/// <reference path="../pb_data/types.d.ts" />

// Staff administration the collection rules cannot express on their own.
//
// PocketBase requires `oldPassword` to change an auth record's password, which
// is right for self-service and wrong for a restaurant: a waiter forgets their
// PIN mid-service and a manager has to reset it there and then, without anyone
// opening the admin dashboard.

// POST /api/app/staff/reset-pin  { staff_id, pin }
routerAdd("POST", "/api/app/staff/reset-pin", (e) => {
  const lib = require(`${__hooks}/lib_staff.js`);

  const caller = e.auth;
  if (!caller) {
    return e.json(401, { message: "Sign in first." });
  }

  const callerRole = caller.getString("role");
  if (callerRole !== "owner" && callerRole !== "manager") {
    return e.json(403, { message: "Only an owner or manager can reset a PIN." });
  }

  const body = e.requestInfo().body || {};
  const staffId = String(body.staff_id || "");
  const pin = String(body.pin || "");

  if (!staffId) {
    return e.json(400, { message: "Which staff member?" });
  }
  if (pin.length < 4) {
    return e.json(400, { message: "PIN must be at least 4 characters." });
  }

  let target;
  try {
    target = e.app.findRecordById("staff", staffId);
  } catch (err) {
    return e.json(404, { message: "That staff member no longer exists." });
  }

  // A manager must not be able to seize an owner's account by resetting its
  // PIN. Only an owner can reset an owner.
  if (target.getString("role") === "owner" && callerRole !== "owner") {
    return e.json(403, { message: "Only an owner can reset an owner's PIN." });
  }

  target.setPassword(pin);
  e.app.save(target);

  lib.audit(e.app, caller.id, "reset_pin", "staff", target.id, {
    username: target.getString("username"),
  });

  return e.json(200, { ok: true });
});

// Guard the two transitions that would leave the venue with no owner:
// demoting the last one, or switching them off.
onRecordUpdate((e) => {
  const lib = require(`${__hooks}/lib_staff.js`);

  const stillOwner = e.record.getString("role") === "owner";
  const stillActive = e.record.getBool("active");

  if (!stillOwner || !stillActive) {
    let previous = null;
    try {
      previous = e.app.findRecordById("staff", e.record.id);
    } catch (err) {
      previous = null;
    }
    if (previous) {
      lib.assertNotLastOwner(
        e.app,
        previous,
        stillOwner ? "deactivate them" : "change their role",
      );
    }
  }

  e.next();
}, "staff");

onRecordDelete((e) => {
  const lib = require(`${__hooks}/lib_staff.js`);
  lib.assertNotLastOwner(e.app, e.record, "remove this account");
  e.next();
}, "staff");
