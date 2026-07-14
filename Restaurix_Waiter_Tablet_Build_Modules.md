# Restaurix Waiter — Tablet & Mobile Order App (Cursor Build Document)

This document defines a **complete, production-ready Flutter app** for **waiters / floor staff** to take and manage orders on **Android & iOS tablets and phones**. It connects to the **same Supabase backend** as the existing Restaurix desktop app (`restaurix/`).

**Role mapping:** Waiters use the existing `salesman` role in `app_users`. Permissions match Module 32 of the desktop build (operational access only — no admin, reports, payroll, or catalog editing).

---

## 0. Read This First

### Relationship to the desktop app

| Area | Desktop (`restaurix/`) | Waiter app (`restaurix_waiter/` recommended) |
|------|------------------------|-----------------------------------------------|
| Backend | Supabase Postgres + Auth | **Same project, same tables, same RLS** |
| Local DB | Isar offline-first | Isar offline-first (same schema subset) |
| Auth role | `admin` or `salesman` | **`salesman` only** (waiter accounts) |
| Catalog | Full CRUD | **Read-only** (sync down from server) |
| POS / Orders | Full | **Full waiter subset** |
| Kitchen | Full KDS + reprint | **Read-only kitchen status** |
| Printing | Windows printers | **Out of scope v1** (kitchen/receipt handled by desktop/KDS) |

### Recommended repo layout

```
Restaurix/
  restaurix/                  # existing Windows desktop app
  restaurix_waiter/           # NEW — this document
  packages/
    restaurix_shared/         # OPTIONAL later — shared domain, sync, lifecycle
```

**v1 strategy:** New Flutter project `restaurix_waiter`. Copy or extract shared code from desktop (`domain/models`, `order_lifecycle.dart`, sync engine patterns) rather than reimplementing business rules. Keep waiter UI mobile-first.

### Global conventions (every module)

**Stack**
- Flutter **mobile-first** (Android + iOS). Responsive layouts for **phone (320–599dp)** and **tablet (600dp+)**.
- State: **Riverpod** — `Notifier` / `AsyncNotifier` for business state; `StatefulWidget` only for ephemeral UI (tabs, sheets, animations).
- Local DB: **Isar** (offline-first source of truth on device).
- Backend: **Supabase** (Auth, Postgres, optional Realtime later).
- Architecture: `UI → Riverpod → Repository → Isar → Sync Queue → Supabase`

**Folder structure**
```
lib/
  core/              # theme, config, sync, utils, auth cache
  data/
    local/           # isar collections (waiter subset)
    remote/          # supabase client
    repositories/
  domain/
    models/
    services/        # order_lifecycle, cart, discounts, etc.
  features/
    <feature>/
      presentation/
      providers/
  app/               # router, shell, breakpoints
```

**Standard sync fields** (every syncable Isar collection + Supabase row):
- `id` (UUID string, client-generated)
- `createdAt`, `updatedAt`
- `isSynced` (bool, default false on local write)
- `deletedAt` (soft delete only)
- `syncAction` (create / update / delete)
- `deviceId`, `version`

**Waiter role rules** (must match desktop `OrderLifecycle` + RLS):
- Can: place orders, edit unpaid orders, apply discounts, hold/resume, advance status through **Ready** only, view tables, view kitchen status, save drafts.
- Cannot: cancel orders, mark paid, complete orders, manage catalog, access reports/payroll/settings/users, reprint kitchen tickets.

**Definition of Done (every module):** compiles cleanly, `flutter analyze` zero issues, works **fully offline** after initial login + sync, data survives app restart, module checklist passes on **one phone + one tablet** form factor.

---

## 1. Supabase Configuration (required before Module 4)

Use the **same Supabase project** as the desktop app. Do not create a separate database.

### 1.1 Apply migrations

From the desktop repo (`restaurix/supabase/migrations/`):

1. `20240621000000_initial_schema.sql` — all tables
2. `20240622000000_auth_rls.sql` — role-based RLS (`admin` / `salesman`)

```bash
cd restaurix
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Or paste each file in **Supabase Dashboard → SQL Editor**.

### 1.2 Auth settings (Dashboard)

**Authentication → Providers → Email**
- Enable Email provider
- For development: disable **Confirm email** so new waiters can sign in immediately
- For production: enable confirm email or use invite flow

**Authentication → URL configuration**
- Add your app’s deep-link scheme if using magic links (optional v1)

### 1.3 Environment variables (Flutter)

Create `restaurix_waiter/.env` (gitignored):

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Get values from **Project Settings → API**:
- **Project URL** → `SUPABASE_URL`
- **anon public** key → `SUPABASE_ANON_KEY` (safe in client apps; RLS enforces access)

**Mobile bundling:** Add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

Load in `main.dart` via `flutter_dotenv` (same pattern as desktop `EnvConfig`).

Never commit `.env`. Commit `.env.example` with placeholders only.

### 1.4 Waiter user provisioning

Every waiter needs **two records**:

1. **Supabase Auth user** (email + password)
2. **`app_users` row** linked by `auth_user_id`

**First admin** (bootstrap once in SQL Editor):

```sql
-- After creating Auth user in Dashboard → Authentication → Users
INSERT INTO app_users (
  id, auth_user_id, role, display_name, created_at, updated_at
) VALUES (
  gen_random_uuid(),
  'PASTE-AUTH-USER-UUID',
  'admin',
  'Admin',
  NOW(), NOW()
);
```

**Waiter accounts** — create from desktop app **Users** screen (admin), or manually:

```sql
INSERT INTO app_users (
  id, auth_user_id, role, display_name, employee_id, created_at, updated_at
) VALUES (
  gen_random_uuid(),
  'WAITER-AUTH-UUID',
  'salesman',
  'Waiter Name',
  NULL,  -- optional: UUID from employees table
  NOW(), NOW()
);
```

Waiter app logins **must** use `role = 'salesman'`. Reject or sign out users with `admin` role (they should use desktop).

### 1.5 RLS summary (already in migration)

| Table group | Waiter (`salesman`) |
|-------------|---------------------|
| categories, products, variants, modifiers, deals, deal_items | SELECT |
| halls, restaurant_tables, discounts, riders, pickup_companies | SELECT |
| orders, order_items, order_item_modifiers | SELECT, INSERT, UPDATE |
| restaurant_tables | SELECT, UPDATE (occupancy) |
| employees, salary_slips, attendance_records | **No access** |
| app_users | SELECT own row only |

Client-side route guards are **not** sufficient — RLS is defense in depth.

### 1.6 Verify connectivity

After configuring `.env`, app startup should:
1. Initialize Supabase
2. Log `Supabase ping: success` (non-blocking)
3. Show login if no cached session

### 1.7 Optional: Realtime (Module 19+)

Subscribe to `orders` / `order_items` changes for multi-device freshness. Not required for v1 if sync engine polls on interval.

---

## 2. Responsive Layout Rules (all UI modules)

Define breakpoints in `core/layout/app_breakpoints.dart`:

| Name | Width | Layout |
|------|-------|--------|
| `compact` | &lt; 600 | Single column; bottom navigation; full-screen cart sheet |
| `medium` | 600–899 | Two-column POS optional; side nav or rail |
| `expanded` | ≥ 900 | Persistent catalog + cart split; side navigation rail |

**Touch targets:** minimum 48×48 logical pixels for all tappable controls.

**Orientation:** Support portrait and landscape on tablets; phone POS usable in portrait with cart as bottom sheet.

**Safe areas:** Respect notches and system bars on iOS/Android.

---

## 3. Waiter App Navigation Map

| Route | Phone | Tablet | Purpose |
|-------|-------|--------|---------|
| `/login` | ✓ | ✓ | Email/password auth |
| `/home` | ✓ | ✓ | Operational dashboard |
| `/pos` | ✓ | ✓ | New order (catalog + cart) |
| `/pos/checkout` | ✓ | ✓ | Review, discounts, place order |
| `/orders` | ✓ | ✓ | Active & recent orders |
| `/orders/:id` | ✓ | ✓ | Detail, advance, edit, hold |
| `/tables` | ✓ | ✓ | Floor plan / table list |
| `/kitchen` | ✓ | ✓ | Read-only kitchen board |
| `/drafts` | ✓ | ✓ | Saved in-progress carts |
| `/sync` | ✓ | ✓ | Sync status, manual sync |
| `/profile` | ✓ | ✓ | User info, sign out |

**Blocked routes** (redirect to `/home`): products admin, settings, reports, employees, salary, users, analytics.

---

## 4. Module Table

| # | Module |
|---|--------|
| W0 | Project Foundation & Mobile Targets |
| W1 | Design System (Touch-First, Responsive) |
| W2 | Local Database (Isar — Waiter Subset) |
| W3 | Supabase Client & Env Config |
| W4 | Authentication & Session Cache |
| W5 | Sync Queue Infrastructure |
| W6 | Sync Engine (Bidirectional) |
| W7 | App Shell, Navigation & Role Guards |
| W8 | Catalog Sync (Categories, Products, Variants) |
| W9 | Modifiers & Deals Sync (Read-Only) |
| W10 | Tables & Halls (View + Occupy/Release) |
| W11 | Delivery Options (Riders & Pickup Companies — Read) |
| W12 | POS — Catalog Browser & Cart |
| W13 | POS — Modifiers, Variants & Deals in Cart |
| W14 | POS — Order Type, Table & Delivery Selection |
| W15 | POS — Discounts |
| W16 | Checkout & Order Placement |
| W17 | Orders List & Detail (Waiter Lifecycle) |
| W18 | Draft Orders |
| W19 | Hold & Resume Orders |
| W20 | Kitchen Status (Read-Only Board) |
| W21 | Operational Dashboard |
| W22 | Sync Status UI & Connectivity |
| W23 | Final Polish & Full Regression |

---

## Module W0 — Project Foundation & Mobile Targets

**Goal:** Scaffold `restaurix_waiter` Flutter project for Android + iOS.

**Cursor Prompt:**
> Create a new Flutter project `restaurix_waiter` targeting **Android and iOS** (phones and tablets). Add dependencies: `flutter_riverpod`, `isar`, `isar_flutter_libs`, `path_provider`, `supabase_flutter`, `uuid`, `intl`, `go_router`, `flutter_dotenv`, `connectivity_plus`, `freezed` + `freezed_annotation` + `build_runner`. Use the folder structure from Section 0. Add `EnvConfig` loading `.env` from assets. Initialize Isar and Supabase in `main.dart` (non-blocking if offline). Show a placeholder `MaterialApp` with text "Restaurix Waiter". Configure `android/app/build.gradle` minSdk 21+, iOS deployment target 13+. Confirm `flutter run` works on at least one Android emulator.

**Testing Checklist:**
- Android build succeeds
- iOS build succeeds (if on Mac)
- `flutter analyze` clean

---

## Module W1 — Design System (Touch-First, Responsive)

**Goal:** Mobile-optimized theme and components; reuse visual language from desktop where sensible.

**Cursor Prompt:**
> Build `core/theme/` (colors, typography, spacing, radius, icons, `ThemeData` Material 3). Build touch-first widgets in `core/widgets/`: `AppButton`, `AppIconButton`, `AppCard`, `AppChip`, `AppTextField`, `AppBottomSheet`, `AppSnackbar`, `AppLoadingIndicator`, `AppEmptyState`, `AppDialog` (single-pop-safe: no double Navigator.pop). Add `core/layout/responsive_scaffold.dart` with breakpoint-aware shell helpers. Minimum tap target 48dp. Add `/theme-preview` debug route.

**Edge Cases:**
- Long product names truncate gracefully in cart tiles
- Bottom sheets scroll when keyboard opens

---

## Module W2 — Local Database (Isar — Waiter Subset)

**Goal:** Isar collections required for waiter operations only.

**Cursor Prompt:**
> Implement Isar in `data/local/`. Collections (with standard sync fields): `CategoryIsar`, `ProductIsar`, `ProductVariantIsar`, `ModifierGroupIsar`, `ItemModifierIsar`, `DealIsar`, `DealItemIsar`, `HallIsar`, `RestaurantTableIsar`, `RiderIsar`, `PickupCompanyIsar`, `OrderIsar`, `OrderItemIsar`, `DraftOrderIsar`, `AppSettingIsar` (auth cache, sync cursors). **Exclude** employee, attendance, salary collections. Copy collection patterns from desktop `restaurix/lib/data/local/collections/`. Expose `isarProvider`, `deviceIdProvider`. Stable `deviceId` per install.

**Testing Checklist:**
- Isar opens on Android/iOS
- Write/read smoke test persists across restart

---

## Module W3 — Supabase Client & Env Config

**Goal:** Connect to shared backend; document-ready config.

**Cursor Prompt:**
> Implement `SupabaseService` mirroring desktop: initialize from `EnvConfig`, expose `supabaseClientProvider`, non-blocking startup ping against `categories` table. If `.env` missing, app runs offline-only with login disabled and clear banner. Add `.env.example`. Document in code comments that waiters use the **same** Supabase project as desktop.

**Testing Checklist:**
- Ping succeeds when online
- App does not crash when offline at startup

---

## Module W4 — Authentication & Session Cache

**Goal:** Real auth on day one; offline session after login.

**Cursor Prompt:**
> Build login screen (email/password). `AuthRepository`: signIn, signOut, fetch `app_users` profile by `auth_user_id`, cache session JSON in `AppSettingIsar`. Reject login if `app_users.role != 'salesman'`. `AuthController` + `currentUserProvider`. Router: unauthenticated → `/login`; authenticated → `/home`. Handle session expiry with re-login prompt (preserve in-memory cart if possible). Copy patterns from desktop `lib/features/auth/`.

**Edge Cases:**
- Auth user exists but no `app_users` row → clear error message
- Admin credentials on waiter app → "Use the desktop app" message

**Testing Checklist:**
- Waiter login works with provisioned account
- Offline use after login (cached session)
- Sign out returns to login

---

## Module W5 — Sync Queue Infrastructure

**Goal:** Track pending local changes across waiter-relevant entities.

**Cursor Prompt:**
> Port `SyncQueueService` from desktop for waiter Isar collections only. Riverpod: `syncQueueSnapshotProvider`, `pendingSyncCountProvider`. Badge in app shell when pending &gt; 0. Audit all waiter repositories: every write sets `isSynced = false` and bumps `version`.

**Testing Checklist:**
- Place order offline → pending count increases
- Soft-deleted records appear in queue with delete action

---

## Module W6 — Sync Engine (Bidirectional)

**Goal:** Same sync semantics as desktop Module 31, waiter entity subset.

**Cursor Prompt:**
> Port sync engine from desktop: upload pending, download by cursor, conflict resolution (higher `version`, then `updatedAt`; local delete wins), conflict log in settings. `SyncCoordinator`: connectivity watch + 3-minute timer + sync on app resume. Waiter devices sync **catalog down**, **orders/tables up/down**. Exclude salary/attendance handlers. Do not sync `draftOrder` to Supabase (local-only, same as desktop).

**Edge Cases:**
- Interrupt mid-sync → resume without corruption
- First launch: large catalog download shows progress

**Testing Checklist:**
- Order placed on waiter appears on desktop after sync
- Product edit on desktop appears on waiter after sync

---

## Module W7 — App Shell, Navigation & Role Guards

**Goal:** Responsive shell with waiter-only routes.

**Cursor Prompt:**
> Build `go_router` with routes from Section 3. `RoleRouteAccess` for salesman-only paths. Phone: `NavigationBar` (Home, Orders, POS, Tables, More). Tablet: `NavigationRail` + optional wide POS split. Top bar: user chip, pending sync badge, sync icon. Block admin routes. Deep links to blocked routes redirect to `/home`.

**Testing Checklist:**
- Phone and tablet layouts both usable
- Manual navigation to `/settings` redirects

---

## Module W8 — Catalog Sync (Categories, Products, Variants)

**Goal:** Read-only catalog available offline for POS.

**Cursor Prompt:**
> Repositories: `watchCategories()`, `watchProducts()`, `watchVariants()` from Isar streams. Sync handlers pull from Supabase; **no create/update/delete UI** for waiters. Products screen for browsing only (optional debug). POS consumes active products only. Show unavailable products greyed out.

**Testing Checklist:**
- Catalog visible offline after one successful sync
- Inactive products hidden from POS

---

## Module W9 — Modifiers & Deals Sync (Read-Only)

**Goal:** Full modifier/deal rules for cart validation.

**Cursor Prompt:**
> Sync modifier groups, modifiers, deals, deal items. Port `ModifierSelectionValidator` and deal availability logic from desktop. Deals appear in POS catalog tab. Required modifier groups enforced before add-to-cart.

**Testing Checklist:**
- Required modifier blocks add until satisfied
- Deal time windows respected

---

## Module W10 — Tables & Halls (View + Occupy/Release)

**Goal:** Dine-in table selection and occupancy sync.

**Cursor Prompt:**
> Tables screen: list or grid by hall; show free/occupied/held states. Select table in POS for dine-in. Occupy on order placement; release on order completed/cancelled (via order lifecycle). Sync table status. Touch-friendly table cards on tablet; searchable list on phone.

**Testing Checklist:**
- Select table in POS → reflected on tables screen
- Complete order → table freed

---

## Module W11 — Delivery Options (Riders & Pickup Companies — Read)

**Goal:** Delivery order type can select rider or pickup company.

**Cursor Prompt:**
> Sync riders and pickup companies (read-only). POS delivery section: require rider **or** pickup company before checkout (same validation as desktop `CheckoutValidation`). No admin CRUD screens.

**Testing Checklist:**
- Delivery checkout blocked without rider/company
- Passes when one is selected

---

## Module W12 — POS — Catalog Browser & Cart

**Goal:** Core ordering UX optimized for touch.

**Cursor Prompt:**
> `/pos` screen: category tabs/chips, product grid (responsive column count: 2 phone, 3–4 tablet). Cart panel: phone = draggable bottom sheet; tablet = persistent side panel (40/60 split). `CartNotifier` with merge-by-configuration logic from desktop. Line qty +/- buttons. Running subtotal. Empty cart state. Link to `/drafts`.

**Edge Cases:**
- Large cart scrolls without losing category context
- Rotation preserves cart state

**Testing Checklist:**
- Add/remove/qty change updates totals
- Tablet split and phone sheet both work

---

## Module W13 — POS — Modifiers, Variants & Deals in Cart

**Goal:** Configure items before adding to cart.

**Cursor Prompt:**
> Product tap → bottom sheet: variant picker (if any), modifier groups (required/optional, max selections), notes field optional. Deal builder flow from desktop. Re-edit line from cart. Show configuration summary on cart lines.

**Testing Checklist:**
- Same product, different modifiers = separate lines
- Edit line reopens configuration sheet

---

## Module W14 — POS — Order Type, Table & Delivery Selection

**Goal:** Dine-in / takeaway / delivery with validations.

**Cursor Prompt:**
> Order type chips: Dine In, Take Away, Delivery. Dine-in → table picker (Module W10). Delivery → rider/company (Module W11). Takeaway → no table. Persist in cart/checkout state. Switching type clears invalid selections with confirmation.

**Testing Checklist:**
- Dine-in without table blocked at checkout
- Switch dine-in → takeaway clears table

---

## Module W15 — POS — Discounts

**Goal:** Apply item/category/order discounts at POS (same rules as desktop).

**Cursor Prompt:**
> Port discount models and `DiscountCalculator` from desktop. Waiter can apply configured discounts (synced read-only from `discounts` table). Show discount breakdown in cart and checkout. Stack order: item → category → whole order.

**Testing Checklist:**
- Discounts persist on placed order
- Totals match desktop for same cart

---

## Module W16 — Checkout & Order Placement

**Goal:** Review and submit order to kitchen.

**Cursor Prompt:**
> `/pos/checkout`: order summary, type/table/delivery recap, payment type selection (cash, card, online, **on credit**), notes, place order button. `OrderRepository.placeOrder()` generates order number as **`ODR-0001`** (4-digit daily sequence starting at 1 each local day — not `ORDM-*`), sets kitchen status, marks table occupied, triggers sync. Success → confirmation screen with order # ; option to view order or new order. **No** receipt printing on mobile v1.

### On-credit orders (regular customers on tab)

Some restaurants allow trusted regulars to order without paying upfront. Balance accumulates and is settled later from the desktop **Credit Customers** tab.

**Checkout rules when payment type = On Credit (`PaymentType.credit`):**
- Show **credit customer picker** (synced read-only list of active `credit_customers`).
- Required: `creditCustomerId` on `PlaceOrderInput`.
- Set `paymentType = credit`, `paymentStatus = unpaid`, `isPrepaid = false`.
- Persist `credit_customer_id` on the order row (Supabase + Isar).
- After placement, post an **order charge** via `CreditLedgerService.chargeForOrder()` (idempotent by `order_id`).
- Waiter **cannot** mark paid — settlement is admin-only on desktop.

**Sync entities to include in waiter Isar subset:**
- `credit_customers` (read + write balance updates from charges)
- `credit_transactions` (create charges locally)

**Desktop follow-up:** After sync, `CreditOrderChargeProcessor.processAfterSync()` posts charges for tablet orders that arrived remotely (same idempotency).

**Edge Cases:**
- Inactive credit customer → block placement
- Credit limit exceeded → show error before placing
- Cancelled order → desktop reverses charge via `CreditLedgerService.reverseOrderCharge()`

**Testing Checklist:**
- Credit order appears in `/orders` with payment type "On Credit"
- Customer balance increases on desktop after sync
- Cash/card order flow unchanged
- Double-tap place order is idempotent
- Offline place queues for sync
- Order appears in `/orders` and on desktop after sync
- Kitchen receives items (via desktop KDS)

---

## Module W17 — Orders List & Detail (Waiter Lifecycle)

**Goal:** Manage active orders within salesman permissions.

**Cursor Prompt:**
> `/orders`: filter tabs (Active, Ready, All Today). Cards with status, type, table, total, held badge. `/orders/:id`: items, totals, status actions from `OrderLifecycle` for `salesman` — advance through Ready, hold/resume, edit in POS if unpaid. **Hide** cancel, mark paid, complete. Show read-only message for paid orders. Edit → reopen POS with cart snapshot.

**Testing Checklist:**
- Waiter can advance to Ready only
- Paid order edit blocked with explanation
- Edit unpaid order recalculates totals

---

## Module W18 — Draft Orders

**Goal:** Save in-progress carts (local-only).

**Cursor Prompt:**
> Port draft order feature from desktop. Save draft with optional label. Drafts list at `/drafts`. Resume → POS. Discard releases table if held. Drafts do not sync to Supabase. Badge count on POS tab.

**Testing Checklist:**
- Save/resume preserves modifiers, type, table
- Discard releases table

---

## Module W19 — Hold & Resume Orders

**Goal:** Operational hold flag on active orders.

**Cursor Prompt:**
> Hold/resume from order detail (and optionally POS). Held badge in orders list and kitchen status. Held orders excluded from auto kitchen advance on desktop (already supported — ensure waiter UI sets `isHeld` correctly).

**Testing Checklist:**
- Hold visible on kitchen status screen
- Resume clears held state

---

## Module W20 — Kitchen Status (Read-Only Board)

**Goal:** Waiters see kitchen progress without admin tools.

**Cursor Prompt:**
> Port read-only `KitchenDisplayScreen` from desktop (`readOnly: true`): Incoming / Preparing / Ready columns, timers, held badge. **No** reprint button. Dark theme acceptable for floor visibility. Optional pull-to-refresh triggering sync.

**Testing Checklist:**
- Orders move columns as kitchen progresses
- No print/admin actions visible

---

## Module W21 — Operational Dashboard

**Goal:** At-a-glance floor metrics (no revenue for waiters).

**Cursor Prompt:**
> `/home` dashboard for salesman: Orders Today, Preparing, Ready, Served, Cancelled Today counts. **No** revenue, monthly sales, or employee metrics (match desktop salesman dashboard). Quick actions: New Order, View Orders, Tables, Kitchen.

**Testing Checklist:**
- Counts update after placing test orders
- No financial data shown

---

## Module W22 — Sync Status UI & Connectivity

**Goal:** Visibility and manual control of sync.

**Cursor Prompt:**
> `/sync` screen from desktop Module 31: last sync time, pending count, manual Sync Now, conflict log (read-only for waiters). Offline banner in shell when no network. Sync icon animates while syncing.

**Testing Checklist:**
- Manual sync completes and updates badge
- Offline banner appears in airplane mode

---

## Module W23 — Final Polish & Full Regression

**Goal:** Production-ready waiter app.

**Cursor Prompt:**
> Full pass: (1) Theme audit — no hardcoded colors. (2) Responsive pass on 5" phone and 10" tablet. (3) Offline regression: login → sync catalog → place order → advance status → sync to desktop. (4) Permission regression: every admin-only action blocked UI + RLS. (5) Performance: 500+ products scroll smoothly. (6) App store readiness: app icon, splash, permissions (internet, network state).

**Testing Checklist:**
- End-to-end waiter shift simulation without crashes
- Two devices + desktop stay consistent after sync
- `flutter analyze` clean; tests pass

---

## 5. Shared Business Logic — Copy from Desktop

When implementing, **port (do not rewrite)** these from `restaurix/lib/`:

| File / area | Purpose |
|-------------|---------|
| `domain/models/order*.dart`, `order_enums.dart` | Order domain |
| `domain/services/order_lifecycle.dart` | Status permissions |
| `domain/services/discount_calculator.dart` | Discount math |
| `domain/services/kitchen_*` | Kitchen display (read-only) |
| `features/pos/providers/cart_*.dart` | Cart state machine |
| `core/sync/*` | Sync engine, handlers (trim entities) |
| `core/config/env_config.dart` | Env loading |
| `features/auth/*` | Auth (change role check to salesman) |

---

## 6. Supabase Tables Used by Waiter App

**Read (sync down):** `categories`, `products`, `product_variants`, `modifier_groups`, `modifiers`, `deals`, `deal_items`, `halls`, `restaurant_tables`, `discounts`, `riders`, `pickup_companies`, `orders`, `order_items`, `order_item_modifiers`

**Write (sync up):** `orders`, `order_items`, `order_item_modifiers`, `restaurant_tables`

**Auth only:** `app_users` (read own profile)

**Not used:** `employees`, `attendance_records`, `salary_slips`

---

## 7. Suggested Cursor Workflow

1. Read this document and desktop `Restaurix_Cursor_Build_Modules.md` for domain depth.
2. Build modules **W0 → W23 in order**.
3. After each module, run checklist on **phone emulator + tablet emulator**.
4. Keep Supabase project shared; test against real desktop instance.
5. Commit message pattern: `feat(waiter-w12): POS catalog and cart`

---

## 8. Out of Scope (Waiter v1)

- Bluetooth/Wi‑Fi receipt or kitchen printing from phone
- Admin catalog editing
- Reports, analytics, payroll, attendance
- Biometric enrollment
- Customer-facing display
- Multi-location / multi-tenant (single restaurant per app config)

---

## 9. Quick Reference — First Run Checklist

- [ ] Supabase migrations applied (schema + RLS)
- [ ] `.env` configured in `restaurix_waiter`
- [ ] Admin user exists on desktop
- [ ] Waiter user created (`role = salesman` in `app_users`)
- [ ] Email confirm disabled for dev (optional)
- [ ] Desktop has categories/products synced
- [ ] Waiter app: login → sync → place test dine-in order → verify on desktop

---

*Document version: 1.0 — aligned with Restaurix desktop Modules 0–33 (June 2025).*
