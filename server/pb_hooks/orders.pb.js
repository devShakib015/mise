/// <reference path="../pb_data/types.d.ts" />

// Order lifecycle: sequential daily numbers, and money columns that the client
// cannot forge.

// ---------------------------------------------------------------- order_items
// Line totals are derived, never accepted from the client.

onRecordCreate((e) => {
  const money = require(`${__hooks}/lib_money.js`);
  money.applyLineTotals(e.record);
  e.next();
}, "order_items");

onRecordUpdate((e) => {
  const money = require(`${__hooks}/lib_money.js`);
  money.applyLineTotals(e.record);
  e.next();
}, "order_items");

// Any change to a line rolls up into the parent order.
const rollUp = (e) => {
  e.next();
  const money = require(`${__hooks}/lib_money.js`);
  money.recomputeOrder(e.app, e.record.getString("order"));
};

onRecordAfterCreateSuccess(rollUp, "order_items");
onRecordAfterUpdateSuccess(rollUp, "order_items");
onRecordAfterDeleteSuccess(rollUp, "order_items");
onRecordAfterCreateSuccess(rollUp, "payments");
onRecordAfterUpdateSuccess(rollUp, "payments");
onRecordAfterDeleteSuccess(rollUp, "payments");

// --------------------------------------------------------------------- orders

onRecordCreate((e) => {
  const money = require(`${__hooks}/lib_money.js`);

  // Sequential per-day number, reset each morning: 001, 002, 003...
  if (!e.record.getString("number")) {
    const now = new Date();
    const dayStart = now.toISOString().slice(0, 10) + " 00:00:00.000Z";

    let seq = 1;
    try {
      const todays = e.app.findRecordsByFilter(
        "orders", "created >= {:from}", "-created", 1, 0, { from: dayStart },
      );
      if (todays.length > 0) {
        const last = parseInt(todays[0].getString("number"), 10);
        if (!isNaN(last)) seq = last + 1;
      }
    } catch (err) { /* first order of the day */ }

    e.record.set("number", String(seq).padStart(3, "0"));
  }

  if (!e.record.get("opened_at")) {
    e.record.set("opened_at", new Date().toISOString());
  }

  money.applyOrderTotals(e.app, e.record);
  e.next();
}, "orders");

// Recompute in place on every save so a discount edit can't desync the total.
// This mutates the record mid-save rather than saving again, so it can't loop.
onRecordUpdate((e) => {
  const money = require(`${__hooks}/lib_money.js`);
  money.applyOrderTotals(e.app, e.record);

  const status = e.record.getString("status");
  if ((status === "paid" || status === "cancelled") && !e.record.get("closed_at")) {
    e.record.set("closed_at", new Date().toISOString());
  }

  e.next();
}, "orders");

// A closed order frees its table.
onRecordAfterUpdateSuccess((e) => {
  e.next();

  const status = e.record.getString("status");
  if (status !== "paid" && status !== "cancelled") return;

  const tableId = e.record.getString("table");
  if (!tableId) return;

  try {
    const open = e.app.findRecordsByFilter(
      "orders",
      "table = {:t} && status != 'paid' && status != 'cancelled'",
      "", 1, 0, { t: tableId },
    );
    if (open.length > 0) return; // another party is still seated there

    const table = e.app.findRecordById("tables", tableId);
    table.set("status", "cleaning");
    e.app.save(table);
  } catch (err) { /* table removed */ }
}, "orders");
