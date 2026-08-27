/// <reference path="../pb_data/types.d.ts" />

// Core schema for the restaurant operations system.
// Everything a fresh install needs: restaurant profile, staff, menu, tables,
// orders, payments, shifts, printers and an audit trail.

migrate((app) => {
  const id = (name) => app.findCollectionByNameOrId(name).id;

  const STAFF = '@request.auth.id != ""';
  const MANAGER = '@request.auth.role = "owner" || @request.auth.role = "manager"';
  const OWNER = '@request.auth.role = "owner"';

  const created = { name: "created", type: "autodate", onCreate: true, onUpdate: false };
  const updated = { name: "updated", type: "autodate", onCreate: true, onUpdate: true };

  // ---------------------------------------------------------------- restaurant
  // Single record. Holds the identity and money rules of the venue.
  app.save(new Collection({
    type: "base",
    name: "restaurant",
    listRule: STAFF,
    viewRule: STAFF,
    createRule: OWNER,
    updateRule: MANAGER,
    deleteRule: null,
    fields: [
      { name: "name", type: "text", required: true, max: 120 },
      { name: "logo", type: "file", maxSelect: 1, maxSize: 2097152,
        mimeTypes: ["image/png", "image/jpeg", "image/webp", "image/svg+xml"] },
      { name: "address", type: "text", max: 300 },
      { name: "phone", type: "text", max: 40 },
      { name: "currency_code", type: "text", required: true, max: 3 },
      { name: "currency_symbol", type: "text", required: true, max: 4 },
      { name: "tax_rate", type: "number", min: 0, max: 100 },
      { name: "tax_inclusive", type: "bool" },
      { name: "service_charge_rate", type: "number", min: 0, max: 100 },
      { name: "receipt_header", type: "text", max: 300 },
      { name: "receipt_footer", type: "text", max: 300 },
      { name: "setup_complete", type: "bool" },
      created, updated,
    ],
  }));

  // --------------------------------------------------------------------- staff
  // Auth collection. The PIN *is* the password, so PocketBase hashes it for us
  // and we never store a credential in plain text.
  app.save(new Collection({
    type: "auth",
    name: "staff",
    listRule: STAFF,
    viewRule: STAFF,
    createRule: MANAGER,
    updateRule: '@request.auth.role = "owner" || @request.auth.role = "manager" || id = @request.auth.id',
    deleteRule: OWNER,
    authRule: "active = true",
    passwordAuth: { enabled: true, identityFields: ["username", "email"] },
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "username", type: "text", required: true, max: 40, pattern: "^[a-z0-9_.-]+$" },
      { name: "role", type: "select", required: true, maxSelect: 1,
        values: ["owner", "manager", "waiter", "cashier", "kitchen"] },
      { name: "active", type: "bool" },
      { name: "avatar", type: "file", maxSelect: 1, maxSize: 2097152,
        mimeTypes: ["image/png", "image/jpeg", "image/webp"] },
      created, updated,
    ],
    indexes: ["CREATE UNIQUE INDEX idx_staff_username ON staff (username)"],
  }));

  // Waiters sign in with a username and a short PIN. Two adjustments to the
  // defaults make that work: allow 4-character passwords, and stop demanding an
  // email address from kitchen staff who will never have one.
  const staff = app.findCollectionByNameOrId("staff");
  staff.passwordAuth.enabled = true;
  const pwField = staff.fields.getByName("password");
  if (pwField) { pwField.min = 4; }
  const emailField = staff.fields.getByName("email");
  if (emailField) { emailField.required = false; }
  app.save(staff);

  // ---------------------------------------------------------------- categories
  app.save(new Collection({
    type: "base",
    name: "categories",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "sort_order", type: "number", onlyInt: true },
      { name: "color", type: "text", max: 9 },
      { name: "image", type: "file", maxSelect: 1, maxSize: 3145728,
        mimeTypes: ["image/png", "image/jpeg", "image/webp"] },
      { name: "active", type: "bool" },
      created, updated,
    ],
    indexes: ["CREATE INDEX idx_categories_sort ON categories (sort_order)"],
  }));

  // ---------------------------------------------------------------- menu_items
  app.save(new Collection({
    type: "base",
    name: "menu_items",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "category", type: "relation", required: true, maxSelect: 1,
        collectionId: id("categories"), cascadeDelete: false },
      { name: "name", type: "text", required: true, max: 120 },
      { name: "description", type: "text", max: 500 },
      { name: "price", type: "number", required: true, min: 0 },
      { name: "image", type: "file", maxSelect: 1, maxSize: 3145728,
        mimeTypes: ["image/png", "image/jpeg", "image/webp"] },
      { name: "prep_minutes", type: "number", onlyInt: true, min: 0 },
      { name: "sku", type: "text", max: 40 },
      { name: "tags", type: "select", maxSelect: 8,
        values: ["vegetarian", "vegan", "spicy", "halal", "gluten_free", "new", "popular", "chef_special"] },
      { name: "sort_order", type: "number", onlyInt: true },
      { name: "active", type: "bool" },
      // Cleared when the kitchen runs out mid-service ("86'd").
      { name: "available", type: "bool" },
      created, updated,
    ],
    indexes: [
      "CREATE INDEX idx_menu_items_category ON menu_items (category)",
      "CREATE INDEX idx_menu_items_sort ON menu_items (sort_order)",
    ],
  }));

  // ----------------------------------------------------------- modifier_groups
  app.save(new Collection({
    type: "base",
    name: "modifier_groups",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "min_select", type: "number", onlyInt: true, min: 0 },
      { name: "max_select", type: "number", onlyInt: true, min: 1 },
      { name: "required", type: "bool" },
      { name: "sort_order", type: "number", onlyInt: true },
      created, updated,
    ],
  }));

  // ------------------------------------------------------------------ modifiers
  app.save(new Collection({
    type: "base",
    name: "modifiers",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "group", type: "relation", required: true, maxSelect: 1,
        collectionId: id("modifier_groups"), cascadeDelete: true },
      { name: "name", type: "text", required: true, max: 80 },
      { name: "price_delta", type: "number" },
      { name: "sort_order", type: "number", onlyInt: true },
      { name: "active", type: "bool" },
      created, updated,
    ],
    indexes: ["CREATE INDEX idx_modifiers_group ON modifiers (`group`)"],
  }));

  // -------------------------------------------------------- menu_item_modifiers
  app.save(new Collection({
    type: "base",
    name: "menu_item_modifiers",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "menu_item", type: "relation", required: true, maxSelect: 1,
        collectionId: id("menu_items"), cascadeDelete: true },
      { name: "modifier_group", type: "relation", required: true, maxSelect: 1,
        collectionId: id("modifier_groups"), cascadeDelete: true },
      { name: "sort_order", type: "number", onlyInt: true },
      created, updated,
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_mim_pair ON menu_item_modifiers (menu_item, modifier_group)",
    ],
  }));

  // --------------------------------------------------------------------- tables
  app.save(new Collection({
    type: "base",
    name: "tables",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: STAFF, deleteRule: MANAGER,
    fields: [
      { name: "label", type: "text", required: true, max: 20 },
      { name: "seats", type: "number", onlyInt: true, min: 1 },
      { name: "zone", type: "text", max: 40 },
      { name: "status", type: "select", required: true, maxSelect: 1,
        values: ["free", "occupied", "reserved", "cleaning"] },
      { name: "pos_x", type: "number" },
      { name: "pos_y", type: "number" },
      { name: "active", type: "bool" },
      created, updated,
    ],
    indexes: ["CREATE UNIQUE INDEX idx_tables_label ON tables (label)"],
  }));

  // --------------------------------------------------------------------- shifts
  app.save(new Collection({
    type: "base",
    name: "shifts",
    listRule: STAFF, viewRule: STAFF,
    createRule: STAFF, updateRule: STAFF, deleteRule: OWNER,
    fields: [
      { name: "staff", type: "relation", required: true, maxSelect: 1,
        collectionId: id("staff"), cascadeDelete: false },
      { name: "opened_at", type: "date" },
      { name: "closed_at", type: "date" },
      { name: "opening_cash", type: "number", min: 0 },
      { name: "closing_cash", type: "number", min: 0 },
      { name: "expected_cash", type: "number" },
      { name: "variance", type: "number" },
      { name: "note", type: "text", max: 500 },
      created, updated,
    ],
    indexes: ["CREATE INDEX idx_shifts_staff ON shifts (staff)"],
  }));

  // --------------------------------------------------------------------- orders
  // Money columns are recomputed server-side by pb_hooks. Never trust a client
  // to tell us what a bill costs.
  app.save(new Collection({
    type: "base",
    name: "orders",
    listRule: STAFF, viewRule: STAFF,
    createRule: STAFF, updateRule: STAFF, deleteRule: MANAGER,
    fields: [
      { name: "number", type: "text", max: 20 },
      { name: "type", type: "select", required: true, maxSelect: 1,
        values: ["dine_in", "takeaway", "delivery"] },
      { name: "table", type: "relation", maxSelect: 1,
        collectionId: id("tables"), cascadeDelete: false },
      { name: "staff", type: "relation", required: true, maxSelect: 1,
        collectionId: id("staff"), cascadeDelete: false },
      { name: "shift", type: "relation", maxSelect: 1,
        collectionId: id("shifts"), cascadeDelete: false },
      { name: "status", type: "select", required: true, maxSelect: 1,
        values: ["open", "sent", "preparing", "ready", "served", "paid", "cancelled"] },
      { name: "guest_count", type: "number", onlyInt: true, min: 0 },
      { name: "subtotal", type: "number" },
      { name: "discount_amount", type: "number" },
      { name: "discount_reason", type: "text", max: 200 },
      { name: "tax_amount", type: "number" },
      { name: "service_amount", type: "number" },
      { name: "total", type: "number" },
      { name: "paid_amount", type: "number" },
      { name: "paid", type: "bool" },
      { name: "customer_name", type: "text", max: 120 },
      { name: "customer_phone", type: "text", max: 40 },
      { name: "note", type: "text", max: 500 },
      { name: "opened_at", type: "date" },
      { name: "closed_at", type: "date" },
      created, updated,
    ],
    indexes: [
      "CREATE INDEX idx_orders_status ON orders (status)",
      "CREATE INDEX idx_orders_table ON orders (`table`)",
      "CREATE INDEX idx_orders_created ON orders (created)",
    ],
  }));

  // ---------------------------------------------------------------- order_items
  // name/price are snapshots. Editing the menu must never rewrite history.
  app.save(new Collection({
    type: "base",
    name: "order_items",
    listRule: STAFF, viewRule: STAFF,
    createRule: STAFF, updateRule: STAFF, deleteRule: STAFF,
    fields: [
      { name: "order", type: "relation", required: true, maxSelect: 1,
        collectionId: id("orders"), cascadeDelete: true },
      { name: "menu_item", type: "relation", maxSelect: 1,
        collectionId: id("menu_items"), cascadeDelete: false },
      { name: "name_snapshot", type: "text", required: true, max: 120 },
      { name: "qty", type: "number", required: true, onlyInt: true, min: 1 },
      { name: "unit_price", type: "number", required: true, min: 0 },
      { name: "modifiers", type: "json", maxSize: 20000 },
      { name: "modifiers_total", type: "number" },
      { name: "line_total", type: "number" },
      { name: "note", type: "text", max: 300 },
      { name: "status", type: "select", required: true, maxSelect: 1,
        values: ["queued", "preparing", "ready", "served", "void"] },
      { name: "void_reason", type: "text", max: 200 },
      { name: "course", type: "number", onlyInt: true, min: 1 },
      { name: "sent_at", type: "date" },
      created, updated,
    ],
    indexes: [
      "CREATE INDEX idx_order_items_order ON order_items (`order`)",
      "CREATE INDEX idx_order_items_status ON order_items (status)",
    ],
  }));

  // ------------------------------------------------------------------- payments
  app.save(new Collection({
    type: "base",
    name: "payments",
    listRule: STAFF, viewRule: STAFF,
    createRule: STAFF, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "order", type: "relation", required: true, maxSelect: 1,
        collectionId: id("orders"), cascadeDelete: true },
      { name: "method", type: "select", required: true, maxSelect: 1,
        values: ["cash", "card", "mobile", "voucher", "other"] },
      { name: "amount", type: "number", required: true },
      { name: "tendered", type: "number" },
      { name: "change_due", type: "number" },
      { name: "reference", type: "text", max: 120 },
      { name: "staff", type: "relation", maxSelect: 1,
        collectionId: id("staff"), cascadeDelete: false },
      created, updated,
    ],
    indexes: ["CREATE INDEX idx_payments_order ON payments (`order`)"],
  }));

  // ------------------------------------------------------------------- printers
  app.save(new Collection({
    type: "base",
    name: "printers",
    listRule: STAFF, viewRule: STAFF,
    createRule: MANAGER, updateRule: MANAGER, deleteRule: MANAGER,
    fields: [
      { name: "name", type: "text", required: true, max: 80 },
      { name: "host", type: "text", required: true, max: 60 },
      { name: "port", type: "number", onlyInt: true, min: 1, max: 65535 },
      { name: "role", type: "select", required: true, maxSelect: 1,
        values: ["receipt", "kitchen", "bar"] },
      { name: "paper_width", type: "select", required: true, maxSelect: 1,
        values: ["58", "80"] },
      { name: "active", type: "bool" },
      created, updated,
    ],
  }));

  // ------------------------------------------------------------------ audit_log
  // Voids and discounts are where money walks out of a restaurant. Log them.
  app.save(new Collection({
    type: "base",
    name: "audit_log",
    listRule: MANAGER, viewRule: MANAGER,
    createRule: STAFF, updateRule: null, deleteRule: null,
    fields: [
      { name: "staff", type: "relation", maxSelect: 1,
        collectionId: id("staff"), cascadeDelete: false },
      { name: "action", type: "text", required: true, max: 60 },
      { name: "entity", type: "text", max: 60 },
      { name: "entity_id", type: "text", max: 40 },
      { name: "detail", type: "json", maxSize: 20000 },
      created,
    ],
    indexes: ["CREATE INDEX idx_audit_created ON audit_log (created)"],
  }));

}, (app) => {
  const names = [
    "audit_log", "printers", "payments", "order_items", "orders", "shifts",
    "tables", "menu_item_modifiers", "modifiers", "modifier_groups",
    "menu_items", "categories", "staff", "restaurant",
  ];
  for (const n of names) {
    try { app.delete(app.findCollectionByNameOrId(n)); } catch (err) { /* already gone */ }
  }
});
