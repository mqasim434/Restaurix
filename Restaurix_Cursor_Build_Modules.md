# Restaurix — Module-by-Module Cursor Build Document

This document breaks the entire restaurant management system into **35 independent, testable modules**. Copy each module's Cursor Prompt into Cursor, build it, test it against its checklist, confirm Definition of Done, then move to the next module in order. Don't skip ahead — later modules assume earlier ones exist exactly as scoped.

**Auth is deliberately last (Module 33).** Until then, every screen is built and tested behind a hardcoded mock session that reports the current user as an Admin. This lets you build and test the entire app without fighting login screens, and the real auth module just swaps the mock provider for a real one — nothing else changes.

---

## 0. Global Conventions (read once, applies to every module)

**Stack**
- Flutter Desktop (Windows target), Material 3, responsive desktop layout (not mobile-first)
- State management: **Riverpod** — `Notifier`/`AsyncNotifier` for all mutable state, `Provider`/`FutureProvider` for derived/read-only state. No `StatefulWidget` business logic — UI state only (e.g. hover, expanded/collapsed).
- Local DB: **Isar** (offline-first source of truth for the UI)
- Backend: **Supabase** (Postgres, Auth, Storage, Realtime)
- Architecture: `UI → Riverpod → Repository → Isar (read/write) → Sync Queue → Supabase`

**Folder structure** (every module's prompt assumes this exists from Module 0):
```
lib/
  core/            # theme, constants, utils, sync engine, base classes
  data/
    local/         # isar collections + isar service
    remote/        # supabase table services
    repositories/  # one repository per domain entity, hides isar vs supabase
  domain/
    models/        # plain dart models (not isar/supabase specific)
  features/
    <feature_name>/
      presentation/  # screens, widgets
      providers/     # riverpod providers/notifiers for this feature
  app/             # router, app shell, role-based navigation
```

**Standard sync fields** — every Isar collection and every Supabase table gets these fields unless explicitly noted otherwise. Module write-ups below say "+ standard sync fields" instead of repeating the list:
- `id` (UUID, string, primary key — generated client-side so offline creation works)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)
- `isSynced` (bool, default false)
- `deletedAt` (DateTime?, null = not deleted — **soft delete only, never hard delete**)
- `syncAction` (enum: create / update / delete)
- `deviceId` (string)
- `version` (int, incremented on every local write, used for conflict resolution)

**Mock auth context (until Module 33)**: a single `currentUserProvider` returning a hardcoded `AppUser(id: 'mock-admin', name: 'Admin', role: UserRole.admin)`. Every module that needs "current user" reads from this provider. When real auth lands, only this provider's implementation changes.

**Definition of Done applies to every module**: code compiles, no analyzer warnings, feature works fully offline (no Supabase call required to use it), data persists across app restart, and the module's testing checklist passes manually.

---

## Table of Contents

| # | Module |
|---|--------|
| 0 | Project Foundation & Architecture Setup |
| 1 | Design System / Theme |
| 2 | Local Database Foundation (Isar) |
| 3 | Supabase Backend Foundation |
| 4 | App Shell & Role-Based Navigation |
| 5 | Categories Module |
| 6 | Products Module |
| 7 | Variants Module |
| 8 | Modifier Groups & Modifiers Module |
| 9 | Deals Module |
| 10 | Tables & Hall Management Module |
| 11 | POS — Cart, Product & Deal Selection |
| 12 | POS — Order Type & Delivery |
| 13 | Pickup Companies & Riders Configuration |
| 14 | POS — Discounts |
| 15 | POS — Payment & Order Placement |
| 16 | Order Lifecycle & Status Management |
| 17 | Draft Orders |
| 18 | Hold Orders |
| 19 | Kitchen Display System (KDS) |
| 20 | Printing — Kitchen Ticket |
| 21 | Printing — Customer Receipt |
| 22 | Sales Module/Tab |
| 23 | Reports Module |
| 24 | Employees Management |
| 25 | Biometric Attendance |
| 26 | Salary Calculation |
| 27 | Salary Slip Generation |
| 28 | Analytics Dashboard |
| 29 | Settings Module |
| 30 | Offline Sync Queue Infrastructure |
| 31 | Sync Engine — Upload / Download / Conflict Resolution |
| 32 | Salesman Restricted Role View |
| 33 | Authentication (Supabase Auth) |
| 34 | Final Polish, Edge Case Pass & Full Regression Test |

---

## Module 0 — Project Foundation & Architecture Setup

**Goal:** Scaffold the Flutter desktop project with the full folder structure, dependencies, and base classes — no features yet.

**Cursor Prompt:**
> Create a new Flutter project configured for Windows desktop. Set up this exact folder structure under `lib/`: `core/`, `data/local/`, `data/remote/`, `data/repositories/`, `domain/models/`, `features/`, `app/`. Add these dependencies: `flutter_riverpod`, `isar`, `isar_flutter_libs`, `path_provider`, `supabase_flutter`, `uuid`, `intl`, `go_router`, `freezed` + `freezed_annotation` + `build_runner` (for immutable models). Create a base `SyncableEntity` mixin/interface in `core/` representing the standard sync fields (id, createdAt, updatedAt, isSynced, deletedAt, syncAction, deviceId, version) that every future Isar collection and domain model will implement. Set up `main.dart` to initialize Isar and a placeholder Supabase client (use dummy URL/anon key as constants in `core/constants.dart` for now — real keys come in Module 3). Do not build any UI yet beyond a blank `MaterialApp` with a placeholder home screen that just says "Restaurix". Confirm the app builds and runs on Windows.

**Edge Cases:** none yet — this is scaffolding only.

**Testing Checklist:**
- App builds and launches on Windows desktop
- Folder structure matches spec exactly
- `flutter analyze` shows zero issues

**Definition of Done:** project runs, structure is in place, dependencies resolve cleanly.

---

## Module 1 — Design System / Theme

**Goal:** A single source of truth for every visual property in the app, so changing one value updates the whole UI.

**Cursor Prompt:**
> In `core/theme/`, build a centralized design system with separate files: `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_icons.dart`, and `app_theme.dart` that assembles them into a Flutter `ThemeData` (Material 3). Define a full color palette (primary, secondary, surface, background, error, success, warning, on-* variants, border, divider) as named constants — not raw hex scattered around the app. Define a type scale (display/headline/title/body/label, each in large/medium/small) using `TextStyle`. Define spacing as a scale (xs, sm, md, lg, xl, xxl) and radius the same way (none, sm, md, lg, full). Then build reusable themed widgets in `core/widgets/`: `AppButton` (primary/secondary/danger/ghost variants), `AppCard`, `AppDialog`, `AppDataTable`, `AppTextField`, `AppDropdown`, `AppSnackbar` (success/error/info), `AppLoadingIndicator`, and `AppEmptyState`. Every widget must pull all colors, spacing, radius, and typography from the theme files — zero hardcoded values inside widget files. Build a `/theme-preview` debug route that renders every component and every color swatch on one screen so changes are visually verifiable instantly.

**Edge Cases:**
- Dark mode is out of scope for v1, but structure colors so a dark variant could be added later without touching widget code
- Long text in buttons/cards must not overflow — verify truncation/wrapping behavior

**Testing Checklist:**
- Change one color constant → confirm it propagates everywhere it's used on the preview screen
- All themed widgets render correctly at different desktop window sizes
- No widget in `core/widgets/` references a raw color or pixel value

**Definition of Done:** `/theme-preview` shows a complete, consistent component library; changing a single theme constant cascades app-wide.

---

## Module 2 — Local Database Foundation (Isar)

**Goal:** Isar initialized, base collection pattern established, no business entities yet.

**Cursor Prompt:**
> Set up Isar in `data/local/`. Create `isar_service.dart` that opens the Isar instance at app startup (using `path_provider` for the storage directory) and exposes it via a Riverpod provider (`isarProvider`). Create a base abstract pattern/example showing how every future collection will declare the standard sync fields (id as Isar `Id` plus a separate `uuid` string field for the universal identifier, createdAt, updatedAt, isSynced, deletedAt, syncAction stored as an enum, deviceId, version). Generate a `deviceId` once per install (UUID, persisted via `path_provider` + a small local file or shared_preferences) and expose it via a `deviceIdProvider`. Write one throwaway demo collection (`DebugPingIsar`) purely to prove writes/reads/queries work, with a temporary debug screen showing CRUD against it. This demo collection and screen will be deleted in Module 5 once a real collection exists.

**Edge Cases:**
- Isar schema must support hot-reload during development without crashing
- Confirm app data directory is correctly scoped per-Windows-user

**Testing Checklist:**
- Write, read, update, soft-delete a `DebugPingIsar` record, restart the app, confirm data persisted
- `deviceId` is stable across restarts

**Definition of Done:** Isar opens reliably at startup, base sync-field pattern is documented/proven, deviceId is stable and accessible app-wide.

---

## Module 3 — Supabase Backend Foundation

**Goal:** Real Supabase project wired up with mirrored table schemas for every entity that will exist, plus RLS stubbed permissively for development.

**Cursor Prompt:**
> Replace the dummy Supabase constants from Module 0 with real project URL/anon key (I will provide these). Write SQL migration files (store them in a `supabase/migrations/` folder in the repo, don't apply via UI manually) creating tables for: categories, products, product_variants, modifier_groups, modifiers, deals, tables (hall/table entities), orders, order_items, order_item_modifiers, discounts, employees, attendance_records, salary_slips, pickup_companies, riders, app_users. Every table gets the standard sync columns (id uuid primary key, created_at, updated_at, is_synced boolean default true [server is always "synced" with itself], deleted_at, sync_action, device_id, version int). For now, set RLS policies to allow full read/write for any authenticated request AND for the anon key (temporary — will be tightened in Module 33 once real auth and roles exist). Add a `core/remote/supabase_table_names.dart` constants file so table names are never hardcoded as raw strings elsewhere. Confirm connectivity with a simple ping query at app startup (log success/failure, don't block UI).

**Edge Cases:**
- App must still launch and function fully offline if Supabase is unreachable at startup — this is a non-blocking ping, not a requirement
- Schema field types must match what Isar will store (no silent type mismatches, e.g. enums stored as text on both sides)

**Testing Checklist:**
- All tables created successfully in Supabase, visible in dashboard
- App launches normally with Wi-Fi off (no crash, no blocking spinner)
- Ping query succeeds when online

**Definition of Done:** full schema exists in Supabase mirroring the planned local entities; app works identically online or offline at this stage (since nothing reads/writes real data yet).

---

## Module 4 — App Shell & Role-Based Navigation

**Goal:** The desktop chrome — sidebar, top bar, routing — driven by role, using the mock-admin provider.

**Cursor Prompt:**
> Build the main app shell in `app/`: a persistent left sidebar navigation and top bar, using `go_router` for routing, styled entirely from the Module 1 theme. Define a `UserRole` enum (`admin`, `salesman`) and the temporary `currentUserProvider` from the Global Conventions section returning a mock admin user. Build a `navigationItemsProvider` that returns the full admin menu when role is admin: Dashboard, Sales (POS), Orders, Products, Categories, Deals, Tables, Employees, Attendance, Reports, Analytics, Settings, Users. (Salesman's restricted menu comes in Module 32 — for now just stub the enum case returning an empty list, unreachable since mock user is always admin.) Each nav item routes to a placeholder screen with just the screen's title for now — real screens replace these placeholders module by module. Add a logged-in-as indicator in the top bar showing the mock user's name and role (this will later be replaced by the real session in Module 33). Sidebar should support collapsed/expanded state (persisted via a simple Riverpod `StateProvider`, not Isar — this is pure UI preference).

**Edge Cases:**
- Window resize must not break the sidebar/content layout
- Navigating to a route that doesn't exist yet should show a clean "coming soon" placeholder, not a crash

**Testing Checklist:**
- All admin nav items are visible and clickable, each shows its placeholder screen
- Sidebar collapse/expand works and persists during the session
- Resizing the window doesn't break layout

**Definition of Done:** full desktop shell navigable end to end with placeholders, ready for each feature module to fill in its screen.

---

## Module 5 — Categories Module

**Goal:** Full CRUD for product categories, offline-first, syncable.

**Cursor Prompt:**
> Build the Categories feature in `features/categories/`. Create the `Category` domain model and matching Isar collection (fields: `name`, `imageUrl` nullable, `sortOrder` int, `isActive` bool, + standard sync fields) and matching Supabase table usage via `categories` table from Module 3. Build `CategoryRepository` in `data/repositories/` with methods: `watchAll()` (Isar stream, excludes soft-deleted), `create()`, `update()`, `softDelete()`, `reorder(List<String> idsInOrder)`. Build a `CategoryListNotifier` (Riverpod `AsyncNotifier`) exposing categories sorted by `sortOrder`. Build the UI: a categories screen with a data table/grid showing name, image thumbnail, active toggle, and edit/delete actions; an add/edit dialog (using `AppDialog` from the theme) with name, image picker (local file for now, upload to Supabase Storage deferred — just store local path), active toggle; drag-to-reorder support updating `sortOrder`. Every create/update/delete must set `isSynced = false`, bump `version`, and update `updatedAt` — actual network sync doesn't happen until Module 30/31, so for now these just sit local with `isSynced = false`, which is correct and expected.

**Edge Cases:**
- Deleting a category that has products assigned: block deletion, show a clear message ("Cannot delete — 4 products use this category"), don't allow orphaned products
- Empty state when no categories exist yet
- Duplicate category names: warn but don't hard-block (restaurants sometimes intentionally have similarly named categories)

**Testing Checklist:**
- Create, edit, reorder, and soft-delete categories; restart app, confirm state persists
- Attempt to delete a category with products attached (once Module 6 exists) and confirm the guard works
- Confirm `isSynced` is `false` after every local write and stays that way (since sync engine doesn't exist yet)

**Definition of Done:** Categories screen is fully functional offline, reorderable, and ready to be referenced by Products.

---

## Module 6 — Products Module

**Goal:** Core product CRUD with category assignment, price, description, image, availability.

**Cursor Prompt:**
> Build the Products feature in `features/products/`. Create the `Product` Isar collection: `name`, `categoryId` (link to Category), `basePrice` (double), `description` nullable, `imageUrl` nullable, `isAvailable` bool default true, `kitchenCategory` (string, for KDS grouping later), `printerId` nullable (link to a printer config — Settings module will define printers in Module 29, for now just store the id as a plain string field), + standard sync fields. Build `ProductRepository` (watchAll, watchByCategory, create, update, softDelete, toggleAvailability). Build a `ProductListNotifier`. UI: a products screen with filter-by-category, search by name, a data table showing thumbnail/name/category/price/availability toggle, and an add/edit form dialog. The form only covers base product fields in this module — variant and modifier assignment hooks are stubbed as disabled tabs/sections labeled "available after Module 7/8" so the form doesn't break, but full wiring happens in those modules. Quick-toggle availability directly from the table (instant unavailable/available, common during service when something runs out).

**Edge Cases:**
- Deleting a product referenced by an existing (even completed) order must not affect historical order data — orders should store a denormalized snapshot of product name/price at time of order, not just a live reference. Note this requirement now for Module 11/15 to implement.
- Marking unavailable should not delete or affect price history
- Search must be debounced and case-insensitive

**Testing Checklist:**
- Create products across multiple categories, filter and search work correctly
- Toggle availability instantly reflects in the table without a full reload
- Soft-delete hides product from active lists but record remains in Isar

**Definition of Done:** Products are fully manageable offline with category linkage; variant/modifier sections present but inert until their modules land.

---

## Module 7 — Variants Module

**Goal:** Manual variants per product (e.g., Small/Medium/Large), each with its own price.

**Cursor Prompt:**
> Build Variants as a sub-feature of Products. Create the `ProductVariant` Isar collection: `productId`, `name` (e.g. "Large"), `price` (double, overrides base price when selected), `sortOrder`, `isDefault` bool, + standard sync fields. Build `VariantRepository` scoped by productId. In the Product edit dialog from Module 6, enable the previously-stubbed Variants tab: a list of variants with add/edit/remove, reorderable, with a constraint that exactly one variant can be `isDefault` (auto-unset others on change). If a product has zero variants, it's sold at `basePrice` directly with no variant selection required at POS — this must be explicitly supported, not an error state. Show a live preview of "what the customer sees" (variant chips) inside the dialog.

**Edge Cases:**
- Product with exactly one variant: still show as a single non-optional choice at POS, or treat as if no variant exists? — Decision: if only one variant exists, auto-select it silently at POS, don't force a choice screen.
- Removing a variant that's been used in past orders must not corrupt historical order line items (same denormalized-snapshot principle as Module 6)

**Testing Checklist:**
- Add 3 variants to a product, set one default, confirm only one can be default at a time
- Product with zero variants behaves correctly (sells at base price)
- Product with one variant auto-selects without prompting (verify once POS exists in Module 11)

**Definition of Done:** variant data model and management UI complete; POS-side selection logic deferred to Module 11 but data is ready for it.

---

## Module 8 — Modifier Groups & Modifiers Module

**Goal:** Reusable modifier groups (e.g., "Extras", "Remove Ingredients") attachable to products, each modifier with optional price delta.

**Cursor Prompt:**
> Build Modifiers in `features/modifiers/`. Create two Isar collections: `ModifierGroup` (`name`, `selectionType` enum [single, multiple], `isRequired` bool, `minSelections` int, `maxSelections` int nullable, + standard sync fields) and `Modifier` (`groupId`, `name`, `priceDelta` double — can be 0 or negative for things like "No Onion", `sortOrder`, + standard sync fields). Build a standalone "Modifier Groups" management screen (separate from individual products, since groups are reusable across many products — e.g. "Extra Cheese/Patty/Sauce" group reused on every burger) with full CRUD for groups and their nested modifiers. Then in the Product edit dialog, enable the previously-stubbed Modifier Groups tab: a multi-select of which existing modifier groups apply to this product (many-to-many — store as a list of groupIds on the product, or a join table if cleaner in Isar — your call, document the choice).

**Edge Cases:**
- A modifier group marked `isRequired` with `minSelections >= 1` must be enforceable later at POS (validate this is achievable with the data model now, even though POS doesn't exist until Module 11)
- Deleting a modifier group that's attached to products: warn which products use it, allow deletion but detach gracefully (don't cascade-delete the products)
- Negative `priceDelta` (e.g., "No Cheese, -50") must be supported and display correctly with a minus sign in the UI

**Testing Checklist:**
- Create a "Extras" group (multiple, optional) and a "Spice Level" group (single, required), attach both to one product
- Confirm negative price modifiers display and store correctly
- Detach a group from a product, confirm the group itself still exists for other products

**Definition of Done:** modifier groups are reusable, attachable, and fully described for both required/optional and single/multiple selection — ready for POS enforcement in Module 11.

---

## Module 9 — Deals Module

**Goal:** Deals as independent bundled-price entities that behave like products inside the POS.

**Cursor Prompt:**
> Build Deals in `features/deals/`. Create the `Deal` Isar collection: `name`, `description` nullable, `imageUrl` nullable, `categoryId` nullable (deals can optionally appear under a category in the POS grid, or in a dedicated "Deals" section), `price` (flat bundle price, double), `isAvailable` bool, `availabilityStart`/`availabilityEnd` (DateTime nullable, for time-limited deals e.g. lunch specials), + standard sync fields. Create `DealItem` Isar collection representing the bundle contents: `dealId`, `productId`, `variantId` nullable, `quantity` int, `allowModifiers` bool (whether the customer can still customize this item within the deal). Build the Deal Builder UI: deal name/price/image/category/availability window, then an item picker letting the admin add multiple products (with quantity, e.g. "2x Drinks") to build the bundle, reusing the product/variant picker components built in Modules 6-7 wherever possible rather than rebuilding them.

**Edge Cases:**
- A deal item referencing a product that later becomes unavailable: the deal itself should show as unavailable too (computed, not manually toggled) — implement a `isEffectivelyAvailable` getter that checks both the deal's own flag and all constituent products
- Time-limited deals (lunch specials) must correctly compute availability against current time, including across midnight if a window spans it
- A deal's bundle price is independent of summing its components — don't auto-calculate, admin sets it explicitly

**Testing Checklist:**
- Build a deal with 3 different products and quantities, confirm it saves and reloads correctly
- Set a deal to a future-only availability window, confirm it's correctly flagged unavailable until that window
- Make one constituent product unavailable, confirm the deal auto-reflects unavailability

**Definition of Done:** deals are fully buildable and manageable, with correct computed availability — ready to appear in the POS grid in Module 11 exactly like a product.

---

## Module 10 — Tables & Hall Management Module

**Goal:** Hall → Table hierarchy with status (occupied/available/reserved) and table transfer.

**Cursor Prompt:**
> Build Tables in `features/tables/`. Create `Hall` Isar collection (`name`, `sortOrder`, + standard sync fields) and `RestaurantTable` Isar collection (`hallId`, `label` e.g. "T5", `capacity` int, `status` enum [available, occupied, reserved], `currentOrderId` nullable, `sortOrder`, + standard sync fields). Build a Halls management screen (simple CRUD, since most restaurants have 1-3 halls) and a visual Table layout screen per hall — a grid/floor-plan-style view where each table is a colored card/tile reflecting its status (green=available, red=occupied, yellow=reserved), tappable to either start a new order (routes into POS, wired in Module 11) or view the current order if occupied. Implement "Transfer Table" — moving an active order from one table to another, updating both tables' status and the order's `tableId`. No table merge or split functionality (explicitly out of scope per requirements).

**Edge Cases:**
- Transferring to a table that's already occupied must be blocked with a clear error
- A table going from occupied back to available must verify the order is actually completed/paid first, not just manually flippable (prevent accidental data loss) — or allow manual override but require a confirmation dialog
- Reserved status doesn't auto-expire; staff manage it manually for v1

**Testing Checklist:**
- Create halls and tables, confirm visual status grid renders and color-codes correctly
- Transfer an order between two available tables, confirm source becomes available and destination becomes occupied
- Attempt transfer to an occupied table, confirm it's blocked

**Definition of Done:** visual table management is fully functional offline; tapping a table is ready to hand off into POS (Module 11) and reflect live order status (Module 16).

---

## Module 11 — POS — Cart, Product & Deal Selection

**Goal:** The core ordering screen: browse products/deals, select variants/modifiers, build a cart.

**Cursor Prompt:**
> Build the POS feature in `features/pos/`. Create a `CartItem` domain model (not an Isar collection yet — it's transient until checkout) holding: `productId` or `dealId`, denormalized `name` and `unitPrice` snapshot (per the Module 6 requirement), selected `variantId`/`variantName`/`variantPriceOverride` nullable, list of selected modifiers (each with id, name, priceDelta snapshot), `quantity`, computed `lineTotal`. Build a `CartNotifier` (Riverpod `Notifier<List<CartItem>>`) with add/remove/updateQuantity/clear and a derived `cartTotalProvider`. Build the POS screen UI: a product/deal grid on the left (grouped by category tabs, including a "Deals" tab pulling from Module 9, respecting `isAvailable`/effective availability), and a running cart panel on the right showing line items, quantities (+/- steppers), and the total. Tapping a product with variants opens a variant picker bottom sheet/dialog; if the product has modifier groups, the modifier picker follows, enforcing `isRequired`/`min`/`maxSelections` from Module 8 before allowing "Add to Cart". Products/deals with zero variants and zero modifiers add directly to cart with one tap.

**Edge Cases:**
- Adding the same product+variant+modifier combination twice should increment quantity on the existing line item rather than creating a duplicate line, but a different modifier combination of the same product is a separate line item
- Required modifier groups must block "Add to Cart" until satisfied, with a clear validation message
- Cart must survive navigating away and back within the same in-progress order (don't lose state on accidental nav) — this becomes fully robust once Draft Orders (Module 17) exists, but at minimum the cart shouldn't clear itself on a simple tab switch

**Testing Checklist:**
- Add a simple product (no variants/modifiers) — one tap, appears in cart
- Add a product with variants and required modifiers — confirm validation blocks incomplete selections
- Add a deal — confirm it behaves identically to a product in the cart
- Adjust quantities and remove items, confirm total recalculates correctly every time

**Definition of Done:** a fully working product/deal browsing and cart-building experience, offline, with correct price snapshotting — ready for order type selection (Module 12) and checkout (Module 15).

---

## Module 12 — POS — Order Type & Delivery

**Goal:** Choosing Dine In / Take Away / Delivery, and for Delivery, own rider vs pickup company.

**Cursor Prompt:**
> Extend the POS feature: add an `OrderType` enum (`dineIn`, `takeAway`, `delivery`) and a `DeliveryMode` enum (`ownRider`, `pickupCompany`) to the in-progress order state (extend the `CartNotifier`'s scope or add a sibling `CheckoutNotifier` holding order-type metadata alongside the cart — your call on the cleanest Riverpod structure, but keep cart items and order-type metadata logically separable). Build an order-type selector shown after the cart has at least one item: three clear options (Dine In, Take Away, Delivery). Selecting Dine In opens the table picker from Module 10, filtered to available tables, and assigns `tableId`. Selecting Take Away requires no further selection. Selecting Delivery reveals the rider/pickup-company choice: "Own Rider" opens a rider picker (data model for riders comes from Module 13 — stub a simple `Rider` Isar collection here with just `name` and `isActive` if Module 13 hasn't run yet, Module 13 will extend it) or "Pickup Company" opens a picker from the configurable pickup companies list (also Module 13).

**Edge Cases:**
- Switching order type after a table was already selected (e.g., admin picks Dine In/Table 5, then changes mind to Take Away) must release the table back to available
- Delivery orders must require either a rider or pickup company selected before checkout can proceed — validate this at the Module 15 placement step, not just visually
- Dine In table picker should hide tables already occupied by other in-progress orders

**Testing Checklist:**
- Select each order type and confirm the correct follow-up UI appears
- Pick Dine In then switch to Take Away, confirm the table is released
- Attempt to proceed to checkout on a Delivery order with no rider/company selected, confirm it's blocked

**Definition of Done:** order type and delivery sub-flow fully functional and validated, feeding into the order placement step in Module 15.

---

## Module 13 — Pickup Companies & Riders Configuration

**Goal:** Configurable (not hardcoded) list of delivery pickup companies, plus own-rider management.

**Cursor Prompt:**
> Build `features/delivery_config/`. Create/extend `PickupCompany` Isar collection (`name`, `logoUrl` nullable, `isActive` bool, + standard sync fields) and `Rider` Isar collection (`name`, `phone` nullable, `isActive` bool, + standard sync fields). Build a simple management screen (likely nested under Settings, Module 29, but functional standalone now) with CRUD for both lists — admin can add/remove/deactivate pickup companies (e.g. Foodpanda, Careem, Bykea, or any custom one) and riders without touching code. Update the Module 12 pickup-company and rider pickers to pull live from these collections instead of any earlier stub.

**Edge Cases:**
- Deactivating a pickup company or rider that's referenced by in-progress (not yet completed) delivery orders should not retroactively break those orders — same denormalized-snapshot principle: store the name as well as the id on the order
- Empty list state: if no riders/companies exist yet, the Module 12 picker should show a clear "none configured — add one in Settings" message rather than an empty dead-end

**Testing Checklist:**
- Add, edit, deactivate a pickup company and a rider; confirm Module 12's pickers reflect changes live
- Confirm deactivated entries don't appear as selectable but historical orders referencing them still display correctly

**Definition of Done:** pickup companies and riders are fully admin-configurable with no hardcoded values anywhere in the codebase.

---

## Module 14 — POS — Discounts

**Goal:** Item-level, category-level, and whole-order discounts, both percentage and fixed.

**Cursor Prompt:**
> Extend the checkout flow with a `Discount` domain model: `scope` enum (`item`, `category`, `wholeOrder`), `targetId` nullable (productId or categoryId depending on scope, null for wholeOrder), `type` enum (`percentage`, `fixed`), `value` double, `reason` nullable string (for audit/reporting later). Build discount application UI: a discount icon/button on each cart line item (item-level), a "discount by category" action accessible from the cart panel, and a whole-order discount field near the total. Apply discounts to compute a `discountedTotal` alongside the original `subtotal`, both stored on the eventual order so reporting (Module 23) can show discount impact accurately. Multiple discounts can stack (e.g., a category discount plus a whole-order discount) — compute them in a clearly defined order (item/category discounts applied first to line totals, then whole-order discount applied to the resulting subtotal) and make that order visible in the UI breakdown, not hidden.

**Edge Cases:**
- A discount must never bring a line or order total below zero — clamp at 0 and show a warning if the entered value would
- Percentage discounts on items with already-discounted prices (stacking item + category on the same line) must compute predictably — document and test the exact order of operations
- Discount reason should be optional but encouraged; not blocking

**Testing Checklist:**
- Apply a 20% item discount, a 10% category discount, and a flat 500 whole-order discount in combination, verify the math against manual calculation
- Attempt a discount that would push total negative, confirm it's clamped with a warning
- Confirm the breakdown (subtotal → after item/category discounts → after order discount → final total) is visible somewhere in the cart UI

**Definition of Done:** discounting is fully functional, predictable, and transparent in the UI — ready to be locked into the order at placement (Module 15).

---

## Module 15 — POS — Payment & Order Placement

**Goal:** Select payment type and commit the cart into a real, persisted Order record.

**Cursor Prompt:**
> Create the `Order` and `OrderItem` Isar collections (this is the central entity of the whole system). `Order`: `orderNumber` (human-readable sequential or date-based, generated locally), `orderType`, `tableId` nullable, `deliveryMode` nullable, `riderId`/`riderName` nullable, `pickupCompanyId`/`pickupCompanyName` nullable, `subtotal`, `itemDiscountTotal`, `orderDiscountTotal`, `total`, `paymentType` enum (`cash`, `card`, `online`), `paymentStatus` enum (`unpaid`, `paid`), `status` enum (`received`, `preparing`, `ready`, `served`, `paid`, `completed`, `cancelled`), `isPrepaid` bool (derived from order type per the global rule: takeAway/delivery default true, dineIn default false, but allow manual override at checkout), `createdByUserId`, `notes` nullable, + standard sync fields. `OrderItem`: `orderId`, denormalized product/deal name, variant name, unit price, quantity, line total, applied discounts, list of selected modifiers (denormalized name+price), `kitchenStatus` enum mirroring relevant parts of order status for per-item kitchen tracking. Build the final checkout screen: payment type selector, a clear summary of everything selected so far (order type, table/delivery info, items, discounts, total), and a "Place Order" button that atomically writes the Order + OrderItems to Isar, sets the table to occupied (if dine-in), clears the cart, and navigates to an order confirmation/receipt-ready state. If `isPrepaid` is true, `paymentStatus` is set to `paid` immediately on placement; otherwise it stays `unpaid` until Module 16 marks it paid later in the lifecycle.

**Edge Cases:**
- Order number generation must avoid collisions when used across multiple offline devices that haven't synced yet — prefix with deviceId or use a UUID-based human-readable scheme (e.g. last 6 chars of a UUID) rather than a simple incrementing counter
- Placing an order must be atomic — if anything fails partway, nothing should be half-written (wrap in an Isar transaction)
- Empty cart should never be placeable — guard at the UI level

**Testing Checklist:**
- Place a Dine In order, confirm `paymentStatus` stays `unpaid` and the table becomes occupied
- Place a Take Away order, confirm `paymentStatus` is immediately `paid`
- Restart the app after placing several orders, confirm all persisted correctly with correct totals

**Definition of Done:** orders are fully placeable, persisted, and correctly reflect payment/order-type rules — the entire POS flow from Module 11 through here is now end-to-end functional offline.

---

## Module 16 — Order Lifecycle & Status Management

**Goal:** Full status progression, edit-until-paid, cancel-not-delete, table release on completion.

**Cursor Prompt:**
> Build `features/orders/` with an Orders list/detail view (separate from POS — this is the management/oversight screen). Implement status transitions: `received → preparing → ready → served → paid → completed`, each transition a clear action button available based on current status and role (full control for admin; salesman gets a restricted subset, enforced fully in Module 32 but design the permission check now). Implement **edit until paid**: while `paymentStatus` is `unpaid`, the order can be reopened into the POS cart UI (Module 11) to add/remove items/modifiers/discounts, recalculating totals — once `paymentStatus` becomes `paid`, the order becomes read-only (no further item edits, only status progression). Implement **cancel**: sets `status` to `cancelled`, requires a reason (free text), releases the table if dine-in, but the record is never deleted — it remains fully visible in Orders history and counted (separately) in reporting. Implement automatic table release: when an order reaches `completed` or `cancelled`, its associated table flips back to `available` automatically.

**Edge Cases:**
- Attempting to edit a `paid` order must be blocked with a clear explanation, not just a disabled button with no context
- Cancelling an order that already has `paymentStatus: paid` (e.g., a prepaid takeaway customer no-show) is a legitimate case — must be supported, and should probably prompt for a refund note even though no actual payment processing is in scope
- Marking `paid` manually for a postpaid (dine-in) order must require selecting a final payment type at that moment if it wasn't set, since dine-in often doesn't commit to a payment type until the end

**Testing Checklist:**
- Walk a Dine In order through every status from received to completed, confirm table releases only at completion
- Edit an unpaid order's items, confirm totals recalculate; mark it paid, confirm it becomes read-only
- Cancel an order with a reason, confirm it remains visible in the orders list, clearly marked, table released

**Definition of Done:** the complete order lifecycle is enforced correctly with no illegal state transitions, and editing/cancellation rules match the spec exactly.

---

## Module 17 — Draft Orders

**Goal:** Save an in-progress, uncommitted cart for later resumption (customer asked to wait, order not yet placed).

**Cursor Prompt:**
> Create a `DraftOrder` Isar collection storing a serialized snapshot of the in-progress POS state from Module 11/12/14 (cart items, order type, table/delivery selections, discounts applied so far — everything except payment, since a draft is by definition not yet placed) plus a `label` (optional, e.g. "Table 5 - waiting on customer"), `createdByUserId`, + standard sync fields. Add a "Save as Draft" action in the POS screen that serializes current state and clears the active cart. Build a Drafts list (accessible from the POS screen, e.g. a "Drafts" tab/badge showing count) letting staff reopen a draft, which restores it fully into the POS cart for continuation, removing it from the drafts list once resumed (or kept until explicitly placed — your call, but document the choice clearly in code comments).

**Edge Cases:**
- If a draft references a table, does saving as draft keep the table marked occupied or not? — Decision: yes, keep it occupied, since the customer is physically still there; only release on cancel/completion of the eventual real order, or if the draft itself is explicitly discarded
- Discarding a draft (not resuming, just deleting it) must release any table it was holding
- Drafts should not appear anywhere in sales/reporting since they were never placed orders

**Testing Checklist:**
- Build a cart, save as draft with a label, confirm cart clears and table stays occupied
- Reopen the draft, confirm full state (items, modifiers, discounts, order type) restores exactly
- Discard a draft, confirm its table releases and it's removed from the list

**Definition of Done:** drafts reliably save and restore full in-progress order state, with correct table-occupancy handling.

---

## Module 18 — Hold Orders

**Goal:** Lightweight pause/resume for an order already placed but temporarily set aside (distinct from Draft, which is pre-placement).

**Cursor Prompt:**
> Add a `held` boolean (or fold into the `OrderStatus` enum as a parallel flag, not a replacement status, since a held order retains its real status like `preparing` underneath) to the `Order` model from Module 15. Add "Hold" and "Resume" actions in the Orders screen (Module 16) and optionally directly in POS for very fast access during busy service. A held order is visually distinguished (e.g., a badge/highlight) in both the Orders list and Kitchen Display (Module 19, once it exists) but is not removed from any list — it's a visibility/priority flag, not a status change. Resuming simply unsets the flag.

**Edge Cases:**
- Held orders must still count correctly in reporting and sales totals — hold is purely an operational UI flag, never affects financials or completion logic
- A held order can still be cancelled or have its status progressed by an admin if needed (hold shouldn't lock the record, just flag it)

**Testing Checklist:**
- Hold an active order, confirm it's visually flagged in Orders list, resume it, confirm flag clears
- Confirm a held order's totals still appear correctly in Sales (once Module 22 exists)

**Definition of Done:** hold/resume works as a pure visibility flag with zero side effects on order data integrity.

---

## Module 19 — Kitchen Display System (KDS)

**Goal:** Kitchen-only view: incoming/preparing/ready orders, nothing else (no sales, money, customers, attendance).

**Cursor Prompt:**
> Build `features/kitchen/`. Create a dedicated Kitchen Display screen (intended to run full-screen on a kitchen terminal) showing three columns: Incoming (status `received`), Preparing, Ready — pulling from `OrderItem.kitchenStatus` (per-item, since a kitchen ticket may have multiple items at different prep stages, e.g. grill items vs salad items) grouped by their parent order. Each card shows order number, table/order-type, item list with modifiers (no prices — kitchen doesn't need money info), and a quick action to advance the item (and consequently check whether all items in the order have reached "ready" to auto-advance the parent order's overall status). Large, high-contrast, touch-friendly cards suitable for a kitchen environment (different visual density than the admin desktop screens — this screen can deviate from standard desktop density for usability). Held orders (Module 18) get a clear visual flag here too. The KDS screen must show absolutely nothing related to sales totals, payment status, reports, or attendance — verify no such data leaks into this view even incidentally.

**Edge Cases:**
- An order with items split across different kitchen categories (e.g., grill + cold) — confirm the per-item kitchenStatus model handles mixed-pace preparation correctly, not just whole-order status
- KDS should auto-refresh/reactively update via Riverpod streams from Isar — no manual refresh button needed for new orders to appear
- Cancelled orders must immediately disappear from KDS, not linger

**Testing Checklist:**
- Place an order in POS, confirm it appears on KDS within Incoming instantly
- Advance items through preparing/ready, confirm parent order status auto-advances when all items reach ready
- Confirm zero financial or customer data is visible anywhere on this screen
- Cancel an order mid-prep, confirm it disappears from KDS immediately

**Definition of Done:** a fast, kitchen-appropriate, strictly scoped display that reactively tracks order/item prep status.

---

## Module 20 — Printing — Kitchen Ticket

**Goal:** Print kitchen tickets to a thermal printer on order placement (and reprintable on demand).

**Cursor Prompt:**
> Build `features/printing/kitchen_ticket/`. Integrate a thermal printer package compatible with Windows (research and use the most maintained ESC/POS-compatible Flutter package available; document the chosen package and its setup requirements in code comments since this involves native printer communication). Design a kitchen ticket template: order number, table/order-type, timestamp, item list with quantities and modifiers (no prices, matching KDS scoping), grouped by kitchen category if a product has one set (Module 6). Trigger automatic printing on order placement (Module 15) to the printer configured for the relevant kitchen category/printer assignment (printer config itself lives in Settings, Module 29 — for now accept a printer identifier as a simple string/IP and store it in a basic local settings collection if Module 29 hasn't run yet). Add a manual "Reprint Kitchen Ticket" action from the Orders screen (Module 16) and KDS (Module 19).

**Edge Cases:**
- No printer connected/configured: placing an order must still succeed — printing failure should show a clear non-blocking warning, never block or roll back the order itself
- An order with items destined for multiple kitchen printers (e.g., grill items to one printer, drinks to another) should print separate tickets to each correctly
- Reprint must be clearly marked "REPRINT" on the ticket to avoid kitchen confusion about duplicate orders

**Testing Checklist:**
- Place an order, confirm a correctly formatted kitchen ticket prints automatically
- Disconnect the printer, place an order, confirm the order still succeeds with a clear warning shown
- Reprint a ticket, confirm it's visibly marked as a reprint

**Definition of Done:** kitchen tickets print reliably and correctly, with graceful non-blocking failure handling.

---

## Module 21 — Printing — Customer Receipt

**Goal:** Print customer-facing receipts with prices/totals, reprintable.

**Cursor Prompt:**
> Build `features/printing/receipt/`, reusing the printer integration from Module 20. Design a customer receipt template: business name/header (configurable in Settings, Module 29 — accept simple placeholder constants for now), order number, date/time, order type, itemized list with prices/modifiers/quantities, discount breakdown, subtotal, total, payment type, payment status. Trigger printing at the appropriate lifecycle point per the prepaid/postpaid rule from Module 15/16 (prepaid orders print on placement; postpaid orders print when marked paid in Module 16). Add a manual "Reprint Receipt" action in the Orders screen.

**Edge Cases:**
- Same non-blocking failure handling as Module 20 — a printer issue must never block payment/order completion
- Receipt totals must exactly match what's stored on the order record (no recalculation drift — print directly from the persisted order/order-item data, never re-derive)
- Reprint must be marked clearly

**Testing Checklist:**
- Complete a prepaid order, confirm receipt prints automatically on placement
- Complete a postpaid order, confirm receipt prints automatically when marked paid (not before)
- Reprint a receipt, confirm totals match the original order exactly and it's marked as a reprint

**Definition of Done:** customer receipts print correctly at the right lifecycle moment with accurate, non-recalculated data.

---

## Module 22 — Sales Module/Tab

**Goal:** A dedicated Sales view — overall sales and per-product breakdowns, with as many useful slices as practical.

**Cursor Prompt:**
> Build `features/sales/`. Create a Sales screen with a date-range selector (today/this week/this month/custom range) and these views, switchable via tabs or filters: Overall Sales (total revenue, total orders, average order value, broken down by order type — dine-in/takeaway/delivery — for the selected range), Per-Product Sales (table of every product/deal sold in range with quantity sold and revenue generated, sortable by either column), Per-Category Sales, Per-Payment-Method Sales (cash/card/online split), Per-Employee Sales (which staff member placed/served the most, tied to `createdByUserId` on orders — full employee linkage completes once Module 24 exists, but the query should be ready). All figures must correctly exclude cancelled orders from revenue counts (but cancelled order count itself can be shown as a separate informational stat) and must correctly account for discounts (show both gross and net-of-discount figures). Build these as efficient Isar queries with proper indexing on `createdAt`/`status` so the screen stays responsive as order volume grows.

**Edge Cases:**
- Orders spanning a date-range boundary at exactly midnight must be bucketed correctly and consistently with however Reports (Module 23) buckets daily figures — use the same date-bucketing utility function for both to avoid mismatched numbers between Sales and Reports screens
- A discounted order's "revenue" must clearly be the net (post-discount) total in headline figures, with gross-before-discount available as a secondary stat, not the reverse
- Empty date ranges (no sales) should show a clean empty state, not a broken chart/table

**Testing Checklist:**
- Place several orders with mixed types, payment methods, and discounts across a couple of days; confirm Overall Sales totals match manual calculation
- Confirm Per-Product sorting works correctly both by quantity and by revenue
- Confirm a cancelled order is excluded from revenue but its existence doesn't crash any view

**Definition of Done:** Sales screen gives accurate, correctly-scoped, multi-angle visibility into revenue, fully offline-computed from local Isar data.

---

## Module 23 — Reports Module

**Goal:** The full comprehensive reporting suite beyond what Sales (Module 22) already covers.

**Cursor Prompt:**
> Build `features/reports/`, reusing the date-bucketing utility from Module 22 for consistency. Implement these report views, each with its own clear table/chart: Sales reports (daily/weekly/monthly/yearly trend), Deals Sales report, Discount Report (total discount given, broken down by item/category/whole-order discount types, with reasons where provided), Cancelled Orders report (count, value-if-not-cancelled, top cancellation reasons), Kitchen Performance (average time from `received` to `ready` per item/category — requires timestamps to be captured at each status transition in Module 16, confirm those timestamps exist; if Module 16 only stored a single `updatedAt`, extend the Order/OrderItem model now with explicit per-status timestamp fields), Peak Hours (order volume by hour-of-day, visualized as a simple bar chart), Average Order Value trend over time, Most Ordered Products, Least Ordered Products (both top-N, configurable N). Every report must support the same date-range filtering pattern as Sales for consistency.

**Edge Cases:**
- Kitchen Performance requires per-status timestamps that may not have existed before this module — if retrofitting onto Module 16's Order model, ensure old orders without these timestamps degrade gracefully (show "N/A" rather than a wrong calculated duration)
- Peak Hours must correctly handle timezone consistently with the rest of the app (use device local time throughout, document this assumption)
- Least Ordered Products should exclude products that don't exist yet in the selected range at all vs. products that exist but had zero sales — clarify in the UI which is being shown

**Testing Checklist:**
- Generate each report with a meaningful spread of test data and manually verify at least one figure per report against raw order data
- Confirm Kitchen Performance gracefully handles orders missing timestamp data
- Confirm all reports respect the selected date range consistently

**Definition of Done:** the full reporting suite from the spec is implemented, accurate, and performant against local data.

---

## Module 24 — Employees Management

**Goal:** Employee records, independent of login accounts (which come in Module 33).

**Cursor Prompt:**
> Build `features/employees/`. Create `Employee` Isar collection: `fullName`, `role` (job role, e.g. "Waiter", "Chef" — distinct from the system `UserRole` enum, this is just descriptive), `phone` nullable, `hireDate`, `hourlyRate` or `monthlySalaryBase` (support both, with a `payType` enum determining which applies), `fingerprintEnrollmentId` nullable (links to the biometric device's internal ID once Module 25 enrolls them), `isActive` bool, + standard sync fields. Build full CRUD UI: employee list with search/filter by active status, add/edit form. Note: this module deliberately does NOT create login credentials — that linkage happens in Module 33 when an admin optionally creates a system user account tied to an employee record for those who need POS access (e.g., a salesman).

**Edge Cases:**
- Deactivating an employee must not delete their historical attendance/sales/salary records (soft-delete principle again)
- `payType` switching (hourly vs monthly) mid-employment should not corrupt past salary calculations — past salary slips (Module 27) are immutable snapshots regardless of later pay-type changes

**Testing Checklist:**
- Create employees with both pay types, confirm form adapts fields shown correctly
- Deactivate an employee, confirm they're hidden from active-only views but remain in records

**Definition of Done:** employee records are fully manageable and ready to be referenced by Attendance, Salary, and (later) user accounts.

---

## Module 25 — Biometric Attendance

**Goal:** USB fingerprint check-in/check-out, with manual fallback.

**Cursor Prompt:**
> Build `features/attendance/`. Create `AttendanceRecord` Isar collection: `employeeId`, `checkInTime`, `checkOutTime` nullable, `source` enum (`fingerprint`, `manual`), `createdByUserId` (relevant for manual entries, to track which admin entered it), `notes` nullable, + standard sync fields. Research and integrate a USB fingerprint device SDK/package compatible with Flutter Windows desktop (document the chosen approach clearly, since hardware integration is inherently device-specific — build this behind a clean `BiometricService` interface so the actual device integration can be swapped without touching UI code). Build an Attendance screen: a live "scan to check in/out" panel when a fingerprint event is detected from the device, automatically matching to the `fingerprintEnrollmentId` on an Employee record and creating/closing an `AttendanceRecord`; an employee enrollment flow (capture and store a fingerprint template against an Employee); and a manual entry/correction screen for when the device fails or an admin needs to fix an entry, clearly tagging `source: manual` and logging which admin made the correction.

**Edge Cases:**
- Device unavailable/not connected: app must function normally otherwise, with a clear "fingerprint device not detected" state, and the manual entry path must remain fully usable as the complete fallback
- A check-in without a matching enrolled employee (unrecognized scan) should show a clear error, not silently fail or create a phantom record
- Double check-in (scanning again without checking out first) — decide and implement a clear rule: either treat the second scan as a check-out, or block it with a message; document the choice

**Testing Checklist:**
- Enroll a test employee's fingerprint (or simulate if hardware isn't available during dev — build a debug "simulate scan" trigger for testing without physical hardware), check in and out, confirm record created/closed correctly
- Disconnect the device, confirm manual entry still works fully
- Attempt a scan for an unenrolled employee, confirm a clear error rather than a crash

**Definition of Done:** attendance tracking works via biometric device when available and via manual entry always, with hours correctly calculable from check-in/check-out pairs — ready for Module 26.

---

## Module 26 — Salary Calculation

**Goal:** Compute hours worked and resulting pay from attendance records.

**Cursor Prompt:**
> Build `features/salary/calculation/`. Implement a calculation service (not a UI-heavy module — mostly logic) that, for a given employee and date range, sums all closed `AttendanceRecord` durations (checkOutTime - checkInTime) into total hours, then computes pay based on the employee's `payType`: hourly → `totalHours * hourlyRate`; monthly → `monthlySalaryBase` prorated if the range isn't a full month, or full amount if it is (define prorating clearly — e.g., based on standard working days in the period). Handle open attendance records (checked in, not yet checked out) within the calculation period by either excluding them from the total (since the shift isn't complete) or counting up to "now" if calculating a live/in-progress estimate — support both via a parameter, since payroll-final calculations need the former and a live dashboard glance might want the latter. Build a simple preview screen showing, per employee, computed hours and pay for a selected period before committing to a salary slip (which happens in Module 27).

**Edge Cases:**
- Overnight shifts (check-in 11pm, check-out 7am) must compute duration correctly across the midnight boundary
- Manual attendance corrections (Module 25) must feed into this calculation identically to fingerprint-sourced records — no special-casing by source
- An employee with zero attendance records in the period should show 0 hours / 0 pay, not an error

**Testing Checklist:**
- Create attendance records including an overnight shift, confirm total hours compute correctly
- Compute pay for both an hourly and a monthly employee over a partial-month range, verify the math
- Confirm an open (not checked out) record is correctly excluded from a "final" calculation but included in a "live" one

**Definition of Done:** salary calculation logic is accurate and well-tested in isolation, ready to be locked into immutable slips in Module 27.

---

## Module 27 — Salary Slip Generation

**Goal:** Auto-generate salary slips on a fixed date, as immutable records.

**Cursor Prompt:**
> Build `features/salary/slips/`. Create `SalarySlip` Isar collection: `employeeId`, `periodStart`, `periodEnd`, `totalHours`, `basePay`, `deductions` nullable (out of scope to compute automatically, but allow a manual adjustment field), `netPay`, `generatedAt`, `generatedByUserId`, `status` enum (`draft`, `finalized`), + standard sync fields — once `finalized`, a slip must be fully immutable (no further edits, only viewable/printable/exportable). Build a settings-driven trigger: a configurable "salary generation day" (e.g., 1st of each month) stored in a simple local settings entry; on app launch, check if today matches and slips haven't yet been generated for the prior period, and if so auto-generate `draft` slips for every active employee using the Module 26 calculation service, with an admin notification/banner to review and finalize them (don't auto-finalize without review). Build a Salary Slips screen: list by period, view/print individual slips, finalize action, and a manual "generate now" trigger for cases where the admin wants to run it ahead of the automatic date.

**Edge Cases:**
- Auto-generation must be idempotent — if the app is opened multiple times on/after the trigger date, it must not create duplicate slips for the same employee/period
- An employee deactivated mid-period should still get a final slip for the portion of the period they were active, not be silently skipped
- Finalizing a slip must lock the underlying calculation even if attendance records are edited afterward (store the computed numbers directly on the slip, don't recompute live from attendance once finalized)

**Testing Checklist:**
- Simulate reaching the generation date (or use the manual trigger), confirm draft slips generate for all active employees with correct figures
- Re-trigger generation for the same period, confirm no duplicates are created
- Finalize a slip, then edit the underlying attendance records, confirm the finalized slip's figures remain unchanged

**Definition of Done:** salary slips generate reliably and automatically, with correct immutability after finalization.

---

## Module 28 — Analytics Dashboard

**Goal:** The at-a-glance home screen — cards and charts pulling from everything built so far.

**Cursor Prompt:**
> Build `features/dashboard/`, replacing the placeholder Dashboard route from Module 4. Build the cards row: Today's Sales, Orders Today, Preparing, Ready, Served, Cancelled, Employees Present (live from Module 25's open attendance records), Monthly Revenue, Average Ticket — each pulling from the repositories/queries already built in Sales (Module 22), Orders (Module 16), and Attendance (Module 25), not duplicated logic. Build the charts row: Sales Trend (line chart, last 30 days), Orders Trend, Payment Distribution (pie/donut), Top Products (bar chart) — reuse a single charting approach consistently across all of them (pick one charting package and stick with it app-wide). This screen should auto-refresh reactively (Riverpod streams) as new orders come in, since it's the screen admins will have open most of the time.

**Edge Cases:**
- All cards/charts must handle a brand-new install with zero data gracefully (zeros and empty-state charts, not errors)
- "Employees Present" must update live the moment someone checks in/out via Module 25, without requiring a manual dashboard refresh
- Charts must remain readable/responsive at different desktop window sizes

**Testing Checklist:**
- Open dashboard on a fresh install, confirm clean zero-state
- Place orders, check employees in/out, confirm every card and chart updates reactively without manual refresh
- Resize the window, confirm charts adapt without breaking

**Definition of Done:** a fully reactive, accurate, visually clean dashboard summarizing the whole system's live state.

---

## Module 29 — Settings Module

**Goal:** Centralize all the configuration values that earlier modules stubbed or hardcoded.

**Cursor Prompt:**
> Build `features/settings/`. Consolidate into one Settings screen with clear sections: General (business name, address, receipt header/footer text — used by Module 21), Printers (named printer configs with connection details, replacing any string stubs from Module 20/21, with the ability to assign which kitchen category routes to which printer), Pickup Companies & Riders (surface the Module 13 management screens here as the canonical location), Salary Generation (the trigger day from Module 27), and any other loose configuration values introduced in earlier modules that were temporarily hardcoded — audit the codebase for `// TODO: move to settings` style markers left in earlier modules and resolve them here. Store all settings in a single `AppSettings` Isar collection (singleton-style, one record) for simplicity rather than scattering many tiny collections.

**Edge Cases:**
- Settings changes (e.g., reassigning a printer) must take effect immediately for new orders without requiring an app restart
- Sensible defaults must exist for every setting so a fresh install isn't broken before the admin visits this screen

**Testing Checklist:**
- Change each setting category, confirm it correctly affects the relevant earlier module's behavior (e.g., printer reassignment routes the next kitchen ticket correctly)
- Confirm fresh-install defaults are sane

**Definition of Done:** all previously hardcoded/stubbed configuration is centralized, admin-editable, and takes effect live.

---

## Module 30 — Offline Sync Queue Infrastructure

**Goal:** The structural sync queue — not yet actually talking to Supabase, just correctly tracking what needs to go.

**Cursor Prompt:**
> Build `core/sync/sync_queue.dart`. Every Isar write across every collection built so far (Modules 5-29) already sets `isSynced = false` and bumps `version` per the Global Conventions — confirm this is consistently true everywhere (audit pass across all repositories) and fix any module that missed it. Build a `SyncQueueService` that can query, across all collections, every record where `isSynced == false`, grouped by entity type and ordered by `updatedAt`, exposing this as a Riverpod stream so a "pending sync" count can be shown somewhere in the UI (e.g., a small badge in the app shell from Module 4 — implement that badge now). This module is purely about correctly identifying what needs syncing; the actual upload/download logic is Module 31.

**Edge Cases:**
- Soft-deleted records (`deletedAt` set) must still be included in the sync queue (deletes need to sync too) and clearly distinguishable via `syncAction == delete`
- A record edited multiple times offline before any sync should only need to sync its latest state, not every intermediate version — confirm the queue naturally reflects "current state" per record, not a change log

**Testing Checklist:**
- Make various creates/updates/deletes across several different entity types, confirm the pending-sync badge count reflects them all accurately
- Confirm a record edited 3 times offline appears once in the queue with its latest values, not 3 times

**Definition of Done:** the app can accurately report exactly what's pending sync at any moment, across every entity type, fully offline.

---

## Module 31 — Sync Engine — Upload / Download / Conflict Resolution

**Goal:** The real bidirectional sync against Supabase.

**Cursor Prompt:**
> Build `core/sync/sync_engine.dart`. Implement the full cycle: detect connectivity (use a connectivity-checking package, triggered both on a timer and on app foreground/network-change events), then for each entity type with pending records (from Module 30's queue), Upload Pending (push local creates/updates/deletes to the corresponding Supabase table, matching by `id`), Download Changes (pull any Supabase records with `updatedAt` newer than the last successful sync timestamp for that entity type, stored locally), Resolve Conflict (if both local and remote have changed the same record since last sync, use `version` field comparison — higher version wins; if versions are equal, use `updatedAt` as tiebreaker; log every conflict resolution for visibility, don't silently discard data — consider keeping the losing version accessible somewhere for manual admin review rather than hard-discarding), Mark Synced (set `isSynced = true` locally once confirmed written to Supabase, update the last-sync timestamp for that entity). Build a simple Sync Status screen (accessible from the app shell) showing last sync time, current sync state (idle/syncing/error), and a manual "sync now" trigger. Run the full cycle automatically whenever connectivity returns after being offline, and on a reasonable interval (e.g. every few minutes) while online.

**Edge Cases:**
- A record deleted locally while offline, but edited remotely by another device in the meantime — deletion should generally win for a restaurant POS context (don't resurrect data the local device explicitly removed), but document this decision clearly since it's a real judgment call
- Sync must be interruptible mid-cycle (app closes, connectivity drops again) without corrupting data — design each entity's sync as independently resumable, not an all-or-nothing transaction across the whole queue
- Very large initial syncs (e.g., first sync after weeks offline, or first sync on a brand new device joining an existing restaurant) must not freeze the UI — run on a background isolate or chunk the work with progress feedback

**Testing Checklist:**
- Create records on two separate test devices/profiles while both offline, bring both online, confirm conflict resolution behaves per the documented rule and no data is silently lost
- Kill the app mid-sync, relaunch, confirm sync resumes/completes correctly without duplicate or corrupted records
- Confirm the Sync Status screen accurately reflects state throughout

**Definition of Done:** the app reliably and safely syncs bidirectionally with Supabase, handles conflicts predictably, and survives interruption — this is the most safety-critical module in the whole system; do not rush its testing.

---

## Module 32 — Salesman Restricted Role View

**Goal:** Implement the actual restricted navigation for the `salesman` role (previously stubbed empty in Module 4).

**Cursor Prompt:**
> Update `navigationItemsProvider` from Module 4: when role is `salesman`, return only Dashboard, New Order (POS), Orders, Tables, Kitchen Status — nothing else. Audit every screen built in Modules 5-29 and add a role guard (a simple wrapper or router-level check) ensuring a salesman session cannot navigate directly to a restricted route even via a deep link/manual URL, not just hide the nav item. The salesman's Dashboard (Module 28) should likely show a reduced card set appropriate to their role (e.g., no full revenue figures if that's a business decision — confirm and implement: salesman dashboard shows operational cards like Orders Today/Preparing/Ready/Served, not necessarily Monthly Revenue). The salesman's Orders view should work identically to admin's in terms of functionality (place, edit-until-paid, status progress) but obviously won't include Reports/Sales/Analytics access. Kitchen Status for salesman is a read-only view into KDS-equivalent status, not the full Settings-laden Orders management screen.

**Edge Cases:**
- A salesman session attempting to navigate to a restricted URL directly must redirect cleanly to their Dashboard, not show a broken/blank screen
- This module still operates entirely under the Module 0-4 mock-auth pattern — role is still hardcoded for testing purposes here (test by temporarily flipping the mock provider's role, don't wait for Module 33)

**Testing Checklist:**
- Flip the mock user's role to salesman, confirm only the 5 permitted nav items appear
- Attempt to navigate to a restricted route via direct route manipulation, confirm it's blocked/redirected
- Confirm salesman can still fully operate POS (place, edit, status-progress orders) within their permitted screens

**Definition of Done:** role-based restriction is enforced at both the navigation and route level, fully testable via the mock provider ahead of real auth.

---

## Module 33 — Authentication (Supabase Auth)

**Goal:** Replace the mock auth provider with real Supabase Auth, login screen, and user-to-employee linkage. This is the only module that touches everything built before it — be careful.

**Cursor Prompt:**
> Implement real authentication. Build a login screen (email/password via Supabase Auth) styled with the Module 1 theme, as the new app entry point ahead of the Module 4 shell. Create the `AppUser` model properly backed by Supabase Auth + a `app_users` table (from the Module 3 schema) storing `authUserId`, `employeeId` nullable (linking to Module 24's Employee records for staff who need login access), `role` (`admin`/`salesman`), `displayName`. Replace the `currentUserProvider` from Global Conventions with a real implementation backed by the Supabase Auth session (with local Isar caching of the current session/role so the app remains usable offline after initial login — auth state shouldn't require connectivity on every launch). Build a "Create User" screen (admin-only) under the Users nav item, letting an admin create login credentials for a salesman, optionally linked to an existing Employee record. Tighten the Module 3 RLS policies now that real auth and roles exist — replace the permissive development policies with proper role-based policies (admins full access, salesmen restricted server-side too, not just client-side, as defense in depth alongside Module 32's client-side restriction). Confirm every module built from 4 through 32 continues working identically, now driven by a real session instead of the mock.

**Edge Cases:**
- App must remain usable offline immediately after a successful login even if connectivity drops right after (cache the session/role locally, don't require a live Supabase check on every screen)
- Session expiry while the app is open mid-shift must be handled gracefully (silent refresh where possible, graceful re-login prompt without losing in-progress POS cart state if avoidable)
- A salesman-role login attempting any restricted action must be blocked both client-side (Module 32) and server-side (RLS) — verify both layers independently, don't trust client-side alone

**Testing Checklist:**
- Log in as admin, confirm full access matches the previous mock-admin behavior exactly
- Create a salesman user, log in as them, confirm restricted nav/route behavior from Module 32 still holds with a real session
- Go offline immediately after login, confirm the app remains fully usable
- Attempt a restricted Supabase query directly (e.g., via REST with the salesman's token) to confirm RLS blocks it server-side, not just the Flutter UI

**Definition of Done:** real authentication is fully wired, role enforcement is solid at both client and server layers, and zero regressions exist in any earlier module's behavior.

---

## Module 34 — Final Polish, Edge Case Pass & Full Regression Test

**Goal:** A dedicated module to close gaps that only become visible once the whole system exists together.

**Cursor Prompt:**
> Perform a full-system pass: (1) Consistency audit — every screen uses the Module 1 theme correctly with no stray hardcoded colors/spacing introduced in later modules under time pressure; every loading state uses `AppLoadingIndicator`, every empty state uses `AppEmptyState`, every error uses `AppSnackbar`. (2) Sync robustness re-test — deliberately simulate poor connectivity (airplane-mode toggling mid-operation) across POS, Orders, Attendance, and Settings, confirming no data loss anywhere. (3) Performance pass — test with a realistic data volume (e.g., simulate 90 days of orders, hundreds of products/employees) and confirm lists/reports/dashboard remain responsive; add pagination or lazy-loading anywhere that struggles. (4) Full workflow regression — walk through, in order: create categories/products/deals/tables → place a dine-in order with variants/modifiers/discounts → progress it through KDS and full lifecycle → mark paid, print receipt → check an employee in/out, generate and finalize a salary slip → review Sales and every Reports view for that activity → confirm sync reflects everything correctly on a second device/profile. (5) Fix every gap found during this pass.

**Edge Cases:** by definition, this module exists to surface and close whatever edge cases weren't caught earlier — treat the testing checklist below as a starting point, not exhaustive.

**Testing Checklist:**
- Full regression workflow from step 4 above, executed start to finish without a single crash or data inconsistency
- Theme/consistency audit shows zero stray hardcoded values
- Performance remains acceptable under realistic simulated data volume
- Two-device sync test shows fully consistent final state on both

**Definition of Done:** the system is production-ready — every module works individually and as a coherent whole, offline-first behavior is bulletproof, and the UI is visually consistent throughout.

---

## Notes on Using This Document

- Test each module fully against its own checklist before starting the next — many later modules (Sales, Reports, Sync) assume earlier data models are exactly as specified, and retrofitting fields after the fact (e.g., per-status timestamps in Module 23) is called out explicitly where it's likely to bite you.
- The mock-auth approach means you get a fully working, fully testable admin application by Module 32, with role restriction and real login layered on at the very end with minimal risk to everything already built and tested.
- Module 31 (Sync Engine) is the highest-risk module in the whole build — budget extra testing time there specifically.
