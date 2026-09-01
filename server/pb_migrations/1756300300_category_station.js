/// <reference path="../pb_data/types.d.ts" />

// Which station makes it. Dockets are routed by this, so a bar printer gets
// the drinks and the kitchen printer gets the food instead of both printing
// everything.
//
// On a category rather than an item: a restaurant sorts its menu into sections
// that already map onto stations, and asking someone to set this per dish would
// be busywork they would get wrong.

migrate((app) => {
  const categories = app.findCollectionByNameOrId("categories");
  categories.fields.add(new SelectField({
    name: "station",
    maxSelect: 1,
    values: ["kitchen", "bar"],
  }));
  app.save(categories);

  // Everything existing goes to the kitchen — the safe default, since a docket
  // arriving at the wrong station is better than one arriving nowhere.
  for (const c of app.findRecordsByFilter("categories", "id != ''", "", 0, 0)) {
    if (c.getString("station") === "") {
      c.set("station", "kitchen");
      app.save(c);
    }
  }
}, (app) => {
  const categories = app.findCollectionByNameOrId("categories");
  const field = categories.fields.getByName("station");
  if (field) {
    categories.fields.removeById(field.id);
    app.save(categories);
  }
});
