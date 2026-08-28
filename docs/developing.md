# Working on Mise

## What you need

- Flutter (stable). Built against 3.47 / Dart 3.13.
- Nothing else. PocketBase is downloaded on demand; there is no database to
  install and no cloud account to create.

## Running it

Two terminals.

```bash
./server/scripts/dev.sh
```

First run fetches the pinned PocketBase into `server/bin/` and applies the
migrations. Its admin UI is at http://127.0.0.1:8090/_/.

```bash
cd app && flutter run -d macos
```

`-d chrome`, `-d windows` and `-d linux` work too. On first launch, point the app
at `127.0.0.1:8090`.

## Tests

Five backend suites. Each spins up a throwaway database on its own port and
tears it down; none touch your data.

```bash
for s in smoke setup kitchen payments staff; do ./server/scripts/${s}_test.sh; done
cd app && flutter test
```

## How it fits together

```
server/pb_migrations/   the schema, in version control
server/pb_hooks/        the rules that cannot live on a client
app/lib/core/           design system, printing, reporting, server hosting
app/lib/data/           models, repositories, live queries
app/lib/features/       setup, auth, pos, kds, manager
```

### Four rules the code leans on

**Money is only ever computed on the server.** The app displays totals; it never
adds them up. A client that PATCHes a forged total has it recomputed and
overwritten, and there is a test for exactly that.

**Menu names and prices are snapshotted onto order lines.** Editing tomorrow's
menu must never rewrite yesterday's bill.

**Takings are counted by when a bill closed**, not when it opened. A table seated
before a shift began and settled during it is that shift's takings.

**Ageing and status use separate colour channels.** On the kitchen display, a
ticket's border and timer say how long; dots and chips say what state. Never
merge them, or a late ticket full of cooking items becomes unreadable.

### Things that will bite you

**PocketBase hooks run in their own runtime.** A function declared at the top of
a `.pb.js` file is not defined inside the handler. Put shared code in a
`lib_*.js` and `require` it *inside* each handler.

**PocketBase zero values are truthy objects.** An empty date is a zero
`DateTime`, so `!record.get("closed_at")` never fires. Use `getString()` and
compare to `""`. A `json` field is a byte array that passes `Array.isArray` —
decode with `.string()` first.

**Filters bind client-side.** `pb.filter("x = {:v}", {...})`, not a `query` map.
The server-side API is the one that binds parameters; the Dart SDK does not.

**The macOS app is not sandboxed, deliberately.** The sandbox quarantines every
file a sandboxed app writes, and a quarantined binary cannot be executed — so
the bundled server would never start. See the comment in
`macos/Runner/Release.entitlements`.

**iOS needs two keys to reach a LAN server** over plain HTTP:
`NSAppTransportSecurity` → `NSAllowsLocalNetworking`, and
`NSLocalNetworkUsageDescription`. Without either, an iPad till silently cannot
connect.

## Building a release

```bash
./installer/macos/build_dmg.sh
```

Stages the server into the app, builds release, and produces
`installer/out/Mise-<version>-macos.dmg`. Set `CODESIGN_IDENTITY` to sign it;
without that it is unsigned and users open it from the right-click menu once.

## Changing the schema

Add a migration to `server/pb_migrations/` — never edit an applied one. Then run
the suites; `smoke` and `payments` cover most of what schema changes break.
