/// <reference path="../pb_data/types.d.ts" />

// Two public endpoints, needed only because of a chicken-and-egg problem:
// the app must know whether a server is configured *before* anyone can sign in,
// and the very first owner has to be created when no owner exists to authorise
// creating them.
//
// Both are deliberately narrow. /status leaks nothing beyond the venue name,
// and /bootstrap refuses outright the moment any staff account exists.

// GET /api/app/status — is there a restaurant here yet?
routerAdd("GET", "/api/app/status", (e) => {
  const setup = require(`${__hooks}/lib_setup.js`);

  const r = setup.findRestaurant(e.app);

  return e.json(200, {
    configured: r ? r.getBool("setup_complete") : false,
    name: r ? r.getString("name") : "",
    has_staff: setup.staffCount(e.app) > 0,
    version: 1,
  });
});

// POST /api/app/bootstrap — create the restaurant and its first owner.
// Only ever works once.
routerAdd("POST", "/api/app/bootstrap", (e) => {
  const setup = require(`${__hooks}/lib_setup.js`);

  if (setup.staffCount(e.app) > 0) {
    return e.json(409, { message: "This server is already set up." });
  }

  const body = e.requestInfo().body || {};

  const required = ["restaurant_name", "owner_name", "owner_username", "owner_pin"];
  for (const key of required) {
    if (!body[key] || String(body[key]).trim() === "") {
      return e.json(400, { message: "Missing required field: " + key });
    }
  }

  const pin = String(body.owner_pin);
  if (pin.length < 4) {
    return e.json(400, { message: "PIN must be at least 4 characters." });
  }

  const username = String(body.owner_username).trim().toLowerCase();
  if (!/^[a-z0-9_.-]+$/.test(username)) {
    return e.json(400, {
      message: "Username may only contain letters, numbers, dot, dash or underscore.",
    });
  }

  // Reuse an existing restaurant row if one was created but never completed.
  let restaurant = setup.findRestaurant(e.app);
  if (!restaurant) {
    restaurant = new Record(e.app.findCollectionByNameOrId("restaurant"));
  }

  restaurant.set("name", String(body.restaurant_name).trim());
  restaurant.set("address", String(body.address || ""));
  restaurant.set("phone", String(body.phone || ""));
  restaurant.set("currency_code", String(body.currency_code || "USD"));
  restaurant.set("currency_symbol", String(body.currency_symbol || "$"));
  restaurant.set("tax_rate", Number(body.tax_rate) || 0);
  restaurant.set("tax_inclusive", body.tax_inclusive === true);
  restaurant.set("service_charge_rate", Number(body.service_charge_rate) || 0);
  restaurant.set("setup_complete", true);
  e.app.save(restaurant);

  const owner = new Record(e.app.findCollectionByNameOrId("staff"));
  owner.set("name", String(body.owner_name).trim());
  owner.set("username", username);
  owner.set("role", "owner");
  owner.set("active", true);
  owner.setPassword(pin);

  try {
    e.app.save(owner);
  } catch (err) {
    // Roll the restaurant back to incomplete so setup can be retried cleanly
    // rather than leaving a configured venue with nobody able to sign in.
    restaurant.set("setup_complete", false);
    try { e.app.save(restaurant); } catch (err2) { /* best effort */ }
    return e.json(400, { message: "Could not create the owner account: " + err });
  }

  return e.json(200, {
    restaurant_id: restaurant.id,
    owner_id: owner.id,
    username: username,
  });
});
