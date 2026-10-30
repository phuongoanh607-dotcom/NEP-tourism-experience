# NÉP — Chạm vào nét riêng Việt Nam

A production-oriented React + Supabase starter for the NÉP tourism experience project. The repository includes a real authentication flow, PostgreSQL schema with row-level security, booking persistence, customer feedback, support tickets, private memories, admin management, per-place QR check-in, a rule-based mood itinerary planner, budget calculation, live weather via Open-Meteo, and map links.

## What is real vs. what still needs external setup

### Implemented in source
- Email/password sign-up and sign-in using Supabase Auth.
- Customer/admin role checks using `profiles.role` and database RLS.
- Persistent booking requests and admin status changes.
- Persistent customer feedback and support tickets; admin can review/update tickets.
- Private memory entries tied to the signed-in customer.
- Place and local storyteller management in the admin area.
- QR generation in the admin area; check-in is validated by a Postgres RPC and unique per customer/place.
- Open-Meteo current weather API (no API key) and Google Maps directions links.
- Responsive UI and original inline NÉP logo artwork.

### Requires project credentials / live service configuration
- A Supabase project and execution of `supabase/migrations/001_initial_schema.sql`.
- Setting the first administrator role with the SQL statement below.
- A Netlify site connected to this repository or uploaded build.
- Real destination and storyteller data curated and verified by the project team.
- Custom email delivery/domain configuration is recommended before public launch.

No Supabase service-role key is used in the browser. Do not put service-role secrets in `VITE_` variables.

## Local setup

1. Install Node.js 20 or newer.
2. In this folder run `npm install`.
3. Copy `.env.example` to `.env` and set:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY` (Supabase publishable/anon key only)
4. Create a Supabase project and run the SQL migration in Supabase Dashboard → SQL Editor.
5. Start locally with `npm run dev`.
6. Run tests with `npm test` and production build with `npm run build`.

Without Supabase credentials the app deliberately shows a configuration warning. Public discovery and client-side planning remain viewable, but auth and database operations are unavailable.

## Create the administrator account

1. Register the intended admin email through the app at `/signup`.
2. Confirm the email if email confirmation is enabled.
3. In Supabase Dashboard → SQL Editor run this statement, replacing the email:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'admin@example.com');
```

4. Sign out and sign back in. Open `/admin`.
5. Never expose the service-role key or grant admin role from a public client form.

## Publish on Netlify

- Build command: `npm run build`
- Publish directory: `dist`
- Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in Netlify → Site configuration → Environment variables.
- Redeploy after setting environment variables.
- `netlify.toml` includes SPA routing fallback.

## QR check-in flow

1. Admin publishes a place from `/admin`.
2. Open the QR action in the admin place list and print the QR.
3. QR points to `/checkin?token=<uuid>`.
4. Customer signs in and scans the QR. `redeem_place_qr()` checks the private token and records one check-in per user/place.
5. The public `published_places` view excludes QR tokens; QR secrets are not exposed in public catalogue responses.

## Security notes

- RLS is enabled on all customer and operational tables.
- Customers can read their own bookings, check-ins, memories, feedback and support tickets.
- Only admins can manage places, storytellers, bookings status, feedback and support tickets.
- Admin QR token retrieval is guarded by `admin_get_place_qr_token()`.
- For a public production launch, add CAPTCHA/rate limiting, audit logs, privacy/consent text, backups, monitoring, and a formal emergency contact workflow.
- Weather information is informational only. It is not a substitute for official severe-weather alerts.

## Verification status

The frontend build and unit tests should be run in the delivery environment. Live Supabase integration tests cannot be truthfully marked passed until a real project URL/key are configured and a test account/database are available.
