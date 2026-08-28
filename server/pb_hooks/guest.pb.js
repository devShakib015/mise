/// <reference path="../pb_data/types.d.ts" />

// The table-side ordering routes.
//
// A guest scans the QR on their table, gets a web page, and sends an order.
// They are anonymous and on the restaurant's wi-fi, so these three routes are
// the entire surface they can reach — every collection stays staff-only.

// GET /api/app/menu — what is on today.
routerAdd("GET", "/api/app/menu", (e) => {
  const guest = require(`${__hooks}/lib_guest.js`);

  const menu = guest.publicMenu(e.app);
  if (!menu) {
    return e.json(404, { message: "This restaurant is not open for ordering yet." });
  }
  return e.json(200, menu);
});

// GET /api/app/table/{id} — confirms a scanned code points at a real table.
routerAdd("GET", "/api/app/table/{id}", (e) => {
  const id = e.request.pathValue("id");

  let table;
  try {
    table = e.app.findRecordById("tables", id);
  } catch (err) {
    return e.json(404, { message: "That code does not match a table here." });
  }

  if (!table.getBool("active")) {
    return e.json(404, { message: "That table is not in use." });
  }

  return e.json(200, {
    id: table.id,
    label: table.getString("label"),
    zone: table.getString("zone"),
  });
});

// POST /api/app/guest-order — puts a guest's choices onto the table's bill.
//
// Deliberately does NOT send anything to the kitchen. The items land on the
// bill unsent, and a waiter fires them. That keeps a stranger on the wi-fi from
// putting food on the pass, and it is how a waiter would want it anyway — they
// are the ones who know the table is real.
routerAdd("POST", "/api/app/guest-order", (e) => {
  const guest = require(`${__hooks}/lib_guest.js`);

  const body = e.requestInfo().body || {};
  const tableId = String(body.table || "");
  const requested = Array.isArray(body.items) ? body.items : [];

  if (requested.length === 0) {
    return e.json(400, { message: "Your order is empty." });
  }
  if (requested.length > 40) {
    return e.json(400, { message: "That is too many items for one order." });
  }

  let table;
  try {
    table = e.app.findRecordById("tables", tableId);
  } catch (err) {
    return e.json(404, { message: "That code does not match a table here." });
  }
  if (!table.getBool("active")) {
    return e.json(404, { message: "That table is not in use." });
  }

  // Price and validate everything before touching the bill, so a bad line
  // cannot leave half an order behind.
  const lines = [];
  for (const item of requested) {
    lines.push(guest.buildLine(e.app, item));
  }

  // Join the bill already open on the table, or start one. A guest ordering a
  // second round should land on the same bill as their first.
  let order = null;
  try {
    order = e.app.findFirstRecordByFilter(
      "orders",
      "table = {:t} && status != 'paid' && status != 'cancelled'",
      { t: table.id },
    );
  } catch (err) { /* nothing open */ }

  if (!order) {
    // No staff member has opened this table, so the bill is raised without one.
    // The floor sees it appear and picks it up.
    order = new Record(e.app.findCollectionByNameOrId("orders"));
    order.set("type", "dine_in");
    order.set("status", "open");
    order.set("table", table.id);
    order.set("guest_count", 0);
    e.app.save(order);

    table.set("status", "occupied");
    e.app.save(table);
  }

  const collection = e.app.findCollectionByNameOrId("order_items");
  for (const line of lines) {
    const record = new Record(collection);
    record.set("order", order.id);
    for (const key of Object.keys(line)) {
      record.set(key, line[key]);
    }
    e.app.save(record);
  }

  // Re-read: the money hooks recomputed the total as each line was saved.
  const fresh = e.app.findRecordById("orders", order.id);

  return e.json(200, {
    order_number: fresh.getString("number"),
    total: fresh.getFloat("total"),
    added: lines.length,
    table: table.getString("label"),
  });
});
