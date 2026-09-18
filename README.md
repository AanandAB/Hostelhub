# HostelHub

A two-sided **Flutter** app (single codebase for Android + iOS) that connects hostel
**owners/managers** with **inmates/residents**. It removes the manual work of chasing
rent and guessing tomorrow's mess headcount by automating payments and food polling,
while giving owners a real-time dashboard plus the day-to-day operational tools —
complaints, visitors, notices, deposits, checkout, chat, expenses, ratings and SOS —
that turn the app into the single source of truth for the hostel.

> **Core promise to the owner:** onboard once, collect automatically, run the whole
> hostel from one dashboard.
> **Core promise to the inmate:** never miss a due date, never get asked twice,
> everything about your stay in one place.

---

## Features

### Owner / Manager
- **Onboarding** — hostel profile (name, address, rooms, beds) and per-inmate onboarding
  with auto-generated login credentials.
- **Rent engine** — per-inmate rent amount + due day, manual pay, digital receipts,
  payment history.
- **Mess polls** — create polls ("Dinner tomorrow?"), one-tap Yes/No responses, live
  headcount, nudge non-responders.
- **Dashboard** — inmates, occupancy %, rooms, quick actions.
- **Complaints** — triaged inbox, open → in-progress → resolved, resolution note.
- **Visitors & leave** — visitor log (name, phone, ID, purpose) and leave/attendance.
- **Deposits & checkout** — security deposit tracking and checkout requests.
- **Notices** — broadcast announcements to the whole hostel.
- **Chat** — threaded owner ↔ inmate messaging.
- **Expenses & P&L** — expense logging by category with live Profit & Loss
  (income = rent collected, expense, net, category breakdown).
- **Ratings** — aggregate stay ratings from inmates.
- **SOS** — incoming emergency alerts with acknowledge.
- **Multi-property** — run several hostels from one account; switch property on the
  dashboard.
- **Document vault** — rental agreements, house rules, KYC documents.
- **Property types** — hostel / PG / rental house / office space.
- **Feature toggles** — switch every module on/off; inmates only see what's enabled.
- **Bed & occupancy** — room capacity and per-bed uniqueness are enforced.

### Inmate / Resident
- **Rent** — see amount + due date, pay, view receipts and history.
- **Mess polls** — one-tap Yes/No on the latest poll.
- **Complaints** — raise a ticket with category + description.
- **Leave** — mark leave/attendance.
- **Deposit** — view own security deposit.
- **Notices** — read hostel announcements.
- **Chat** — message the owner/warden.
- **Rate stay** — 1–5 star rating + comment.
- **SOS** — one-tap emergency alert.
- **Documents** — hostel documents + upload own KYC.

---

## Tech Stack

| Layer | Choice |
| --- | --- |
| App | Flutter (Dart), Riverpod (state), GoRouter (navigation), http |
| Design | Custom glassmorphic theme (light + dark), Google Fonts |
| Local backend (dev/testing) | Dart `shelf` REST API, in-memory store |
| Production backends (placeholders ready) | Supabase **or** Firebase — switchable |
| Payments | Razorpay (UPI Autopay / eMandate) — placeholder ready |

The entire backend is behind **repository interfaces** (`AuthRepository`,
`PropertyRepository`, `RoomRepository`, `InmateRepository`, `RentRepository`,
`PollRepository`, `OpsRepository`) with three implementations — **Local** (LAN server),
**Supabase** (stub), **Firebase** (stub). Swap the whole backend with one config flag;
no feature code changes.

---

## Project Structure

```
HostelManage/
├── hostelhub/                  # Flutter app
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/         # AppConfig — backend + keys via --dart-define
│   │   │   ├── router/         # GoRouter, auth-aware redirects, owner guards
│   │   │   └── theme/          # glassmorphic theme (colors, typography, theme)
│   │   ├── data/
│   │   │   ├── backend_provider.dart   # BackendKind switch (local/supabase/firebase)
│   │   │   ├── local/          # LAN server client + Local*Repository impls
│   │   │   ├── supabase/       # SupabaseRepository stubs (TODO: wire SDK)
│   │   │   ├── firebase/       # FirebaseRepository stubs (TODO: wire SDK)
│   │   │   ├── models/         # data models
│   │   │   ├── repositories/   # repository interfaces + Backend aggregate
│   │   │   └── session_store.dart      # shared_preferences session persistence
│   │   ├── features/
│   │   │   ├── auth/           # splash, login, register, auth_controller
│   │   │   ├── onboarding/     # hostel setup wizard + providers
│   │   │   ├── inmates/        # add + list inmates
│   │   │   ├── rent/           # pay flow, payments screen, due ring
│   │   │   ├── polls/          # poll dashboard + inmate poll card
│   │   │   ├── ops/            # complaints, notices, visitors/leave, deposits/
│   │   │   │                   #   checkout, chat, expenses, ratings, SOS, documents
│   │   │   └── shell/          # app shell, tab screens (role-aware), More hub
│   │   └── presentation/
│   │       └── widgets/        # GlassCard, GlassButton, GlassTextField, bottom nav
│   └── ...                     # android/, ios/, pubspec.yaml
└── server/                     # Dart shelf local backend
    ├── bin/server.dart         # in-memory REST API
    └── *_test.py               # API smoke scripts (smoke, poll, ops, phase6, phase7)
```

---

## Getting Started

### Prerequisites
- Flutter SDK (3.47+), Dart 3.13+
- Android Studio / Xcode for device builds

### 1. Run the local backend

```bash
cd server
dart pub get
dart run bin/server.dart          # serves http://127.0.0.1:8081
```

Override the port with `PORT=9000 dart run bin/server.dart`.

### 2. Run the app against it

```bash
cd hostelhub
flutter pub get
flutter run --dart-define=BACKEND=local
```

To reach the server from a physical device on the same Wi-Fi, point the app at your
machine's LAN IP:

```bash
flutter run --dart-define=BACKEND=local \
  --dart-define=LOCAL_BASE_URL=http://<YOUR-LAN-IP>:8081
```

### 3. Build a release APK

```bash
cd hostelhub
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

---

### 4. Test on a phone (same Wi-Fi)

When the app runs on a **physical phone**, `127.0.0.1` means the phone itself — it
will **not** reach your PC. Point the app at your PC's LAN address instead.

1. **Find your PC's LAN IP** (Windows):
   ```bash
   ipconfig
   # look for "IPv4 Address" under your Wi-Fi adapter, e.g. 192.168.1.8
   ```
2. **Start the server** (step 1 above) — it binds to all interfaces, so the phone
   can reach it.
3. **Build the APK with that IP baked in**:
   ```bash
   cd hostelhub
   flutter build apk --release \
     --dart-define=BACKEND=local \
     --dart-define=LOCAL_BASE_URL=http://<YOUR-PC-IP>:8081
   # output: build/app/outputs/flutter-apk/app-release.apk
   ```
4. **Install the APK on the phone** (USB / Drive / WhatsApp, then allow
   "install from unknown sources").

The phone and the PC must be on the **same Wi-Fi network**. The IP is baked in at
build time — if the PC's IP changes, rebuild with the new address.

The IP, port and backend default live in `lib/core/config/app_config.dart`; the
`--dart-define` flags above override those defaults.

---

## Configuration

All environment-specific values are injected at build/run time via `--dart-define`
(never committed to source). See `lib/core/config/app_config.dart`.

| Key | Purpose |
| --- | --- |
| `BACKEND` | `local` \| `supabase` \| `firebase` (default `local`) |
| `LOCAL_BASE_URL` | local server URL (default `http://127.0.0.1:8081`) |
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | Supabase project credentials |
| `FIREBASE_*` | Firebase project credentials |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | Razorpay gateway credentials |

Secrets are never committed; add them via a local `.env` / CI variables.

---

## Backend Choice at Scale

Multi-tenancy is one shared backend with `tenant_id` (property id) on every row,
isolated at the data layer (Supabase RLS / Firebase security rules / code-enforced
for Cloudflare) — **never** one database per hostel.

| Scale | Recommendation | Why |
| --- | --- | --- |
| ~10 hostels (testing) | **Firebase Spark** ($0/mo, no auto-pause) | free tier covers it; generous realtime |
| 100+ hostels | **Supabase Pro** (~$30/mo) | SQL for financials, India region, RLS, zero lock-in |

Both are already placeholdered; only the chosen SDK needs wiring when you go to
production.

---

## Payments (Razorpay)

`lib/services/payments/payment_gateway.dart` defines the `PaymentGateway` interface
with a **RazorpayGateway** (stub) and a **MockPaymentGateway** for local testing.
The local backend records payments directly.

> ⚠️ **UPI Autopay (eMandate) requires a live Razorpay merchant account** and
> bank/NBFC sponsorship approval. It cannot be tested on Razorpay's test keys.
> Rent collection is a physical service, so it is exempt from Apple IAP and Razorpay
> is fine on iOS.

---

## Store Compliance (Play Store + App Store)

- ✅ In-app **account deletion** (both Google and Apple requirement) — see More → account.
- ✅ Android `targetSdk 36` + data-safety form + hosted privacy-policy URL.
- ✅ iOS privacy manifest.
- ✅ Rent is a physical service — no Apple IAP needed; Razorpay allowed.
- ✅ Secrets injected via `--dart-define`, never in the repo.

Remaining before submission (Phase 7): signing keys, privacy policy hosting,
store screenshots, data-safety form completion.

---

## Roadmap

- **Phases 1–5 (done):** design system, auth, onboarding, rent engine, mess polls,
  six ops modules.
- **Phase 6 (done):** chat, expenses & P&L, ratings, SOS.
- **Phase 6.5 (done):** multi-property, document vault.
- **Phase 7 (next):** live Razorpay autopay mandate, scheduled jobs, FCM/APNs push,
  geolocation for SOS, store submission prep.

---

## Pricing & Subscription

HostelHub is **subscription-based** — the owner/operator pays, inmates never do.

| Plan | Price | Includes |
| --- | --- | --- |
| Monthly | ₹599 / month | 1 property, unlimited rooms & inmates, all features |
| Yearly | ₹5,999 / year (~₹500/mo) | 1 property, everything in Monthly, ~17% cheaper |
| Extra property | +₹199 / month each | each property beyond the first |

Billing & enforcement rules:

- One subscription covers **one owner account** and all their properties.
- **Non-payment stops the app**: if a monthly subscription lapses or a yearly
  plan is not renewed, the owner's account is suspended and the app stops
  working for **all** their properties — both the owner and their inmates lose
  access until the plan is renewed.
- Adding an extra property is billed separately (prorated to the renewal date).
- Inmates never pay — only the hostel owner / operator is billed.

> The numbers above are the **proposed** defaults and are easy to change before
> launch (see the billing/subscription module in the roadmap).

---

## License

Proprietary — all rights reserved. Contact the author before reuse or distribution.
