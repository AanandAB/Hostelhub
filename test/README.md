# HostelHub test automation

One repository of tests for both delivery channels:

| Layer | Tool | Runs against |
| --- | --- | --- |
| **Web** (desktop + mobile browser) | Playwright + JavaScript | https://hostelhub.mynilam.in |
| **Native mobile** (Android / iOS) | WebdriverIO + Appium | the Flutter APK/IPA build |
| **API** | Playwright request layer (`lib/api-client.js`) | https://hostelhub.mynilamhousing.workers.dev |

Shared between all three: environment config (`config/env.js`), test data
factories (`config/testdata.js`) and the API client. The native layer only adds
Appium capabilities (`wdio.conf.js`) and accessibility-id selectors, so a flow
is written once per layer, not per platform hack.

```
test/
├── config/            env.js · testdata.js
├── lib/               api-client.js · flutter.js · fixtures.js · pages/ · mobile.js
├── e2e/               end-to-end flows (web)              + e2e/mobile/*.mobile.test.js (Appium)
├── smoketest/         fast, must-never-break checks
├── regression/        deep regression (API contract, occupancy rules, session)
├── test-cases/        catalogue → HostelHub_TestCases.xlsx + jira-import.csv
├── scripts/           cleanup.sql
├── playwright.config.js
└── wdio.conf.js
```

## Setup

```bash
cd test
cp .env.example .env      # adjust URLs if needed
npm install              # Playwright + ExcelJS (+ Appium/WebdriverIO)
npx playwright install chromium
```

## Running

```bash
npm run test:smoke        # ~1-2 min, run on every deploy
npm run test:e2e          # full web end-to-end flows
npm run test:regression   # deep regression (API + UI)
npm test                  # everything
npm run report            # open the last HTML report
npm run test:mobile       # Appium suite (needs emulator + APK)
```

Filter by tag: `npx playwright test --grep @regression`.
Pick a project: `npx playwright test --project=web-mobile-chromium`.

## How the app is driven (important)

HostelHub's web build renders to `<canvas>`, so DOM selectors find nothing.
`lib/flutter.js` activates Flutter's accessibility (semantics) tree on first
load; after that the UI is queryable with normal Playwright locators
(`getByRole`, `getByLabel`, text assertions). Two rules that matter:

1. Call `openApp(page)` (or use the `app` / `ownerApp` / `hostelApp` fixtures)
   before touching the page.
2. Text fields need a **click before typing** — `fill()` alone leaves Flutter's
   editing state empty. `fillField()` does this for you.

## Fixtures and test data

`lib/fixtures.js` gives every test its own isolated tenant:

- `owner` — a registered owner (unique username/email per run)
- `hostel` — owner + property + room, with `addInmate()`, `addPoll()`,
  `addNotice()` helpers and `hostel.api` for direct assertions
- `app` — the app open with semantics enabled
- `ownerApp` / `hostelApp` — same, already logged in

Test accounts use `@hostelhub.test` emails. Clean them up with
`test/scripts/cleanup.sql` (one statement at a time via `wrangler d1 execute`).

## Native (Appium) suite

```bash
cd ../hostelhub
flutter build apk --release \
  --dart-define=BACKEND=cloudflare \
  --dart-define=CLOUDFLARE_BASE_URL=https://hostelhub.mynilamhousing.workers.dev
cd ../test
ANDROID_APP_PATH=../hostelhub/build/app/outputs/flutter-apk/app-release.apk npm run test:mobile
```

Flutter publishes Semantics labels to the platform accessibility layer, so the
mobile specs reuse the same visible text (`~Username`, `~Log in`, `~Inmates`).

## Test case catalogue for Jira

```bash
npm run testcases
```

Generates `test-cases/HostelHub_TestCases.xlsx` (Summary · Test Cases · Jira
Import sheets) and `test-cases/jira-import.csv`.

Jira import: **Issues → Import issues from CSV** → upload the CSV → map
`Summary`, `Issue Type`, `Priority`, `Labels`, `Description`, `External issue
ID`. Because the ID column is populated, re-importing updates existing issues
instead of duplicating them. Set `JIRA_PROJECT_KEY` in `.env` if you want the
key embedded in labels.

## Conventions

- Test IDs are stable and used in three places: the spec name, the code comment
  and the Excel/Jira row. Never renumber — add new IDs.
- `@smoke`, `@e2e`, `@regression`, `@mobile` tags map to the folders and to the
  npm scripts.
- Assert on user-visible text or API contracts, never on internal widget keys.
- A failing test must say what broke: prefer `expect(text).toContain('…')` with
  a message over bare truthiness checks.
