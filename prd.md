# Shanyraq (Шаңырақ) — Product Requirements Document

**Status:** Live beta, single-city (Almaty) MVP
**Live URL:** https://nurmukhammed0.github.io/shanyraq/
**Repository:** github.com/Nurmukhammed0/shanyraq
**Last updated:** 2026-11-20

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
- Support more than one city (Almaty, Astana, Shymkent) with a single app-wide city switcher shared
  across the documents list, map, home catalog and the Buy-a-home marketplace.

**Non-goals (for this version)**
- Real payment processing (subscription payment is currently simulated — see §9).
- Native iOS/Android store distribution (web-only for now).
- Any city beyond the fixed three-city list below (adding a fourth city is a data-entry/registry task,
  not a code change — see §7.7).
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
- **New-building documents** (ЖК list) — searchable, filterable (status, district; city is fixed to
  Almaty today) list/grid of all tracked complexes → tap through to **Complex detail**.
- **Complex detail** — photo, status badge, free construction-status/year, paywalled
  documentation/violations/measures/court fields, "report an issue," favorite toggle, admin edit/delete.
- **Map** — flutter_map on OpenStreetMap raster tiles, custom teardrop pin markers colored by status,
  same filters as the list, geolocation, long-press-to-add for admins. Reached via a "Map" button from
  the documents list (carries the list's current filters with it), not a top-level destination.
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
- **Complex objects:** add/edit (reuses the same form for both), soft-delete to Trash.
- **Trash:** restore or permanently delete a soft-deleted complex.
- **Reports:** user-submitted "something's wrong with this complex" issues, with an open/resolved toggle.
- **Buy-a-home listings:** moderation queue filterable by status, approve/reject per listing.
- **Statistics:** counts of active/trashed complexes, total/subscribed users, open reports.
- Fully localized RU/KZ/EN (this was originally Russian-only by deliberate scope cut, then completed in
  full at the user's request — see §10).

### 7.5 Internationalization
- Custom lightweight dictionary-based system (`lib/l10n/app_strings.dart`), **not**
  `flutter_localizations`/ARB — a single `Map<String, Map<AppLanguage, String>>` with a
  `context.tr('key', {params})` extension. Three languages: Russian, Kazakh, English, switchable in
  Settings and persisted via `SharedPreferences`.
- The product's own name is the one deliberate exception to translation (see §1).

### 7.6 Notifications
- In-app only (no push yet): a badge/counter on the map and a Notifications screen listing status
  changes (`zhk_status_log`) for the user's favorited complexes. Can be toggled off in Settings.

### 7.7 Multi-city
- Supported cities are a fixed, hand-maintained list (`AppCity.all` in `lib/models/app_city.dart`):
  Almaty, Astana, Shymkent. Adding a fourth city means appending it there (plus translated labels in
  `app_strings.dart`, a map-center entry in `map_screen.dart`, and populating `zhk` rows for it) — it is a
  data-entry step, not a schema change, because `zhk.city` and `listings.city` already exist.
- The selected city is one piece of global state (`SettingsService.city`, persisted via
  `SharedPreferences`, same mechanism as the language setting) — not a per-screen filter — so switching
  city on the documents list carries over to the map, the home catalog preview, and the Buy-a-home feed.
- District lists are derived from the data (`distinct district` of whatever city is selected), not
  hard-coded per city, so no extra maintenance is needed when a new city's ЖК rows are added.
- The map re-centers to the selected city (a small `city → LatLng` lookup in `map_screen.dart`) and
  admin's "add ЖК by long-press" inherits the currently-selected city automatically.
- Buy-a-home listings also carry a `city` (owner-selected when posting, defaulting to the app's current
  city) and the marketplace feed filters to the selected city the same way the ЖК list does.

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
- **Operational dependency:** the recovery email's link redirect target comes from the Supabase
  project's own **Authentication → URL Configuration → Site URL / Redirect URLs** setting, not from
  app code — it must include the deployed GitHub Pages URL (and `localhost` for local dev) or the link
  will redirect somewhere wrong. Also subject to the same built-in Supabase email rate limits noted in
  §11 (custom SMTP follow-up).

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
- **Single city.** All data and the "city" filter chip are hard-coded to Almaty; the schema doesn't
  prevent adding more cities later, but nothing today makes that easy.

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

## 11. Known follow-ups (not yet done)

- Real payment gateway integration behind the existing subscription UI.
- Lawyer review of Privacy Policy / Terms of Service before any store submission.
- Custom SMTP for Supabase auth emails (the built-in email service has strict hourly rate limits, fine
  for current scale, not for production volume).
- Native mobile app packaging, if/when warranted.
- A fourth+ city: possible today without a schema change (see §7.7), but still needs someone to source
  and enter that city's red-zone/guaranteed-completion registry data.

## 12. Tech stack reference

- **Client:** Flutter 3.13 / Dart 3.1, Provider for state management, `flutter_map` + `latlong2` for the
  map, `image_picker` for photo uploads, `url_launcher` for tel/mailto links, `shared_preferences` for
  local settings.
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime + Edge Functions), accessed via
  `supabase_flutter`.
- **Hosting/CI:** GitHub Pages + GitHub Actions.
- **Brand color:** `#2454FF` (Material 3 `ColorScheme.fromSeed` seed color).
