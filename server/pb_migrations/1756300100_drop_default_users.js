/// <reference path="../pb_data/types.d.ts" />

// PocketBase ships a default `users` auth collection. This system authenticates
// staff against `staff` instead, so `users` is dead weight in the dashboard and
// an easy thing to wire up by mistake.
//
// Its own migration rather than part of the initial schema, so that databases
// created before this change get cleaned up too.

migrate((app) => {
  try {
    const users = app.findCollectionByNameOrId("users");
    // Only remove it if nobody has actually put anything in it.
    if (app.countRecords("users") === 0) {
      app.delete(users);
    }
  } catch (err) {
    // Already gone.
  }
}, (app) => {
  // Deliberately not recreated on rollback: the default collection carries no
  // data we removed, and guessing at its original shape would be worse.
});
