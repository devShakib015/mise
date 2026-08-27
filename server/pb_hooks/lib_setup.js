// Helpers for the first-run endpoints.
//
// These live in a required module rather than at the top of routes.pb.js
// because PocketBase executes each handler in its own pooled JS runtime — a
// function declared beside the handler is simply not defined when it runs.

function staffCount(app) {
  try {
    return app.countRecords("staff");
  } catch (err) {
    return 0;
  }
}

function findRestaurant(app) {
  try {
    return app.findFirstRecordByFilter("restaurant", "id != ''");
  } catch (err) {
    return null;
  }
}

module.exports = { staffCount, findRestaurant };
