/// <reference path="../pb_data/types.d.ts" />

// A bill can now be raised by a guest scanning the QR on their table, before
// any waiter has touched it. Such a bill has no staff member yet — one is
// effectively assigned when the floor picks it up — so `staff` can no longer be
// required.
//
// Everything else about the field is unchanged; existing orders keep theirs.

migrate((app) => {
  const orders = app.findCollectionByNameOrId("orders");
  const staff = orders.fields.getByName("staff");
  if (staff) {
    staff.required = false;
    app.save(orders);
  }
}, (app) => {
  const orders = app.findCollectionByNameOrId("orders");
  const staff = orders.fields.getByName("staff");
  if (staff) {
    staff.required = true;
    app.save(orders);
  }
});
