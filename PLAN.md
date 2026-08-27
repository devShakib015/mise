# Restaurant CMS — Build Plan

> This document is the contract. If the code and this file disagree, this file wins
> until it is deliberately updated.

## 1. What this is

A **free, self-hosted restaurant management system**. A restaurant downloads one
installer, runs a setup wizard, and has a working POS, kitchen display, menu manager
and sales reports on their own hardware.

**Free forever means free forever.** No licence key, no account, no subscription,
no telemetry, no paid tier, no "pro" upsell. The restaurant's data lives on the
restaurant's machine.

### The promise, and its one honest limit

Free for the restaurant: yes, permanently. There is nothing they can be billed for.

What costs *us* money, and never them:
- Apple Developer Program, $99/yr — required to notarise macOS builds. Without it
  macOS shows a Gatekeeper warning that users must right-click → Open past.
- Windows code-signing certificate, ~$200-400/yr — without it SmartScreen warns
  on first run.
- Both are cosmetic-trust problems, not functional ones. We ship unsigned and
  document the workaround until signing is worth paying for.

## 2. Decisions already made

| Question | Decision |
|---|---|
| Backend | **PocketBase** — single binary, no cloud account, no credit card |
| Who installs it | **Both** — one-click installer for owners, docs + config for developers |
| v1 product core | **Restaurant operations** — POS, KDS, menu, tables, staff, reports |
| Old 2022 code | **Full restart** — new code and new design |

The 2022 code (`customer_app`, `admin_panel`, `delivery_app`) is preserved on the
`UI_Only` branch and pushed to origin. Recover any of it with
`git checkout UI_Only -- <path>`. It is not carried forward.

### Why PocketBase and not Firebase

Firebase cannot deliver "free forever, they set it up themselves". Every restaurant
would need their own Firebase project or we pay their bill; Cloud Functions require
the Blaze plan with a card on file; `flutterfire configure` is a developer task.

PocketBase is one binary containing auth, a database, realtime subscriptions, file
storage and an admin UI. Download, run, done. And because it runs on a machine in
the restaurant, **the POS keeps taking orders when their internet goes down** —
which for a restaurant matters more than almost anything else.

Pinned to a specific PocketBase version. It is still pre-1.0 (currently v0.40.x)
and ships breaking changes between minor releases, so the version is locked in
`server/VERSION` and only moved deliberately.

## 3. Architecture

### One app, three shells

Not three separate downloads. **One Flutter binary**; the logged-in staff member's
role decides which shell they get.

- Waiter or cashier signs in → **POS**
- Kitchen screen signs in → **KDS**
- Owner or manager signs in → **Manager**

One codebase, one installer, one thing to explain to a restaurant.

### Repository layout

```
restaurant_cms/
├── PLAN.md                  ← this file
├── README.md
├── server/
│   ├── VERSION              ← pinned PocketBase version
│   ├── pb_migrations/       ← JS migrations: the schema, version controlled
│   ├── pb_hooks/            ← JS hooks: order numbers, totals, guards, audit
│   └── fetch_pocketbase.sh  ← downloads the right binary per OS/arch
├── app/
│   └── lib/
│       ├── core/            ← design system, router, DI, result types
│       ├── data/            ← PocketBase client, models, repositories
│       ├── features/
│       │   ├── setup/       ← first-run wizard
│       │   ├── auth/        ← staff sign-in, PIN lock
│       │   ├── pos/         ← tables, order taking, payment
│       │   ├── kds/         ← kitchen display
│       │   ├── menu/        ← menu management
│       │   ├── staff/       ← staff and roles
│       │   ├── reports/     ← sales reporting
│       │   └── settings/    ← restaurant, tax, printers
│       └── main.dart
├── installer/               ← macOS DMG, Windows NSIS, Linux AppImage
└── docs/                    ← owner guide + developer guide
```

### How devices find the server

The server runs on one machine on the restaurant's LAN. Tablets and the kitchen
screen join over that LAN. Discovery, in order of preference:

1. mDNS/Bonjour auto-discovery
2. QR code shown by the server machine
3. Typing the IP address by hand

### Design system

Warm neutrals rather than cool greys — a screen that sits in a dining room all
evening should not read clinical. **Ember** is the brand colour and is reserved
for identity and primary actions.

Status colours deliberately avoid orange so an order's state can never be
mistaken for a button: queued is neutral, preparing is **blue**, ready is
**green**, and red is kept for trouble. Ticket ageing runs on a separate visual
channel — it tints borders and timers, never status chips.

Inter is bundled, not fetched, because nothing may load at runtime. Money always
uses tabular figures so digits stop shifting as totals change.

### Non-negotiables

- **Totals are computed server-side.** A POS must never let a tampered client
  decide what a bill costs. Hooks recompute every total on write.
- **Offline-tolerant.** Losing the network mid-service must not lose an order.
- **Realtime.** An order sent from the POS appears on the kitchen screen with no
  refresh, no polling.
- **Premium UI.** This is the thing a restaurant stares at for twelve hours a day.

## 4. Data model

PocketBase collections, defined as JS migrations so the schema is version-controlled
and reproducible on a fresh install.

| Collection | Holds |
|---|---|
| `restaurant` | Name, logo, address, phone, currency, tax rate, service charge |
| `staff` | Auth collection — name, PIN, role, active |
| `categories` | Name, sort order, image, active |
| `menu_items` | Category, name, description, price, image, prep time, active |
| `modifier_groups` | Name, min/max selectable, required |
| `modifiers` | Group, name, price delta |
| `tables` | Number, seats, zone, current status |
| `orders` | Number, type, table, staff, status, money columns, timestamps |
| `order_items` | Order, item, qty, unit price, modifiers, notes, item status |
| `payments` | Order, method, amount, reference, staff |
| `shifts` | Staff, open/close times, opening and closing cash, variance |
| `printers` | Name, IP, port, role (receipt / kitchen), paper width |
| `audit_log` | Who changed what, when — voids and discounts especially |

## 5. Receipt printing

Network thermal printers over **TCP port 9100** (ESC/POS), which is what virtually
every restaurant printer already speaks and what works identically on desktop,
tablet and web. PDF export as the fallback for anyone without a thermal printer.

## 6. Phases

Each phase ends with something you can actually run and test.

**Phase 0 — Foundation** ✅ *done*
Repo restart, PocketBase bundle and fetch script, schema migrations, server-side
money hooks, Flutter app skeleton, design system, staff auth, first-run setup
wizard. Verified end to end: connect → set up → sign in → role shell, with the
session surviving a restart. 27 automated checks passing across two suites.

**Phase 1 — Menu and settings** ✅ *done*
Manager shell with grouped navigation. Categories with drag-reordering and till
colours; items with photos, tags, prep times and a sold-out ("86") toggle;
modifier groups and their options; venue settings for name, currency, tax,
service charge and receipt lines. All lists are realtime — a change on one
device lands on the others without a refresh.
*Test: build your real menu from scratch.*

**Phase 2 — POS core** ✅ *done*
Tables management, floor view with live bill totals per table, order taking with
a modifier sheet, kitchen notes, quantities, send-to-kitchen, and voids that are
recorded rather than silently deleted. Owners and managers get a shell switcher,
because in a small restaurant the owner is also the waiter.
*Test: take an order end to end.*

Still to come here: split and merge tables, and moving a bill between tables
(the repository supports the move; there is no UI for it yet).

**Phase 3 — Kitchen display**
Realtime tickets, per-item status, bump to ready, prep timers, ticket ageing colours.
*Test: send an order from POS, watch it land in the kitchen instantly.*

**Phase 4 — Payments, receipts, shifts**
Split bills, cash and card and mobile, discounts and voids with audit trail, ESC/POS
receipt printing, shift open/close, end-of-day Z-report.
*Test: close a bill and print a receipt.*

**Phase 5 — Staff and reports**
Roles and permissions, sales by day/item/staff/hour, CSV export.
*Test: see yesterday's numbers.*

**Phase 6 — Packaging and distribution**
macOS DMG, Windows installer, Linux AppImage, one-click setup, owner and developer
docs, GitHub Releases, landing page on the portfolio.
*Test: install it on a clean machine like a stranger would.*

### Later, deliberately not in v1
Customer ordering app, QR-code table menu, delivery app and driver tracking,
multi-branch, inventory and stock control, reservations.

The 2022 customer app was built first and had nothing to send orders to. Ops first
this time; the customer app plugs into a system that already works.

## 7. The name

The product is **Mise**, from *mise en place* — everything in its place before
service. It is the one French term every professional kitchen actually uses, so
it reads as built by someone who knows restaurants, and it is distinctive enough
to find in a search.

`restaurant_cms` remains the repository name. The two do not need to match.

Rejected, and why, so this is not relitigated: **Counter** and **Pass** are common
English words — unsearchable, and already taken by other products. **Ember** and
**Expo** collide with well-known developer tools, which matters when developers
are half the audience. **Servewell** was fine but reads like legacy hospitality
software.
