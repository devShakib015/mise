// Everything the table-side web page is allowed to see or do.
//
// Deliberately routed rather than done by loosening collection rules. A guest
// is an anonymous stranger on the restaurant's wi-fi; giving them direct read
// or write on any collection would mean auditing every rule against that. These
// routes expose exactly what a menu needs and nothing else — no cost prices, no
// inactive items, no staff, no takings.

/// The menu as a guest sees it: only what is on and in stock.
function publicMenu(app) {
  let venue = null;
  try {
    venue = app.findFirstRecordByFilter("restaurant", "id != ''");
  } catch (err) { /* not set up yet */ }

  if (!venue || !venue.getBool("setup_complete")) return null;

  const categories = app.findRecordsByFilter(
    "categories", "active = true", "sort_order,name", 0, 0,
  );
  const items = app.findRecordsByFilter(
    "menu_items", "active = true", "sort_order,name", 0, 0,
  );
  const links = app.findRecordsByFilter("menu_item_modifiers", "id != ''", "sort_order", 0, 0);
  const groups = app.findRecordsByFilter("modifier_groups", "id != ''", "sort_order,name", 0, 0);
  const modifiers = app.findRecordsByFilter("modifiers", "active = true", "sort_order,name", 0, 0);

  const groupsByItem = {};
  for (const l of links) {
    const item = l.getString("menu_item");
    if (!groupsByItem[item]) groupsByItem[item] = [];
    groupsByItem[item].push(l.getString("modifier_group"));
  }

  return {
    restaurant: {
      name: venue.getString("name"),
      currency_symbol: venue.getString("currency_symbol"),
      currency_code: venue.getString("currency_code"),
    },
    categories: categories.map((c) => ({
      id: c.id,
      name: c.getString("name"),
      color: c.getString("color"),
    })),
    items: items.map((i) => ({
      id: i.id,
      category: i.getString("category"),
      name: i.getString("name"),
      description: i.getString("description"),
      price: i.getFloat("price"),
      image: i.getString("image"),
      tags: i.get("tags"),
      // Sold out is shown, not hidden: a guest looking for it should learn it
      // is off rather than think the restaurant never had it.
      available: i.getBool("available"),
      groups: groupsByItem[i.id] || [],
    })),
    groups: groups.map((g) => ({
      id: g.id,
      name: g.getString("name"),
      required: g.getBool("required"),
      min: g.getInt("min_select"),
      max: g.getInt("max_select"),
      modifiers: modifiers
        .filter((m) => m.getString("group") === g.id)
        .map((m) => ({
          id: m.id,
          name: m.getString("name"),
          price_delta: m.getFloat("price_delta"),
        })),
    })),
  };
}

/// Builds one order line from a guest's request, pricing it from the database.
///
/// Nothing about money comes from the request. A guest sends item ids and
/// quantities; every price is looked up here.
function buildLine(app, request) {
  const itemId = String(request.item_id || "");
  const qty = Math.floor(Number(request.qty) || 0);

  if (qty < 1 || qty > 20) {
    throw new BadRequestError("That is not a sensible quantity.");
  }

  let item;
  try {
    item = app.findRecordById("menu_items", itemId);
  } catch (err) {
    throw new BadRequestError("Something on your order is no longer on the menu.");
  }

  if (!item.getBool("active") || !item.getBool("available")) {
    throw new BadRequestError(
      item.getString("name") + " has just gone off the menu. Please remove it.",
    );
  }

  // A modifier only counts if it belongs to a group actually attached to this
  // item — otherwise a guest could price a steak with a coffee's discount.
  const allowedGroups = app
    .findRecordsByFilter("menu_item_modifiers", "menu_item = {:id}", "", 0, 0, { id: item.id })
    .map((l) => l.getString("modifier_group"));

  const chosen = Array.isArray(request.modifiers) ? request.modifiers : [];
  const snapshot = [];

  for (const modifierId of chosen) {
    let modifier;
    try {
      modifier = app.findRecordById("modifiers", String(modifierId));
    } catch (err) {
      throw new BadRequestError("One of the options is no longer offered.");
    }
    if (!modifier.getBool("active")) {
      throw new BadRequestError("One of the options is no longer offered.");
    }
    if (allowedGroups.indexOf(modifier.getString("group")) === -1) {
      throw new BadRequestError("That option does not belong to that item.");
    }
    snapshot.push({
      name: modifier.getString("name"),
      price_delta: modifier.getFloat("price_delta"),
    });
  }

  // Every required question must have been answered.
  for (const groupId of allowedGroups) {
    let group;
    try {
      group = app.findRecordById("modifier_groups", groupId);
    } catch (err) { continue; }
    if (!group.getBool("required")) continue;

    const answered = snapshot.length > 0 && chosen.some((id) => {
      try {
        return app.findRecordById("modifiers", String(id)).getString("group") === groupId;
      } catch (err) { return false; }
    });
    if (!answered) {
      throw new BadRequestError("Please choose " + group.getString("name").toLowerCase() + ".");
    }
  }

  return {
    menu_item: item.id,
    name_snapshot: item.getString("name"),
    qty: qty,
    unit_price: item.getFloat("price"),
    modifiers: snapshot,
    note: String(request.note || "").slice(0, 200),
    status: "queued",
  };
}

module.exports = { publicMenu, buildLine };
