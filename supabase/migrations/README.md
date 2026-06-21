# Supabase migrations

SQL migrations for the Restaurix backend schema.

## Apply migrations

### Option A — Supabase CLI (recommended)

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

### Option B — Dashboard

1. Open your [Supabase Dashboard](https://supabase.com/dashboard) → SQL Editor
2. Paste the contents of `migrations/20240621000000_initial_schema.sql`
3. Run

## Configure the Flutter app

1. Copy `.env.example` to `.env` in the project root:

   ```bash
   cp .env.example .env
   ```

2. Fill in your values from **Supabase Dashboard → Project Settings → API**:

   ```
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```

3. Restart the app (`flutter run`). On success you should see `Supabase ping: success` in the console.

`.env` is gitignored — never commit real keys.

## RLS note

All tables use permissive development policies (`dev_allow_all_*`) allowing full read/write for `anon` and `authenticated` roles. These are replaced with role-based policies in **Module 33**.
