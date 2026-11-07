# NÉP — Chạm vào nét riêng Việt Nam

A production-oriented React + Supabase starter for the NÉP tourism experience project. The repository includes authentication, PostgreSQL schema with row-level security, booking persistence, customer feedback, support tickets, private memories, admin management, QR check-in, a rule-based mood itinerary planner, budget calculation, live weather via Open-Meteo, and map links.

## Deploy to Cloudflare Pages

This is a Vite + React single-page application. Connect this GitHub repository to **Cloudflare Pages** (not Workers).

Use these build settings:

| Setting | Value |
|---|---|
| Production branch | `main` |
| Framework preset | `Vite` |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Root directory | `/` (repository root) |
| Node.js | `20` or newer |

In Cloudflare Pages → project → Settings → Environment variables, add the following for both Production and Preview as appropriate:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY` (the Supabase publishable/anon key only)

Then trigger a new deployment from the `main` branch. Vite builds the static site into `dist`. Cloudflare Pages automatically serves this SPA through `index.html` when no top-level `404.html` is present; no Workers runtime or Wrangler configuration is required for this frontend.

Do not put a Supabase service-role key in a `VITE_` variable or in browser code.

## Local setup

1. Install Node.js 20 or newer.
2. Run `npm install` in the repository root.
3. Copy `.env.example` to `.env` and set:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
4. In Supabase Dashboard → SQL Editor, run the database scripts in the intended migration order after reviewing them against the schema already installed in your project. Do not blindly rerun migrations that have already been applied.
5. Start locally with `npm run dev`.
6. Run tests with `npm test` and production build with `npm run build`.

Without Supabase credentials the app deliberately shows a configuration warning. Authentication and database operations are unavailable until a real Supabase project is configured.

## Supabase setup and administrator

The repository contains the initial schema at `001_initial_schema.sql` and subsequent SQL changes at the repository root and in `supabase/`. The tour-stop spatial/3D fields are added by `supabase/019_tour_stop_spatial_assets.sql`; review and apply this migration in Supabase before using the new stop editor and linked tour previews. Confirm which migrations have already been applied before running additional scripts; some files are sequential changes and some are alternative/overlapping revisions.

To create the first administrator safely:

1. Register the intended admin account through the app.
2. Confirm the email if email confirmation is enabled.
3. In Supabase SQL Editor, set the role for that exact account:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'admin@example.com');
```

4. Sign out and sign back in, then open `/admin`.

Never expose the service-role key or grant admin role from a public client form.

## What is implemented in source

- Email/password sign-up and sign-in using Supabase Auth.
- Customer/admin role checks using `profiles.role` and database RLS.
- Persistent booking requests and admin status changes.
- Persistent customer feedback and support tickets.
- Private memory entries tied to the signed-in customer.
- Destination and tour-stop management in the admin area.
- Booking-bound QR check-in for required tour stops, validated by the database.
- Open-Meteo weather information and Google Maps directions links.
- Responsive UI and original inline NÉP logo artwork.

## Production verification still required

A successful Vite build only verifies that the frontend compiles. Before treating NÉP as production-ready, verify the Cloudflare Pages deployment URL, configure the real Supabase environment variables, confirm that every required SQL migration is applied, and test sign-up/sign-in, booking persistence, admin permissions, QR validation, and storage with real test accounts. Do not display simulated payment success as a real bank transfer confirmation.

## Security notes

- Keep Supabase RLS enabled and review policies before public launch.
- Use only the Supabase publishable/anon key in frontend environment variables.
- Add CAPTCHA/rate limiting, audit logs, privacy/consent text, backups, monitoring, and a formal support workflow before a public launch.
- Weather information is informational and is not a substitute for official severe-weather alerts.


## NÉP product direction

NÉP focuses on lesser-known places in Vietnam and connects natural landscapes with local culture and community experiences. The main flow is: discover a place → understand the local context → explore a curated tour → review its stops, map and optional 3D model → book.

- **NÉP Explorer** matches visitor preferences with published destinations and tours using transparent rules; it is not represented as generative AI.
- **Tour stops** link to existing places where possible. Coordinates support map directions. Optional GLB/GLTF assets appear only on the relevant stop; a tour does not need a 3D model at every stop.
- **3D provenance** should identify the source and whether the model is illustrative or measured. Illustrative models must not be presented as accurate terrain.
- **Memory Capsule** stores private trip photos and booking-linked memories.
- Discovery Passport and standalone Storyteller features are not part of the current product experience. Legacy database tables and migration files are retained to protect existing records; they are not exposed as active navigation features.
