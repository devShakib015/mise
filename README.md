# Restaurant CMS

A free, self-hosted restaurant management system. One installer gives a restaurant
a working POS, kitchen display, menu manager and sales reports on their own
hardware.

**Free forever.** No licence key, no account, no subscription, no telemetry, no
paid tier. The restaurant's data lives on the restaurant's machine.

Because the server runs on-site, **the POS keeps taking orders when the internet
goes down** — which for a restaurant matters more than almost anything else.

> Status: in development. See [PLAN.md](PLAN.md) for the roadmap and the decisions
> behind it. The pre-2023 prototype lives on the `UI_Only` branch and is not
> carried forward.

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

Verify the schema and the server-side money rules:

```bash
./server/scripts/smoke_test.sh
```

That spins up a throwaway database, exercises order numbering, modifier pricing,
tax and service charge, voids, payments and table release, then tears itself down.
It never touches your real data.

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

Menu names and prices are snapshotted onto each order line. Editing tomorrow's menu
must never rewrite yesterday's bill.
