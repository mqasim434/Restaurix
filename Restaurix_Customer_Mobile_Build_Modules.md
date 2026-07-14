# Restaurix Customer — Home Ordering Mobile App (Cursor Build Document)

This document defines a **production-ready Flutter mobile app** for **customers ordering food from home** (delivery & takeaway). It connects to the **same Supabase backend** as the existing Restaurix Windows desktop app (`restaurix/`) and waiter tablet app (`restaurix_waiter/` if built).

**Primary outcome:** When a customer places an order, it **automatically appears on the desktop Tablet Orders monitor**, triggers **dual auto-print** (kitchen slip + customer receipt), and shows a **live status** in the customer app — using the desktop features already implemented in `restaurix/`.

---

## 0. Read This First

### 0.1 Relationship to existing apps

| Area | Desktop (`restaurix/`) | Customer app (`restaurix_customer/`) |
|------|------------------------|----------------------------------------|
| Backend | Supabase Postgres + Auth | **Same project, same tables + new customer tables** |
| Local DB | Isar offline-first | **Online-first v1** (Supabase direct); optional Isar cart cache v2 |
| Auth | `app_users` → `admin` / `salesman` | **`customer_profiles`** → Supabase Auth (email/password) |
| Catalog | Full CRUD | **Read-only** (active products, deals, modifiers) |
| Orders | Monitor + auto-print | **Create only** (own orders); track status |
| Printing | Windows ESC/POS auto-print | **None** (desktop prints on arrival) |
| Payments | Cash/card at counter | **Cash on delivery / pickup** v1; online gateway v2 |

### 0.2 Desktop integration (already built — do not reimplement)

The desktop app (`restaurix/`) in **monitor mode** (`DesktopFeatures.hidePosAndDashboard = true`) already:

1. Listens to **Supabase Realtime** on `orders` inserts (`order_realtime_listener.dart`)
2. Syncs new rows into local Isar (`sync_lifecycle.dart`)
3. Detects **remote orders** via `tablet_order_detection.dart`:
   - Order number prefix `ODR-*` (waiter tablet), **or**
   - Order number prefix `ODRM-*` (customer app), **or**
   - `device_id` different from desktop device id
4. Shows them on **Live Orders** screen with “Incoming” highlight
5. **Auto-prints** kitchen + customer receipts (`tablet_order_auto_print_service.dart`)

**Customer app must trigger the same pipeline** by:

- Using order prefix **`ODRM-0001`** (daily sequence starting at 1), **and**
- Setting `device_id` to the customer app’s stable device UUID (never the desktop id)
- Inserting into the same `orders` / `order_items` / `order_item_modifiers` tables
- Ensuring Realtime migration `20240623000000_realtime_orders.sql` is applied

Legacy prefixes `ORDM-*` / `ORDC-*` are still recognized by desktop for old rows.

### 0.3 Recommended repo layout

```
Restaurix/
  restaurix/                  # Windows desktop (monitor + print hub)
  restaurix_waiter/           # Waiter tablet (optional, ODR-* orders)
  restaurix_customer/         # NEW — this document
```

**v1 strategy:** New Flutter project `restaurix_customer`. Port **domain models** and **pricing/discount math** from desktop where needed; do **not** duplicate admin/staff features.

### 0.4 Product goals — advanced UI, easy to use

This is **not** a minimal ordering webview. Build a **premium consumer food app** feel:

| Principle | Implementation |
|-----------|----------------|
| **Fast browsing** | Category chips, sticky search, skeleton loaders, cached images |
| **Delight** | Hero product images, subtle page transitions, haptic on add-to-cart |
| **Clarity** | One primary action per screen; large tap targets (min 48dp) |
| **Trust** | Order timeline, ETA, restaurant branding, clear pricing breakdown |
| **Accessibility** | Semantic labels, contrast ≥ 4.5:1, dynamic type support |
| **Responsive** | Phone-first; graceful tablet layouts (2-column menu grid) |

**Design system (mandatory):**

- Material 3 with **custom `ThemeExtension`** for brand colors
- Typography: **Display** (restaurant name), **Title** (sections), **Body** (menu), **Label** (prices)
- Spacing scale: 4 / 8 / 12 / 16 / 24 / 32
- Radius: cards 16, buttons 12, bottom sheet 24 top
- Motion: 200–300ms ease; staggered list entrance on menu load
- Empty states: illustrated + single CTA
- Error states: friendly copy + retry (network-aware)

### 0.5 Global technical conventions

**Stack**

- Flutter **Android + iOS** (phones primary; tablets supported)
- State: **Riverpod** (`AsyncNotifier` for data, `Notifier` for cart)
- Navigation: **go_router** with auth redirect guards
- Backend: **Supabase** (Auth, Postgres, Realtime)
- Images: `cached_network_image`
- Forms: inline validation + `flutter_form_builder` optional

**Folder structure**

```
lib/
  core/
    config/           # env, branding
    theme/            # M3 theme, extensions, typography
    network/          # supabase client wrapper
    widgets/          # shared UI primitives
  data/
    models/
    repositories/     # catalog, orders, profile, addresses
  domain/
    services/         # cart, pricing, order_placement, validation
  features/
    auth/
    home/
    menu/
    product/
    cart/
    checkout/
    orders/
    profile/
    addresses/
  app/
    router.dart
    app.dart
```

**Definition of Done (every module):** `flutter analyze` clean, runs on **Android emulator + one physical device**, auth flows work, orders appear on desktop within **≤30s** (Realtime + sync), checklist passes.

---

## 1. Supabase Configuration

### 1.1 Existing migrations (apply first)

From `restaurix/supabase/migrations/`:

| File | Purpose |
|------|---------|
| `20240621000000_initial_schema.sql` | All core tables |
| `20240622000000_auth_rls.sql` | Staff RLS (`admin` / `salesman`) |
| `20240623000000_realtime_orders.sql` | Realtime on `orders` + `order_items` |

```bash
cd restaurix
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

### 1.2 NEW migration — customer app tables & order fields

Create `restaurix/supabase/migrations/20240624000000_customer_app.sql` and apply:

```sql
-- =============================================================================
-- RESTAURANT PUBLIC CONFIG (branding for customer app — admin maintains)
-- =============================================================================
CREATE TABLE IF NOT EXISTS restaurant_public_config (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name           TEXT NOT NULL,
  business_address        TEXT,
  tagline                 TEXT,
  logo_url                TEXT,
  cover_image_url         TEXT,
  currency_code           TEXT NOT NULL DEFAULT 'PKR',
  minimum_order_amount    NUMERIC(12, 2) NOT NULL DEFAULT 0,
  delivery_fee            NUMERIC(12, 2) NOT NULL DEFAULT 0,
  estimated_prep_minutes  INTEGER NOT NULL DEFAULT 30,
  is_accepting_orders     BOOLEAN NOT NULL DEFAULT TRUE,
  opening_hours           JSONB NOT NULL DEFAULT '{}',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed one row if empty (desktop admin updates later)
INSERT INTO restaurant_public_config (business_name, tagline)
SELECT 'Restaurix', 'Order fresh food to your door'
WHERE NOT EXISTS (SELECT 1 FROM restaurant_public_config);

-- =============================================================================
-- CUSTOMER PROFILES (linked to Supabase Auth — NOT app_users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_profiles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID NOT NULL UNIQUE REFERENCES auth.users (id) ON DELETE CASCADE,
  full_name       TEXT NOT NULL,
  phone           TEXT,
  email           TEXT NOT NULL,
  avatar_url      TEXT,
  marketing_opt_in BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customer_profiles_auth_user_id
  ON customer_profiles (auth_user_id);

-- =============================================================================
-- CUSTOMER ADDRESSES (delivery)
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_addresses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID NOT NULL REFERENCES customer_profiles (id) ON DELETE CASCADE,
  label           TEXT NOT NULL DEFAULT 'Home',
  line1           TEXT NOT NULL,
  line2           TEXT,
  city            TEXT NOT NULL,
  postcode        TEXT,
  notes           TEXT,
  is_default      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customer_addresses_customer_id
  ON customer_addresses (customer_id);

-- =============================================================================
-- ORDERS — customer delivery fields
-- =============================================================================
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customer_profiles (id);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_name TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line1 TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address_line2 TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_city TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_postcode TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_notes TEXT;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_source TEXT NOT NULL DEFAULT 'desktop';

COMMENT ON COLUMN orders.order_source IS 'desktop | waiter_tablet | customer_app';

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_source ON orders (order_source);

-- =============================================================================
-- RLS — customer role helpers
-- =============================================================================
CREATE OR REPLACE FUNCTION public.current_customer_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id
  FROM customer_profiles
  WHERE auth_user_id = auth.uid()
    AND deleted_at IS NULL
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_customer()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT current_customer_id() IS NOT NULL;
$$;

-- Enable RLS on new tables
ALTER TABLE restaurant_public_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

-- Public branding: anyone authenticated can read
CREATE POLICY public_config_read ON restaurant_public_config
  FOR SELECT TO authenticated, anon
  USING (true);

CREATE POLICY public_config_admin_write ON restaurant_public_config
  FOR ALL TO authenticated
  USING (is_app_admin())
  WITH CHECK (is_app_admin());

-- Customer profile: own row only
CREATE POLICY customer_profile_select_own ON customer_profiles
  FOR SELECT TO authenticated
  USING (auth_user_id = auth.uid());

CREATE POLICY customer_profile_insert_own ON customer_profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth_user_id = auth.uid());

CREATE POLICY customer_profile_update_own ON customer_profiles
  FOR UPDATE TO authenticated
  USING (auth_user_id = auth.uid())
  WITH CHECK (auth_user_id = auth.uid());

-- Addresses: own rows only
CREATE POLICY customer_addresses_own ON customer_addresses
  FOR ALL TO authenticated
  USING (customer_id = current_customer_id())
  WITH CHECK (customer_id = current_customer_id());

-- =============================================================================
-- RLS — catalog read for customers (active only)
-- =============================================================================
CREATE POLICY customer_read_categories ON categories
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_active = TRUE);

CREATE POLICY customer_read_products ON products
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_available = TRUE);

CREATE POLICY customer_read_variants ON product_variants
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_modifier_groups ON modifier_groups
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_modifiers ON modifiers
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

CREATE POLICY customer_read_deals ON deals
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL AND is_available = TRUE);

CREATE POLICY customer_read_deal_items ON deal_items
  FOR SELECT TO authenticated
  USING (is_customer() AND deleted_at IS NULL);

-- =============================================================================
-- RLS — orders: customers create & read own orders only
-- =============================================================================
CREATE POLICY customer_insert_orders ON orders
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND customer_id = current_customer_id()
    AND order_source = 'customer_app'
  );

CREATE POLICY customer_select_own_orders ON orders
  FOR SELECT TO authenticated
  USING (is_customer() AND customer_id = current_customer_id());

CREATE POLICY customer_insert_order_items ON order_items
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_select_own_order_items ON order_items
  FOR SELECT TO authenticated
  USING (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM orders o
      WHERE o.id = order_items.order_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_insert_order_item_modifiers ON order_item_modifiers
  FOR INSERT TO authenticated
  WITH CHECK (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE oi.id = order_item_modifiers.order_item_id
        AND o.customer_id = current_customer_id()
    )
  );

CREATE POLICY customer_select_own_order_item_modifiers ON order_item_modifiers
  FOR SELECT TO authenticated
  USING (
    is_customer()
    AND EXISTS (
      SELECT 1 FROM order_items oi
      JOIN orders o ON o.id = oi.order_id
      WHERE oi.id = order_item_modifiers.order_item_id
        AND o.customer_id = current_customer_id()
    )
  );

-- Customers may read order status updates (desktop changes status field)
CREATE POLICY customer_update_own_orders_readonly_status ON orders
  FOR SELECT TO authenticated
  USING (is_customer() AND customer_id = current_customer_id());

-- Realtime: customers subscribe to own orders (Supabase filters in app)
ALTER TABLE orders REPLICA IDENTITY FULL;
```

### 1.3 Auth settings (Supabase Dashboard)

**Authentication → Providers → Email**

- Enable Email provider
- **Confirm email:** ON for production; OFF for dev only
- Minimum password length: 8

**Authentication → Policies**

- Customers use **standard Supabase Auth** (`signUp` / `signInWithPassword`)
- They do **not** get rows in `app_users` (staff only)

**Optional v2:** Phone OTP provider for Pakistan/international numbers.

### 1.4 Environment variables

Create `restaurix_customer/.env` (gitignored):

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=your-publishable-or-anon-key
```

Bundle for mobile:

```yaml
flutter:
  assets:
    - .env
```

Load via `flutter_dotenv` at startup (same pattern as desktop `EnvConfig`).

**Never** commit real keys. Ship `.env.example` with placeholders.

### 1.5 Order number convention (critical for desktop)

| Source | Prefix | Example | Reset |
|--------|--------|---------|-------|
| Desktop POS | `ORD-` | `ORD-20260630-001` | Daily (date in number) |
| Waiter tablet | `ODR-` | `ODR-0001` | Daily from 1 |
| **Customer app** | **`ODRM-`** | **`ODRM-0001`** | Daily from 1 |

Allocate on device before insert (count today’s `ODRM-*` rows by `created_at`):

```dart
const customerOrderNumberPrefix = 'ODRM';

Future<String> allocateCustomerOrderNumber(SupabaseClient client) async {
  final dayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final dayEnd = dayStart.add(const Duration(days: 1));
  final rows = await client
      .from('orders')
      .select('order_number')
      .like('order_number', '$customerOrderNumberPrefix-%')
      .gte('created_at', dayStart.toUtc().toIso8601String())
      .lt('created_at', dayEnd.toUtc().toIso8601String());
  var maxSeq = 0;
  for (final row in rows) {
    final parts = (row['order_number'] as String).split('-');
    if (parts.length == 2) {
      final seq = int.tryParse(parts[1]) ?? 0;
      if (seq > maxSeq) maxSeq = seq;
    }
  }
  return '$customerOrderNumberPrefix-${(maxSeq + 1).toString().padLeft(4, '0')}';
}
```

---

## 2. Existing Database Schema Reference (core tables)

All tables include standard sync columns: `created_at`, `updated_at`, `is_synced`, `deleted_at`, `sync_action`, `device_id`, `version`.

### 2.1 Catalog

**`categories`:** `id`, `name`, `image_url`, `sort_order`, `is_active`

**`products`:** `id`, `name`, `category_id`, `base_price`, `description`, `image_url`, `is_available`, `kitchen_category`, `modifier_group_ids` (UUID[])

**`product_variants`:** `id`, `product_id`, `name`, `price`, `sort_order`, `is_default`

**`modifier_groups`:** `id`, `name`, `selection_type` (`single` | `multiple`), `is_required`, `min_selections`, `max_selections`

**`modifiers`:** `id`, `group_id`, `name`, `price_delta`, `sort_order`

**`deals`:** `id`, `name`, `description`, `image_url`, `price`, `is_available`, `availability_start`, `availability_end`

**`deal_items`:** `id`, `deal_id`, `product_id`, `variant_id`, `quantity`, `allow_modifiers`

### 2.2 Orders (shared with desktop)

**`orders`**

| Column | Customer app usage |
|--------|-------------------|
| `order_number` | `ODRM-*` |
| `order_type` | `takeaway` or `delivery` only |
| `table_id` | `NULL` |
| `delivery_mode` | `NULL` on place (staff assigns rider on desktop) |
| `subtotal`, `item_discount_total`, `order_discount_total`, `total` | Computed client-side, persisted as-is |
| `payment_type` | `cash` (COD) or `online` (v2) |
| `payment_status` | `unpaid` for COD; `paid` when prepaid/online |
| `status` | `received` on place |
| `is_prepaid` | `true` for takeaway/delivery defaults |
| `created_by_user_id` | `customer_profiles.id` (string) |
| `notes` | Customer instructions |
| `device_id` | Customer app stable UUID |
| `order_source` | **`customer_app`** |
| `customer_id` | FK to profile |
| `customer_name`, `customer_phone` | Snapshot at checkout |
| `delivery_address_*` | Required for `delivery` |

**`order_items`:** `order_id`, `product_id`, `deal_id`, `name`, `variant_name`, `unit_price`, `quantity`, `line_total`, `kitchen_status` = `received`, `applied_discounts` JSON

**`order_item_modifiers`:** `order_item_id`, `modifier_id`, `name`, `price_delta`

### 2.3 Staff-only tables (customers must NOT access)

`app_users`, `employees`, `attendance_records`, `salary_slips`, `halls`, `restaurant_tables`, `pickup_companies`, `riders`, `discounts` (admin-managed; customer promos v2)

### 2.4 Enum wire values (must match desktop)

```dart
// order_type
'dine_in' | 'takeaway' | 'delivery'

// payment_type
'cash' | 'card' | 'online'

// payment_status
'unpaid' | 'paid' | 'refunded'

// status
'received' | 'preparing' | 'ready' | 'served' | 'paid' | 'completed' | 'cancelled'

// kitchen_status (order_items)
'received' | 'preparing' | 'ready' | 'served'
```

---

## 3. Desktop Integration — Module C0 (apply in `restaurix/`)

**Goal:** Customer `ODRM-*` orders trigger the same monitor + auto-print as tablet orders.

**Cursor prompt:**

> In `restaurix/`, extend remote order detection:
> 1. `lib/data/services/order_number_service.dart` — use `customerOrderNumberPrefix = 'ODRM'` / `tabletOrderNumberPrefix = 'ODR'` (legacy `ORDC`/`ORDM` still detected).
> 2. `lib/domain/services/tablet_order_detection.dart` — treat `ODRM-*` OR `ODR-*` OR foreign `device_id` as remote orders.
> 3. Update tests in `test/tablet_order_detection_test.dart` and `test/order_number_service_test.dart`.
> 4. Optional UI copy: Tablet Orders screen title → **Incoming Orders** (includes customer + waiter).
>
> No change to print logic — `tablet_order_auto_print_service.dart` already prints kitchen + customer receipt when `processAfterSync()` runs.

**Verify:**

- Place order from customer app → appears on desktop Tablet Orders within 30s
- Kitchen + customer slips auto-print once
- Order badge count increments in app shell

---

## 4. Customer App Modules

### Module C1 — Project Bootstrap & Theme

**Goal:** Premium visual foundation.

**Cursor prompt:**

> Create Flutter project `restaurix_customer` (Android minSdk 24, iOS 13+). Dependencies: `flutter_riverpod`, `go_router`, `supabase_flutter`, `flutter_dotenv`, `intl`, `uuid`, `cached_network_image`, `flutter_animate` (optional). Implement `AppTheme`: warm primary (food brand), surface containers, dark mode. `core/widgets/`: `PrimaryButton`, `GhostButton`, `PriceLabel`, `QuantityStepper`, `SkeletonBox`, `EmptyState`, `ErrorRetryPanel`. `main.dart`: load env, init Supabase, `ProviderScope`, `RestaurixCustomerApp`.

**Testing:** App launches to splash → routes to auth or home.

---

### Module C2 — Auth: Register, Login, Forgot Password

**Goal:** Full customer authentication.

**Screens:**

| Route | Purpose |
|-------|---------|
| `/welcome` | Brand hero, “Sign in” / “Create account” |
| `/register` | Full name, email, phone (optional), password, terms checkbox |
| `/login` | Email + password |
| `/forgot-password` | Email → Supabase `resetPasswordForEmail` |

**Register flow:**

1. `supabase.auth.signUp(email, password, data: { full_name, phone })`
2. Insert `customer_profiles` row (`auth_user_id`, `full_name`, `email`, `phone`)
3. If email confirm ON → show “Check your email” screen
4. Else → navigate to `/home`

**Login flow:**

1. `signInWithPassword`
2. Load `customer_profiles` by `auth_user_id`; if missing, create profile (recovery path)
3. Navigate to `/home`

**Router guards:**

- Unauthenticated → `/welcome`
- Authenticated → shell routes

**UX:**

- Password visibility toggle
- Inline field errors
- Loading overlay on submit (no double-submit)
- Biometric unlock v2 (optional)

**Testing:**

- Register → login → restart app → session persists
- Wrong password shows friendly error
- Customer cannot query `app_users` (RLS blocks)

---

### Module C3 — Public Config & Home

**Goal:** Branded home experience.

**Cursor prompt:**

> Fetch `restaurant_public_config` singleton on launch. Home screen (`/home`): parallax cover image, logo, business name, tagline, “Order now” CTA, horizontal **Deals** carousel, **Categories** grid (image + name), search bar → `/menu?query=`. Show closed banner when `is_accepting_orders = false`. Pull-to-refresh.

**Testing:** Config loads; closed state blocks checkout CTA.

---

### Module C4 — Menu Browse & Search

**Goal:** Fast menu discovery.

**Route:** `/menu`, `/menu/:categoryId`

**UX:**

- Sticky category chips (horizontal scroll)
- Product cards: image, name, from-price, “+” add (opens detail if has variants/modifiers)
- Search debounced 300ms (name + description)
- Skeleton grid while loading
- Tablet: 2-column grid

**Data:** Join products + categories; filter `is_available`; sort by category `sort_order`, product name.

---

### Module C5 — Product Detail Sheet

**Goal:** Configure item before add.

**Route:** `/product/:productId` (or modal bottom sheet from menu)

**UX:**

- Hero image header
- Variant chips (required if variants exist)
- Modifier groups: radio for `single`, checkboxes for `multiple` with min/max validation
- Live price update
- Notes field (optional, max 200 chars)
- Sticky bottom bar: qty stepper + “Add to cart — Rs X”

**Logic:** Port modifier validation from desktop POS (required groups block add).

---

### Module C6 — Cart

**Goal:** Review basket with delight.

**Route:** `/cart` (FAB or bottom nav badge with count)

**UX:**

- Swipe-to-remove with undo snackbar
- Line cards: thumb, name, config summary, qty stepper, line total
- Subtotal, delivery fee (if delivery), total
- “Proceed to checkout” disabled if below `minimum_order_amount`
- Empty cart illustration

**State:** `CartNotifier` — merge lines by product + variant + sorted modifier ids (same as desktop cart logic).

---

### Module C7 — Checkout & Place Order

**Goal:** Submit order to Supabase → desktop auto-print.

**Route:** `/checkout`

**Sections:**

1. **Order type:** Takeaway | Delivery (segmented control)
2. **Delivery address** (if delivery): picker from saved addresses + “Add new”
3. **Contact:** name + phone (pre-filled from profile)
4. **Payment:** Cash on delivery/pickup (v1); Online (disabled “Coming soon” badge v1)
5. **Notes:** optional
6. **Summary:** lines, fees, total, ETA (`estimated_prep_minutes`)

**Place order algorithm:**

```dart
Future<PlacedOrder> placeOrder(...) async {
  final orderId = const Uuid().v4();
  final orderNumber = await allocateCustomerOrderNumber(supabase);
  final deviceId = await DeviceIdService.getOrCreate();

  // 1. Insert orders row (order_source = customer_app, status = received)
  // 2. Insert order_items + order_item_modifiers
  // 3. Return order number for confirmation screen

  // Desktop picks up via Realtime → sync → auto-print (no extra API)
}
```

**Field rules:**

| Field | Takeaway | Delivery |
|-------|----------|----------|
| `order_type` | `takeaway` | `delivery` |
| `delivery_address_line1` | null | required |
| `delivery_city` | null | required |
| `payment_type` | `cash` | `cash` |
| `payment_status` | `unpaid` | `unpaid` |
| `is_prepaid` | `true` | `true` |

**UX:**

- Full-screen success animation with order number
- “Track order” + “Back to home” buttons
- Idempotent place (disable button after tap)

**Testing:**

- Order in Supabase with `ODRM-*`, `order_source = customer_app`
- Desktop Tablet Orders shows new row + prints two slips

---

### Module C8 — Order Tracking & History

**Goal:** Customer sees live status.

**Routes:** `/orders`, `/orders/:id`

**List:** Active + past orders (newest first), status chip, total, type icon.

**Detail:**

- Status timeline: Received → Preparing → Ready → Out for delivery / Ready for pickup → Completed
- Map order `status` from desktop lifecycle (read-only)
- **Realtime:** subscribe to `orders` UPDATE for `id = orderId` to refresh status
- Reorder button (copy items to cart) v1.5

**Testing:** Change status on desktop → customer app updates within seconds.

---

### Module C9 — Profile & Addresses

**Routes:** `/profile`, `/profile/edit`, `/addresses`, `/addresses/new`

**Profile:** edit name, phone, avatar (Supabase Storage optional v2), marketing toggle, sign out.

**Addresses:** CRUD `customer_addresses`; set default; used in checkout picker.

---

### Module C10 — Shell Navigation

**Bottom nav (4 tabs):**

| Tab | Route |
|-----|-------|
| Home | `/home` |
| Menu | `/menu` |
| Orders | `/orders` |
| Profile | `/profile` |

Cart accessible via floating cart bar when `cartCount > 0`.

---

## 5. Order Payload Example (Supabase insert)

```json
{
  "id": "uuid-v4",
  "order_number": "ODRM-0001",
  "order_type": "delivery",
  "order_source": "customer_app",
  "customer_id": "profile-uuid",
  "customer_name": "Ali Khan",
  "customer_phone": "+923001234567",
  "delivery_address_line1": "House 12, Street 4",
  "delivery_city": "Lahore",
  "delivery_postcode": "54000",
  "delivery_notes": "Ring the bell",
  "subtotal": 1500.00,
  "item_discount_total": 0,
  "order_discount_total": 0,
  "total": 1550.00,
  "delivery_fee": 50.00,
  "payment_type": "cash",
  "payment_status": "unpaid",
  "status": "received",
  "is_prepaid": true,
  "is_held": false,
  "created_by_user_id": "profile-uuid",
  "notes": "Extra napkins",
  "device_id": "customer-device-uuid",
  "is_synced": true,
  "sync_action": "create",
  "version": 1
}
```

Include delivery fee in `total` and/or `notes` — align with desktop `total` field (recommended: add delivery fee into `total`, store fee separately in notes or future column).

---

## 6. Pricing Rules (port from desktop)

- Line total = `(unit_price + modifier_deltas) * quantity`
- Subtotal = sum of line totals before discounts
- Customer app v1: **no waiter discounts** (customer-facing promos = deals only)
- Deals: use `DealAvailability` rules from desktop (`deal_availability.dart`)
- Currency display: read `currency_code` from `restaurant_public_config`

---

## 7. Security Checklist

- [ ] Customer JWT only sees own `orders` rows
- [ ] Customer cannot SELECT `app_users`, `employees`, payroll
- [ ] Customer cannot UPDATE catalog tables
- [ ] `SUPABASE_ANON_KEY` / publishable key only in client (never service role)
- [ ] RLS enabled on all new tables
- [ ] Rate limiting via Supabase Dashboard for auth endpoints

---

## 8. End-to-End Test Plan

| # | Step | Expected |
|---|------|----------|
| 1 | Apply all SQL migrations | No errors in Supabase |
| 2 | Desktop logged in as admin, monitor mode on | Tablet Orders screen open |
| 3 | Customer registers + logs in | Profile row exists |
| 4 | Browse menu, add items, checkout delivery | Checkout validates address |
| 5 | Place order | `ODRM-*` row in Supabase |
| 6 | Within 30s on desktop | Incoming order + highlight |
| 7 | Auto-print | Kitchen + customer slips print |
| 8 | Desktop advances status | Customer app timeline updates |
| 9 | Customer places takeaway | No address required; still prints |

---

## 9. Optional v2 Features (out of scope v1)

- Stripe/JazzCash online payment (`payment_status = paid`)
- Push notifications (FCM + Supabase Edge Function)
- Loyalty points / promo codes
- Favorites & reorder
- Isar offline cart + queue
- Dine-in QR table ordering
- Desktop sync of `restaurant_public_config` from local business settings

---

## 10. Module Build Order

```
C0  Desktop detection patch (restaurix/)
C1  Project + theme
C2  Auth (register/login)
C3  Home + public config
C4  Menu browse
C5  Product detail
C6  Cart
C7  Checkout + place order  ← critical integration point
C8  Order tracking (Realtime)
C9  Profile + addresses
C10 Shell navigation
```

---

## 11. Quick Reference — Files in Desktop to Study

| File | Why |
|------|-----|
| `lib/domain/services/tablet_order_detection.dart` | Remote order detection (`ODR` / `ODRM`) |
| `lib/features/tablet_orders/services/tablet_order_auto_print_service.dart` | Auto dual print |
| `lib/core/sync/order_realtime_listener.dart` | Realtime insert handling |
| `lib/data/services/order_number_service.dart` | Order prefix conventions |
| `lib/domain/models/order_enums.dart` | Wire enums |
| `supabase/migrations/*.sql` | Schema source of truth |

---

*Document version: 1.0 — matches Restaurix desktop as of customer-app spec. Apply Module C0 in desktop before end-to-end testing.*
