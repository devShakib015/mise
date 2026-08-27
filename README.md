# Restaurant CMS

A free, self-hosted restaurant management system. One installer gives a restaurant
a working POS, kitchen display, menu manager and sales reports on their own
hardware.

**Free forever.** No licence key, no account, no subscription, no telemetry, no
paid tier. The restaurant's data lives on the restaurant's machine.

Because the server runs on-site, **the POS keeps taking orders when the internet
goes down** — which for a restaurant matters more than almost anything else.

> Status: in development on the `v2` branch. Phases 0–4 are done — menu, till,
> kitchen display, payments, receipts and shifts. See [PLAN.md](PLAN.md) for the
> roadmap and the decisions behind it. The pre-2023 prototype lives on the
> `UI_Only` branch and is not carried forward.

## Stack

| Layer | Choice |
|---|---|
| Backend | [PocketBase](https://pocketbase.io) — one binary: database, auth, realtime, file storage |
| Apps | Flutter — one binary, three role-based shells (POS / KDS / Manager) |
| Printing | ESC/POS over TCP 9100, with PDF fallback |

## Running it locally

```bash
./server/scripts/dev.sh
```

First run downloads the pinned PocketBase version into `server/bin/` and applies
the schema migrations. The admin UI is then at http://127.0.0.1:8090/_/.

## Tests

Four backend suites, each spinning up a throwaway database on its own port and
tearing it down afterwards. None of them touch your real data.

```bash
for s in smoke setup kitchen payments; do ./server/scripts/${s}_test.sh; done
```

- `smoke` — order numbering, modifier pricing, tax and service charge, voids,
  table release, and that a forged total is overwritten
- `setup` — the first-run endpoints, and that bootstrap can never run twice
- `kitchen` — a bill's status following its lines, and the guards that stop it
  touching bills which are not in service
- `payments` — part payments, settlement, discounts, and refusing money against
  a cancelled bill

Plus the Dart side, including a fake thermal printer on a real socket:

```bash
cd app && flutter test
```

## Running the app

With the server up, in another terminal:

```bash
cd app && flutter run -d macos
```

`-d chrome`, `-d windows` and `-d linux` all work too. On first launch the app
asks for a server address (`127.0.0.1:8090` if it is running on this machine),
then walks through a three-step setup and signs you in.

## How it is put together

`server/pb_migrations/` is the schema, in version control, so a fresh install is
reproducible. `server/pb_hooks/` holds the rules that cannot live on the client:
order numbering and **all money math**. A point-of-sale system must never let a
client tell the server what a bill costs, so every total is recomputed server-side
on write and a forged total is simply overwritten.

Menu names and prices are snapshotted onto each order line. Editing tomorrow's
menu must never rewrite yesterday's bill.

Two rules the whole system leans on. **Money is only ever computed on the
server** — the app displays totals, it never adds them up. And **takings are
counted by when a bill closed**, not when it was opened, so a table seated
before a shift began and settled during it belongs to that shift.

Receipts print over TCP 9100 from the desktop and tablet builds. A browser
cannot open a raw socket, so the web build says so rather than failing quietly.
