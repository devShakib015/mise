// Staff guards.
//
// In a required module, not beside the handlers: PocketBase runs each handler
// in its own pooled runtime, where a function declared at file scope is simply
// not defined.

/// Refuses to leave the restaurant without an owner. There is no way back from
/// that short of the admin dashboard, which is exactly what this system exists
/// to avoid needing.
function assertNotLastOwner(app, record, action) {
  if (record.getString("role") !== "owner") return;
  if (!record.getBool("active")) return;

  let others = [];
  try {
    others = app.findRecordsByFilter(
      "staff",
      "role = 'owner' && active = true && id != {:id}",
      "", 1, 0,
      { id: record.id },
    );
  } catch (err) {
    others = [];
  }

  if (others.length === 0) {
    throw new BadRequestError(
      "This is the only owner. Make someone else an owner before you " + action + ".",
    );
  }
}

function audit(app, staffId, action, entity, entityId, detail) {
  try {
    const log = new Record(app.findCollectionByNameOrId("audit_log"));
    log.set("staff", staffId);
    log.set("action", action);
    log.set("entity", entity);
    log.set("entity_id", entityId);
    log.set("detail", detail || {});
    app.save(log);
  } catch (err) {
    // Best effort; an audit failure must never block staff administration.
  }
}

module.exports = { assertNotLastOwner, audit };
