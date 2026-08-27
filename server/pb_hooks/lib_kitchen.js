// Derives an order's status from the state of its lines.
//
// Lives on the server so every terminal agrees: a chef bumping the last item
// on the kitchen screen and a waiter looking at the floor must see the same
// thing without either of them computing it.

const SERVICE_STATES = ["sent", "preparing", "ready", "served"];

function deriveOrderStatus(app, orderId) {
  if (!orderId) return;

  let order;
  try {
    order = app.findRecordById("orders", orderId);
  } catch (err) {
    return; // order deleted; its lines cascade away with it
  }

  const current = order.getString("status");

  // Never override a bill that is not in service. An open bill has not been
  // sent yet, and paid or cancelled ones are finished.
  if (SERVICE_STATES.indexOf(current) === -1) return;

  const lines = app.findRecordsByFilter(
    "order_items",
    "order = {:oid} && status != 'void'",
    "", 0, 0,
    { oid: orderId },
  );

  const sent = lines.filter((l) => (l.getString("sent_at") || "") !== "");
  if (sent.length === 0) return;

  const states = sent.map((l) => l.getString("status"));
  const every = (s) => states.every((x) => x === s);
  const some = (s) => states.some((x) => x === s);

  let next;
  if (every("served")) {
    next = "served";
  } else if (states.every((x) => x === "ready" || x === "served")) {
    next = "ready";
  } else if (some("preparing")) {
    next = "preparing";
  } else {
    next = "sent";
  }

  if (next !== current) {
    order.set("status", next);
    app.save(order);
  }
}

module.exports = { deriveOrderStatus };
