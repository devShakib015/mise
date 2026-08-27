// Money math for orders. Everything here runs server-side on purpose: a POS must
// never let a client tell the server what a bill costs.

const round2 = (n) => Math.round((Number(n) || 0) * 100) / 100;

// Sum the price deltas of an order item's selected modifiers.
// Stored as a JSON snapshot so later menu edits can't rewrite an old bill.
function modifiersTotal(record) {
  let list = record.get("modifiers");
  if (!list) return 0;

  // A json field arrives as types.JSONRaw, which is a *byte* array. It passes
  // Array.isArray, so it has to be decoded via .string() before anything else
  // or you end up quietly summing raw bytes and getting zero.
  if (typeof list.string === "function") {
    list = list.string();
  }
  if (typeof list === "string") {
    try { list = JSON.parse(list); } catch (err) { return 0; }
  }
  if (!Array.isArray(list)) return 0;

  let sum = 0;
  for (const m of list) {
    sum += Number((m && m.price_delta) || 0);
  }
  return round2(sum);
}

// (unit price + modifiers) x quantity. Voided lines are worth nothing.
function applyLineTotals(record) {
  const mods = modifiersTotal(record);
  const qty = Number(record.getInt("qty")) || 0;
  const unit = Number(record.getFloat("unit_price")) || 0;
  const voided = record.getString("status") === "void";

  record.set("modifiers_total", mods);
  record.set("line_total", voided ? 0 : round2((unit + mods) * qty));
}

function restaurantSettings(app) {
  try {
    const r = app.findFirstRecordByFilter("restaurant", "id != ''");
    return {
      taxRate: Number(r.getFloat("tax_rate")) || 0,
      taxInclusive: r.getBool("tax_inclusive"),
      serviceRate: Number(r.getFloat("service_charge_rate")) || 0,
    };
  } catch (err) {
    return { taxRate: 0, taxInclusive: false, serviceRate: 0 };
  }
}

// Recomputes an order's money columns onto the record, WITHOUT saving it.
// Callers decide whether they're mutating a record mid-save or persisting after.
function applyOrderTotals(app, order) {
  const s = restaurantSettings(app);

  const items = app.findRecordsByFilter(
    "order_items",
    "order = {:oid} && status != 'void'",
    "", 0, 0,
    { oid: order.id },
  );

  let subtotal = 0;
  for (const it of items) {
    subtotal += Number(it.getFloat("line_total")) || 0;
  }
  subtotal = round2(subtotal);

  const discount = Math.min(round2(order.getFloat("discount_amount")), subtotal);
  const base = round2(subtotal - discount);
  const service = round2(base * s.serviceRate / 100);
  const preTax = round2(base + service);

  // Tax-inclusive menus already have the tax baked into the listed price, so we
  // extract it rather than adding it on top.
  const tax = s.taxInclusive
    ? round2(preTax * s.taxRate / (100 + s.taxRate))
    : round2(preTax * s.taxRate / 100);

  const total = s.taxInclusive ? preTax : round2(preTax + tax);

  let paidAmount = 0;
  try {
    const payments = app.findRecordsByFilter(
      "payments", "order = {:oid}", "", 0, 0, { oid: order.id },
    );
    for (const p of payments) {
      paidAmount += Number(p.getFloat("amount")) || 0;
    }
  } catch (err) { /* no payments yet */ }
  paidAmount = round2(paidAmount);

  order.set("subtotal", subtotal);
  order.set("discount_amount", discount);
  order.set("service_amount", service);
  order.set("tax_amount", tax);
  order.set("total", total);
  order.set("paid_amount", paidAmount);
  order.set("paid", paidAmount >= total && total > 0);
}

// Recomputes and persists. Used from after-success hooks on child records.
function recomputeOrder(app, orderId) {
  if (!orderId) return;
  let order;
  try {
    order = app.findRecordById("orders", orderId);
  } catch (err) {
    return; // order was deleted; its items cascade away with it
  }
  applyOrderTotals(app, order);
  app.save(order);
}

module.exports = { round2, applyLineTotals, applyOrderTotals, recomputeOrder };
