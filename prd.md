# Shanyraq (Шаңырақ) — Product Requirements Document

**Status:** Live beta, single-city (Almaty) MVP — multi-city architecture is built and tested but
intentionally left disabled (see §7.7) until a second city's registry data actually exists.
**Live URL:** https://nurmukhammed0.github.io/shanyraq/
**Repository:** github.com/Nurmukhammed0/shanyraq
**Last updated:** 2026-11-24

---

## 1. Summary

Shanyraq is a Flutter Web app that helps people in Almaty, Kazakhstan check the safety of a residential
construction project (ЖК — жилой комплекс) before buying an apartment in it. Kazakhstan has a well-known
risk with off-plan ("shared equity") construction: developers go bankrupt, build without permits, or
freeze construction for years, leaving buyers with no apartment and no refund. The city government
publishes two authoritative lists — complexes flagged as problematic ("red zone") and complexes completed
under a state buyer-protection guarantee — but these lists are hard to find, not map-based, and not kept
in one place a regular buyer would check before signing a contract.

Shanyraq turns that government data into a searchable map and list, adds a subscription tier for detailed
violation/document data, and (new) a self-serve marketplace where owners can list their own property for
sale, moderated by an admin before going live.

The brand name is always rendered as **"Shanyraq"** in Latin script in the UI, regardless of the active
language — the Kazakh word (Шаңырақ, the wooden crown at the top of a yurt, a symbol of home and family)
is the inspiration for the name, but Cyrillic script is unreadable to non-Russian/Kazakh speakers, so the
product name itself is not translated.

## 2. Problem statement

- A buyer in Almaty has no single, trustworthy, map-based place to check "is this specific residential
  complex safe to buy into?" before paying a developer.
- The data that answers this question exists (government red-zone list + state-guarantee completion
  registry) but is distributed as static documents, not an app.
- Existing commercial listing sites (Krisha.kz, OLX, 2GIS) show real-estate listings but do not surface
  this construction-risk signal, and are not a data source Shanyraq is allowed to scrape (see §9,
  **Explicitly out of scope**).

## 3. Goals / non-goals

**Goals**
- Let anyone check a ЖК's status (red zone vs. state-guaranteed-completed) for free, including on a map.
- Monetize deeper due-diligence data (violations, legal measures, court status, full documentation state)
  via subscription.
- Let verified property owners list their own home for sale directly in the app, with human moderation
  before anything goes public.
- Work equally well as a phone app (bottom navigation) and as a desktop/tablet site (sidebar navigation),
  from one Flutter Web codebase.
- Ship in Russian, Kazakh and English throughout the user-facing app, including the admin panel.
- Be *able to* support more than one city (Almaty, Astana, Shymkent) with a single app-wide city switcher
  shared across the documents list, map, home catalog and the Buy-a-home marketplace — built, but
  currently switched off (§7.7) since only Almaty has real registry data.

**Non-goals (for this version)**
- Real payment processing (subscription payment is currently simulated — see §9).
- Native iOS/Android store distribution (web-only for now).
- Actually showing a second city to users today — the architecture no longer blocks it (§7.7), but no
  one has sourced Astana's or Shymkent's red-zone/guaranteed-completion registry data yet.
- Aggregating or scraping third-party listing inventory (see §9).

## 4. Target users

| User | Need |
|---|---|
| **Apartment buyer** | Check a specific ЖК's risk status before paying a developer; browse/search listings; get notified if a favorited ЖК's status changes. |
| **Property owner / seller** | Post their own home for sale without an agency, reaching serious buyers; subscription-gated to keep listings quality higher and fund the service. |
| **Admin (product owner today)** | Keep the ЖК registry accurate (add/edit/soft-delete objects), moderate marketplace listings, manage users (including blocking abusive accounts), watch basic usage stats, handle user-submitted issue reports. |

## 5. Platform & distribution

- **Flutter Web**, compiled with the **canvaskit** renderer (the `html` renderer was tried first and
  caused an out-of-memory crash loop on iOS Safari — see §10, Incident log).
- Hosted as a static site on **GitHub Pages**, base href `/shanyraq/`.
- **CI/CD:** `.github/workflows/deploy.yml` builds and deploys automatically on every push to `main`
  (`flutter build web --release --base-href /shanyraq/ --no-tree-shake-icons --web-renderer canvaskit`).
- **Responsive breakpoint:** 820px width (`kDesktopBreakpoint` in `lib/widgets/responsive.dart`).
  Below it: mobile layout (bottom navigation, single-column screens). At or above it: desktop layout
  (collapsible left sidebar, centered/width-constrained content, grid layouts for card lists). The two
  layouts share the same screen widgets — the split happens only in `AppShell` (`RootShell` vs.
  `DesktopShell`) and in a small number of width-aware layout choices inside list screens.

## 6. Information architecture

**Mobile (`RootShell`)** — bottom navigation, 3 destinations: Главная (Home) · Избранное (Favorites) ·
Профиль (Profile). "Documents" and "Buy a home" are reached from two buttons on the Home screen.

**Desktop (`DesktopShell`)** — a persistent left sidebar with the app logo, 4 nav items (Home, New-building
documents, Buy a home, Favorites — promoted directly into the sidebar since desktop has the width to spare)
and, pinned at the bottom, a user card (avatar + name + quick log-out) instead of a 5th "Profile" nav row.
The sidebar can be collapsed to an icon-only rail with an animated width/label transition.

**Core screens**
- **Home** — ad/promo banner (currently self-promotional; literally labelled as an ad slot, with
  "your ad could be here" copy for future advertisers), a live "N complexes tracked" counter, and a
  7-item preview catalog mixing problematic/guaranteed objects.
- **New-building documents** (ЖК list) — a search bar plus a single **«Фильтры»** button (city chip
  hidden while only one city is active, §7.7) that opens a two-level bottom sheet: a root screen listing
  filter *categories* (Статус, Район) each showing their current value, tapping one drills into that
  category's options with a back arrow, and a bottom "Показать (N)" button (live count, computed from the
  in-progress draft selection) commits the whole batch at once — replaced an earlier always-visible
  horizontal chip row, which stopped scaling once there were two filter categories and wouldn't scale
  further if more are added later (see §10) → tap a complex to reach **Complex detail**.
- **Complex detail** — photo, status badge, free construction-status/year, paywalled
  documentation/violations/measures/court fields, "report an issue," favorite toggle, admin edit/delete.
- **Map** — flutter_map on OpenStreetMap raster tiles, custom teardrop pin markers colored by status, the
  same two-level «Фильтры» sheet as the documents list, geolocation, long-press-to-add for admins. Reached
  via a "Map" button from the documents list (carries the list's current filters with it), not a
  top-level destination.
- **Buy a home** — feed of **approved** owner listings only; a floating "Add listing" action (locked
  behind subscription + login); "My listings" to see the status of one's own submissions
  (pending / approved / rejected); a disclaimer that Shanyraq does not verify documents or deal terms
  for these listings.
- **Favorites**, **Notifications** (status-change alerts for favorited complexes), **Profile** (edit
  name/avatar, change password, subscription, settings, admin entry point, about/legal, delete account,
  log out).
- **Admin** (hub + 6 screens) — Users, Complex objects, Trash, Reports, Buy-a-home listings (moderation
  queue), Statistics.

## 7. Core features, in detail

### 7.1 Complex registry (the core dataset)
- Two status values: `problematic` (red zone) and `completed_guaranteed` (state guarantee).
- Sourced from two official documents: the Almaty city construction-oversight red-zone list and the
  state-guarantee completion registry (~38 objects at last import).
- Fields: name, city, district, address, developer, status, documentation, tech_status, violations,
  measures, court, lat/lng, photo_url, construction_status (`built`/`in_progress`), completion_year.
- **Free to everyone:** construction status + completion year (deliberately — buyers care about this even
  without paying).
- **Subscription-gated:** documentation, tech_status, violations, measures, court — the deeper
  due-diligence fields.
- Coordinates were originally synthetic (a placeholder ring pattern around a district center) and have
  since been re-geocoded against real addresses via the OpenStreetMap/Nominatim API; a few
  individually-wrong geocodes (e.g. one that landed on a cemetery) were corrected by hand.

### 7.2 Subscription
- Simulated payment flow today (card-number-style form or "Apple ID" option, masked card display,
  auto-renew toggle) — explicitly a placeholder: `activateSubscription()` just flips a flag via a
  SECURITY DEFINER RPC, pending a real payment gateway integration (see §9).
- Gates: paywalled complex detail fields, the red-zone/guaranteed status *filter* on the documents list
  and map (the status itself is still visible per-item for free), and posting a "Buy a home" listing.

### 7.3 Buy a home (owner-to-buyer marketplace)
- **Why self-serve, not aggregated:** scraping Krisha.kz/OLX/2GIS for listings (including phone numbers)
  was explicitly considered and rejected — see §9. Listings are entered directly by the owner instead.
- Posting requires an active subscription and being logged in.
- New listings start in `pending` status and are not visible to the public until an admin approves them
  (`listings.status`: `pending` → `approved` / `rejected`), enforced by RLS (public SELECT only sees
  `approved`; the owner and admins can also see their own pending/rejected rows).
- Owner-entered fields: title, description, price, district, address, rooms, area, phone, contact name,
  one photo.
- Disclaimer shown both when posting and when viewing: Shanyraq does not verify the listing's documents
  or the deal — that is on the buyer and seller.

### 7.4 Admin panel
- **Users:** create (via `admin-create-user` Edge Function, since client-side Supabase Auth can't create
  other users), toggle role/subscription, block/unblock, delete (via SECURITY DEFINER RPCs
  `admin_set_blocked` / `admin_delete_user`).
- **Complex objects:** add/edit (reuses the same form for both), soft-delete to Trash. City field in the
  form, and a city filter row in the list (both hidden while `AppCity.all` has only one entry, §7.7).
- **Trash:** restore or permanently delete a soft-deleted complex; city shown per row.
- **Reports:** user-submitted "something's wrong with this complex" issues, with an open/resolved toggle;
  city shown per row (joined from `zhk`).
- **Buy-a-home listings:** moderation queue filterable by status (and by city, same hide-if-one-city
  rule), approve/reject per listing.
- **Statistics:** counts of active/trashed complexes, total/subscribed users, open reports.
- Fully localized RU/KZ/EN (this was originally Russian-only by deliberate scope cut, then completed in
  full at the user's request — see §10).
- Admin writes to `zhk` (create/edit/soft-delete/restore/permanently-delete) each call
  `ZhkChangeNotifier.notifyChanged()` after a successful write — see §8's `zhk_public` note for why this
  exists (plain Postgres Changes stopped reaching non-admin viewers once direct `zhk` reads became
  admin-only).

### 7.5 Internationalization
- Custom lightweight dictionary-based system (`lib/l10n/app_strings.dart`), **not**
  `flutter_localizations`/ARB — a single `Map<String, Map<AppLanguage, String>>` with a
  `context.tr('key', {params})` extension. Three languages: Russian, Kazakh, English, switchable in
  Settings and persisted via `SharedPreferences`.
- The product's own name is the one deliberate exception to translation (see §1).
- Supabase Auth errors (wrong password, email not confirmed, rate-limited, …) used to leak straight
  through as `AuthException.message` — raw English, regardless of the selected app language. Found while
  testing the forgot-password flow (§7.8) with an unconfirmed test account. `AuthService` now returns
  `AuthException.code` (a stable machine-readable string like `email_not_confirmed`) instead of the
  message when one is available, and a `context.trAuthError()` extension (next to `context.tr`) maps the
  known codes to translated strings, falling back to the raw message only for the rare error that has no
  code.

### 7.6 Notifications
- In-app only (no push yet): a badge/counter on the map and a Notifications screen listing status
  changes (`zhk_status_log`) for the user's favorited complexes. Can be toggled off in Settings.

### 7.7 Multi-city
- Supported cities are a fixed, hand-maintained list (`AppCity.all` in `lib/models/app_city.dart`). It was
  shipped with all three entries live (Almaty, Astana, Shymkent) and the full city-switcher UI (a chip
  opening a city picker, everywhere the registry is browsed), then almost immediately scaled back to just
  Almaty — showing a switcher for cities with zero registry rows read as broken, not "coming soon." Astana
  and Shymkent stay defined as constants (with translated labels already in `app_strings.dart` and map
  centers already in `map_screen.dart`) but commented out of the `all` list; re-enabling a city later is
  uncommenting one line, not new code.
- Every screen that shows a city chip/filter (documents list, map, Buy-a-home, both admin moderation
  queues) guards it with `if (AppCity.all.length > 1)` — so the instant a second city is uncommented, the
  switcher reappears everywhere at once, with nothing else to wire up.
- The selected city is one piece of global state (`SettingsService.city`, persisted via
  `SharedPreferences`, same mechanism as the language setting) — not a per-screen filter — so switching
  city on the documents list carries over to the map, the home catalog preview, and the Buy-a-home feed.
- District lists are derived from the data (`distinct district` of whatever city is selected), not
  hard-coded per city, so no extra maintenance is needed when a new city's ЖК rows are added.
- The map re-centers to the selected city (a small `city → LatLng` lookup in `map_screen.dart`) and
  admin's "add ЖК by long-press" inherits the currently-selected city automatically.
- Buy-a-home listings also carry a `city` (owner-selected when posting, defaulting to the app's current
  city) and the marketplace feed filters to the selected city the same way the ЖК list does.
- Adding a real fourth+ city later is still the data-entry step described above (plus populating `zhk`
  rows for it) — not a schema change, because `zhk.city` and `listings.city` already exist.

### 7.8 Authentication
- Email+password (Supabase Auth) and Google OAuth. Login is required to use the app at all (`AuthGate`
  shows `LoginScreen` whenever there is no session — see §6).
- **Forgot password:** `LoginScreen` has a "Forgot password?" link → `ForgotPasswordScreen` collects an
  email and calls `AuthService.resetPasswordForEmail`, which wraps Supabase's
  `resetPasswordForEmail` (always reports success in the UI regardless of whether the email exists, to
  avoid leaking which emails are registered). Supabase emails a recovery link; opening it signs the
  browser in with a short-lived "recovery" session and fires `AuthChangeEvent.passwordRecovery`.
  `AuthService.isPasswordRecovery` tracks that event, and `AuthGate` checks it **before** the normal
  logged-in check, so the user lands on `ResetPasswordScreen` (set-new-password only, no old password
  needed — the link itself already proved mail ownership) instead of straight into the app with
  whatever password they were trying to replace. Saving the new password clears the flag and the gate
  falls through to the normal `AppShell`.
- **Redirect target is set explicitly in code, not left to Supabase's default.** `resetPasswordForEmail`,
  `signUp` (`emailRedirectTo`), and `signInWithGoogle` (`redirectTo`) all pass
  `https://nurmukhammed0.github.io/shanyraq/` explicitly for web. Leaving any of them unset (`null`) makes
  supabase_flutter fall back to the current page's bare origin (`.../github.io/`, no `/shanyraq/` path) —
  which 404s on GitHub Pages — regardless of what the Supabase dashboard's Site URL says. Found via the
  password-recovery link first (see §10), then proactively checked and fixed the same way in the other
  two, since all three share the identical default-redirect code path.
- **Auth flow type is `AuthFlowType.implicit`, set explicitly in `Supabase.initialize()`** — not the
  supabase_flutter default (`AuthFlowType.pkce`). PKCE stores the code-exchange secret in the *initiating*
  browser's local storage; a password-recovery email is close to always opened in a *different*
  browser/device than the one that requested it, where that secret doesn't exist, so the code-exchange
  silently fails (no error — the link just quietly fails to establish a session). Implicit flow embeds the
  session tokens directly in the redirect URL fragment instead, so it works regardless of where the link
  is opened. See §10 for how this was diagnosed.
- **Why `AuthService.isPasswordRecovery` is seeded from the URL in `main()`, not only from the
  `AuthChangeEvent.passwordRecovery` stream event:** `onAuthStateChange` is a broadcast stream with no
  replay — GoTrue can process the recovery link and emit that event *during* `Supabase.initialize()`,
  before `AuthService`'s constructor (created afterward, in `main()`'s `runApp`) has subscribed to
  anything. `main()` parses `Uri.base` for `type=recovery` *before* calling `Supabase.initialize()` and
  passes that as `AuthService(initialPasswordRecovery: ...)`, so the recovery state is known independent
  of whether the stream event is ever actually caught. The event listener is kept as a secondary path.
  `AuthGate` shows a timeout-guarded spinner (`_PasswordRecoveryWaiting`) while a recovery link's session
  is still being established, with a manual "back to login" escape hatch if it never completes (expired
  or already-used link).

## 8. Data model (Supabase / Postgres)

All tables have **Row Level Security enabled**; privileged writes go through **SECURITY DEFINER** RPC
functions (never raw client-side updates to other users' rows) to avoid privilege-escalation bugs — see
`supabase/profiles_and_subscriptions.sql` for the pattern (`is_admin()` helper + policies built on it).

| Table | Purpose | Key columns |
|---|---|---|
| `profiles` | 1:1 with `auth.users` | `role` (user/admin), `is_subscribed`, `blocked`, `auto_renew`, `display_name`, `avatar_url` |
| `zhk` | The complex registry (§7.1) | see §7.1; `city` (default `'Алматы'`, indexed); `deleted_at` for soft-delete |
| `favorites` | user ↔ zhk | `user_id`, `zhk_id` |
| `zhk_status_log` | status-change history, drives notifications | `zhk_id`, `old_status`, `new_status` |
| `zhk_reports` | user-submitted issue reports | `zhk_id`, `message`, `status` (open/resolved) |
| `listings` | Buy-a-home marketplace (§7.3) | `owner_id`, `status` (pending/approved/rejected), `deleted_at` |

**Storage buckets:** `avatars`, `zhk-photos`, `listing-photos` (public read; scoped write policies).

**Key RPCs / Edge Functions:** `is_admin()`, `update_own_profile`, `activate_own_subscription`,
`set_own_auto_renew`, `delete_own_account`, `admin_set_blocked`, `admin_delete_user`,
`admin-create-user` (Edge Function).

**`zhk_public` view (column-level paywall enforcement).** RLS controls row visibility, not column
visibility — the original `zhk_read_all` policy (`using (true)`) let anyone, including anonymous
unauthenticated clients, `select *` from `zhk` over the REST API directly, bypassing the app UI entirely.
Since the subscription gate on `documentation`/`tech_status`/`violations`/`measures`/`court` (§7.1, §7.2)
was originally enforced only in the Flutter widgets, that meant anyone who inspected network traffic (or
just read the public anon key out of the client bundle — expected/normal for Supabase, not itself a bug)
could fetch the full paid dataset for free, no subscription required. Two migrations fixed this in
sequence:

- `supabase/zhk_public_view.sql` added a `zhk_public` view that nulls out those five columns unless
  `profiles.is_subscribed` is true for the requesting user; `ZhkRepository.fetchFromSupabase()` (the read
  path used by the documents list, map, home catalog, and favorites) reads this view instead of the base
  table.
- `supabase/zhk_lock_table_access.sql` went further and closed the base table itself: `zhk_read_all` is
  now `zhk_read_admin_only` (`using (is_admin())`), so even someone who finds/guesses the `zhk` table name
  and queries it directly gets nothing unless they're an admin. For `zhk_public` to still work for
  everyone else after that, it had to be recreated **without** `security_invoker` — a `security_invoker`
  view runs with the *caller's* RLS, which would have made it as locked-down as the base table for
  non-admins; without it, the view runs as its owner (bypasses RLS, sees every row) and does the
  subscriber-check redaction itself.
- Side effect: Supabase Realtime (Postgres Changes) enforces RLS when delivering change events, so once
  `zhk` reads are admin-only, non-admins stop receiving `onPostgresChanges(table: 'zhk')` events entirely.
  `map_screen.dart`'s live-refresh was switched to a `zhk-updates` Broadcast channel instead (not governed
  by table RLS): every successful admin write to `zhk` calls `ZhkChangeNotifier.notifyChanged()`, which
  every open map screen is listening for, triggering a plain re-fetch from `zhk_public`.

Admin writes still go straight to the `zhk` table (unaffected, already gated by the existing admin-only
INSERT/UPDATE/DELETE policies) — only the public **read** path and the realtime signal mechanism changed.

## 9. Explicitly out of scope / deliberate exclusions

- **No scraping or aggregating third-party listing data** (Krisha.kz, OLX, 2GIS, or anyone else).
  Considered and rejected: it would mean redistributing other people's personal data (phone numbers)
  without their consent to *this* service, and would violate those platforms' terms of use — a real legal
  exposure for a project this size, not just a style choice. The Buy-a-home marketplace is first-party
  (owners post themselves) specifically because of this decision.
- **No real payment gateway yet.** Subscription activation is simulated by design — the UI (card form /
  Apple ID option, masked card, auto-renew) is real, but `activateSubscription()` just flips a database
  flag. Swapping in a real processor (Kaspi, Stripe, etc.) is a known, isolated follow-up — see §11.
- **Legal copy is a draft.** Privacy policy and terms of service are deliberately short placeholder text,
  flagged in source comments to be reviewed by an actual lawyer before any app-store submission or paid
  launch.
- **Single city, by data availability rather than by architecture.** The multi-city switcher, schema
  columns, and per-screen filtering all exist and work (§7.7); only Almaty is turned on because no one has
  sourced Astana's or Shymkent's registry data yet.
- **Buy-a-home listings' phone numbers/contact names are publicly readable by anyone, including
  unauthenticated scrapers** (`listings_read_all`: `status = 'approved'`, no auth check). Considered
  alongside the `zhk` paywall-bypass fix (§8) and *not* changed: unlike the paywall case, showing a
  seller's contact info to any prospective buyer — logged in or not — is the explicit point of a public
  real-estate listing (same as Krisha.kz, OLX, or any classifieds site), not an accidental leak of
  something meant to be gated. Revisit only if bulk-harvesting by competitors becomes an actual observed
  problem, not preemptively.

## 10. Incident log (decisions worth remembering)

- **iOS Safari crash-loop ("A problem repeatedly occurred").** Root-caused via a JetsamEvent OS crash log
  pulled from the user's iPhone, showing a ~2.4 GB WebKit memory spike. Caused by the `html` web renderer;
  fixed by switching to `canvaskit` combined with adding a missing `<meta name="viewport">` tag.
- **Map tiles started requiring a paid key.** CARTO basemaps added a paid-API requirement; switched to
  Esri (free), then later to plain OpenStreetMap tiles because Esri's generalized basemap wasn't kept
  current for newer/informal neighborhoods at the city's edge, which is exactly where many red-zone
  complexes are.
- **Marker coordinates were fake.** Original lat/lng values were a synthetic ring generated around each
  district's centroid (not real geocoding), producing visibly circular clusters on the map. Fixed by
  re-geocoding every address against OpenStreetMap/Nominatim.
- **Admin panel language scope.** Initially shipped Russian-only as a deliberate cut; fully localized to
  RU/KZ/EN later in the project at the user's explicit request.
- **Sidebar collapse-animation bug.** The collapsed/expanded icon row used to snap its alignment and
  padding instantly while only the container width animated, making the selection highlight visibly jump.
  Fixed by keeping the icon's position constant in both states and animating only the label's width/opacity.
- **Password-reset link 404'd, and the real cause wasn't where it looked.** First symptom: the emailed
  link opened `https://nurmukhammed0.github.io/` (no `/shanyraq/`) → GitHub Pages 404. Looked like a
  Supabase dashboard **Site URL** misconfiguration; the user's screenshot showed it set correctly, Save
  clicked. Root cause was actually in the client: `resetPasswordForEmail(..., redirectTo: null)` on web
  makes supabase_flutter default to the page's bare origin, ignoring the dashboard's Site URL entirely.
  Fixed by passing the full URL explicitly (see §7.8) — then found and pre-emptively fixed the identical
  default in `signUp` and `signInWithGoogle` too.
- **...then the (now-correct) link still didn't show the reset-password screen.** Two compounding causes,
  found in sequence: (1) `AuthChangeEvent.passwordRecovery` was firing but being missed —
  `onAuthStateChange` has no replay, and GoTrue can emit it during `Supabase.initialize()`, before
  `AuthService` exists to listen (fixed by reading the URL in `main()` first, see §7.8); (2) even after
  that fix, a test performed on a different device than the one that requested the reset still silently
  failed — traced to PKCE's code-exchange secret living only in the *requesting* browser's local storage,
  which is close to never the device someone opens a password-recovery email on. Fixed by switching the
  whole app to `AuthFlowType.implicit` (§7.8), which doesn't need that secret at all.
- **The subscription paywall had no backend enforcement — anyone could read it for free.** Discovered
  while deliberately checking "can someone copy our data" after an unrelated feature request. Row Level
  Security restricts which *rows* a query can see, not which *columns* — `zhk_read_all`'s `using (true)`
  meant any anonymous request to `/rest/v1/zhk?select=*` returned the paid `documentation`/`violations`/
  etc. fields in full; the subscription check lived only in the Flutter widgets. Confirmed with a live
  `curl` against the production API before and after each fix (see §8 for the two-migration fix and the
  Realtime side effect it caused).

## 11. Known follow-ups (not yet done)

- Real payment gateway integration behind the existing subscription UI.
- Lawyer review of Privacy Policy / Terms of Service before any store submission.
- Custom SMTP for Supabase auth emails (the built-in email service has strict hourly rate limits, fine
  for current scale, not for production volume).
- Native mobile app packaging, if/when warranted.
- Re-enabling Astana/Shymkent (or adding a true fourth city): the switcher, schema, and per-screen
  filtering already work (§7.7) — this is purely "source that city's red-zone/guaranteed-completion
  registry data, add the rows, uncomment one line in `AppCity.all`," not a development task.
- A bulk CSV/JSON import tool for the `zhk` registry — floated when discussing how a second city's data
  would get entered, not yet built. Today, adding complexes means the one-at-a-time admin form; fine for
  occasional edits to ~38 rows, painful for onboarding an entire new city at once.

## 12. Tech stack reference

- **Client:** Flutter 3.13 / Dart 3.1, Provider for state management, `flutter_map` + `latlong2` for the
  map, `image_picker` for photo uploads, `url_launcher` for tel/mailto links, `shared_preferences` for
  local settings.
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime + Edge Functions), accessed via
  `supabase_flutter`.
- **Hosting/CI:** GitHub Pages + GitHub Actions.
- **Brand color:** `#2454FF` (Material 3 `ColorScheme.fromSeed` seed color).
