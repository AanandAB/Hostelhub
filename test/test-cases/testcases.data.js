/**
 * Single source of truth for the manual/automation test case catalogue.
 *
 * `automation` links a case to the automated test that covers it
 * (file + test name). Cases without automation are manual checks and are
 * flagged so, which is what makes the Excel useful for a QA sign-off.
 *
 * Used by generate-test-cases.js to produce:
 *   • HostelHub_TestCases.xlsx  (Summary + Test Cases + Jira Import sheets)
 *   • jira-import.csv           (direct import into Jira: Issues → Import)
 */
export const testCases = [
  // ── Authentication ────────────────────────────────────────────────────────
  {
    id: 'SMK-02', module: 'Authentication', title: 'App loads and shows the login screen',
    type: 'Smoke', priority: 'P1', severity: 'Critical',
    preconditions: 'Web app deployed and reachable',
    steps: ['Open https://hostelhub.mynilam.in', 'Wait for the Flutter app to render'],
    expected: 'Login screen shows "Welcome back", Username and Password fields, Log in button',
    data: 'n/a', automation: 'smoketest/smoke.spec.js › SMK-02 app loads and shows the login screen',
  },
  {
    id: 'SMK-03', module: 'Authentication', title: 'Owner logs in and sees the dashboard',
    type: 'Smoke', priority: 'P1', severity: 'Critical',
    preconditions: 'Owner account exists with a property',
    steps: ['Open the app', 'Enter valid username and password', 'Tap Log in'],
    expected: 'Dashboard shows the property name, Inmates / Occupancy / Rooms stats and the four tabs',
    data: 'owner seeded per run', automation: 'smoketest/smoke.spec.js › SMK-03 owner can log in and see the dashboard',
  },
  {
    id: 'E2E-AUTH-02', module: 'Authentication', title: 'Invalid password is rejected',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'Valid owner account exists',
    steps: ['Open the app', 'Enter a valid username with a wrong password', 'Tap Log in'],
    expected: 'User stays on the login screen and an error message is shown',
    data: 'Wrong password', automation: 'e2e/auth.spec.js › E2E-AUTH-02 invalid password is rejected...',
  },
  {
    id: 'E2E-AUTH-03', module: 'Authentication', title: 'Sign-up screen opens from login',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'App loaded on the login screen',
    steps: ['Tap "Sign up"'], expected: 'Create-account screen is displayed',
    data: 'n/a', automation: 'e2e/auth.spec.js › E2E-AUTH-03 sign-up screen opens...',
  },
  {
    id: 'E2E-AUTH-04', module: 'Authentication', title: 'Forgot-password screen opens from login',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'App loaded on the login screen',
    steps: ['Tap "Forgot password?"'], expected: 'Password reset screen is displayed',
    data: 'n/a', automation: 'e2e/auth.spec.js › E2E-AUTH-04 forgot-password screen opens...',
  },
  {
    id: 'E2E-AUTH-05', module: 'Authentication', title: 'Protected route redirects to login when signed out',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'No active session',
    steps: ['Open #/expenses directly'], expected: 'User is redirected to the login screen',
    data: 'n/a', automation: 'e2e/auth.spec.js › E2E-AUTH-05 unauthenticated deep link...',
  },
  {
    id: 'REG-AUTH-01', module: 'Authentication', title: 'Session survives a page reload',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'Owner logged in', steps: ['Reload the browser page'], expected: 'User remains on the dashboard, still authenticated',
    data: 'n/a', automation: 'regression/auth.regression.spec.js › REG-AUTH-01',
  },
  {
    id: 'REG-AUTH-04', module: 'Authentication', title: 'Logout returns to the login screen',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'Owner logged in', steps: ['Open the More tab', 'Tap Log out'],
    expected: 'Session is cleared and the login screen is shown',
    data: 'n/a', automation: 'regression/auth.regression.spec.js › REG-AUTH-04',
  },
  {
    id: 'REG-AUTH-05', module: 'Authentication', title: 'Password reset request accepts an email',
    type: 'Regression', priority: 'P2', severity: 'Medium',
    preconditions: 'App on the login screen', steps: ['Tap Forgot password?', 'Enter an email', 'Submit'],
    expected: 'The app acknowledges the request without an error screen',
    data: 'nobody@hostelhub.test', automation: 'regression/auth.regression.spec.js › REG-AUTH-05',
  },

  // ── Onboarding ────────────────────────────────────────────────────────────
  {
    id: 'E2E-ONB-01', module: 'Onboarding', title: 'New owner sees the setup prompt',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'Owner account with no property',
    steps: ['Log in as a new owner'], expected: 'Dashboard shows "Set up your hostel" with a Get started button',
    data: 'fresh owner', automation: 'e2e/onboarding.spec.js › E2E-ONB-01',
  },
  {
    id: 'E2E-ONB-02', module: 'Onboarding', title: 'Setup wizard opens from the prompt',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'New owner logged in', steps: ['Tap Get started'], expected: 'Setup wizard renders its first step',
    data: 'n/a', automation: 'e2e/onboarding.spec.js › E2E-ONB-02',
  },
  {
    id: 'E2E-ONB-03', module: 'Onboarding', title: 'Created property appears on dashboard and inmates tab',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'Owner with a property and a room',
    steps: ['Log in', 'Check dashboard', 'Open the Inmates tab'],
    expected: 'Property name is shown on both screens, room appears with 0/capacity beds',
    data: 'property + room seeded', automation: 'e2e/onboarding.spec.js › E2E-ONB-03',
  },
  {
    id: 'MNL-ONB-01', module: 'Onboarding', title: 'Complete setup wizard end to end',
    type: 'Manual', priority: 'P1', severity: 'High',
    preconditions: 'New owner, no property',
    steps: ['Tap Get started', 'Fill property name, address, type, rent', 'Continue to rooms', 'Add two rooms with capacity', 'Finish'],
    expected: 'Property and rooms are created; dashboard shows them; data persists after reload',
    data: 'Test hostel, 2 rooms x 2 beds', automation: '',
  },

  // ── Inmates ───────────────────────────────────────────────────────────────
  {
    id: 'SMK-05', module: 'Inmates', title: 'Inmates tab lists seeded residents',
    type: 'Smoke', priority: 'P1', severity: 'Critical',
    preconditions: 'Property with one resident',
    steps: ['Log in', 'Open the Inmates tab'], expected: 'Resident name, room and bed are listed',
    data: 'resident seeded', automation: 'smoketest/smoke.spec.js › SMK-05',
  },
  {
    id: 'E2E-INM-02', module: 'Inmates', title: 'Add a resident through the form',
    type: 'E2E', priority: 'P1', severity: 'Critical',
    preconditions: 'Property with a room that has a free bed',
    steps: ['Inmates tab → Add inmate', 'Select the room chip', 'Fill name, phone, email, bed, rent, due day', 'Tap Add inmate'],
    expected: 'Resident is created, credentials are shown, and the resident appears in the list',
    data: 'bed 2, rent 7000, due day 10', automation: 'e2e/inmates.spec.js › E2E-INM-02',
  },
  {
    id: 'REG-OCC-01', module: 'Inmates', title: 'Room capacity cannot be exceeded',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'Room with capacity 3',
    steps: ['Add 3 residents to the room', 'Attempt to add a 4th'],
    expected: 'API rejects the 4th resident with "room is full"',
    data: 'capacity 3', automation: 'regression/inmates.regression.spec.js › REG-OCC-01',
  },
  {
    id: 'REG-OCC-02', module: 'Inmates', title: 'A bed cannot be assigned twice',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'One resident on bed 1',
    steps: ['Attempt to add another resident on bed 1'],
    expected: 'API rejects with "bed already taken"', data: 'bed 1', automation: 'regression/inmates.regression.spec.js › REG-OCC-02',
  },
  {
    id: 'REG-OCC-03', module: 'Inmates', title: 'Bed number outside the room range is rejected',
    type: 'Regression', priority: 'P2', severity: 'Medium',
    preconditions: 'Room with capacity 3',
    steps: ['Attempt to add a resident on bed 99'],
    expected: 'API rejects with "bed is out of range"', data: 'bed 99', automation: 'regression/inmates.regression.spec.js › REG-OCC-03',
  },
  {
    id: 'MNL-INM-02', module: 'Inmates', title: 'Regenerate resident credentials',
    type: 'Manual', priority: 'P2', severity: 'Medium',
    preconditions: 'Existing resident',
    steps: ['Open resident detail', 'Tap regenerate credentials', 'Log in as the resident with the new password'],
    expected: 'New credentials work, old password no longer works', data: 'n/a', automation: '',
  },

  // ── Rent & payments ───────────────────────────────────────────────────────
  {
    id: 'MNL-RNT-01', module: 'Rent', title: 'Record a rent payment and see the receipt',
    type: 'Manual', priority: 'P1', severity: 'High',
    preconditions: 'Resident with rent configured',
    steps: ['Open the resident', 'Tap Pay rent', 'Complete the payment', 'Open payment history'],
    expected: 'Payment is recorded, dashboard "Today\'s collection" increases, receipt is available',
    data: '₹6500', automation: '',
  },
  {
    id: 'MNL-RNT-02', module: 'Rent', title: 'Generate and share a PDF invoice',
    type: 'Manual', priority: 'P2', severity: 'Medium',
    preconditions: 'Resident with rent and email',
    steps: ['Open Bills & invoices', 'Generate the invoice', 'Download/share it'],
    expected: 'PDF opens with property, resident, amount and total; WhatsApp/email share works',
    data: 'n/a', automation: '',
  },

  // ── Mess polls ────────────────────────────────────────────────────────────
  {
    id: 'E2E-POLL-01', module: 'Polls', title: 'Polls tab renders an active poll',
    type: 'E2E', priority: 'P1', severity: 'High',
    preconditions: 'Property with a dinner poll for tomorrow',
    steps: ['Log in', 'Open the Polls tab'], expected: 'The poll is listed with its meal and options',
    data: 'meal=dinner', automation: 'e2e/polls.spec.js › E2E-POLL-01',
  },
  {
    id: 'E2E-POLL-02', module: 'Polls', title: 'Poll options come back as an array and recurring as a boolean',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Poll created', steps: ['GET /polls?property_id=…'],
    expected: 'options is ["Yes","No"] and recurring is true/false (not "[\"Yes\"]"/1)',
    data: 'n/a', automation: 'e2e/polls.spec.js › E2E-POLL-02',
  },
  {
    id: 'MNL-POLL-01', module: 'Polls', title: 'Resident answers a poll and owner sees the headcount',
    type: 'Manual', priority: 'P1', severity: 'High',
    preconditions: 'Poll open, resident account active',
    steps: ['Log in as resident', 'Tap Yes on the poll', 'Log in as owner', 'Open the poll'],
    expected: 'Headcount increases by one and the resident is listed as responding', data: 'n/a', automation: '',
  },

  // ── Operations ────────────────────────────────────────────────────────────
  {
    id: 'E2E-OPS-01', module: 'Operations', title: 'Complaints screen renders',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner logged in', steps: ['Open Complaints from More'], expected: 'Complaints list renders with its empty state or entries',
    data: 'n/a', automation: 'e2e/ops.spec.js › E2E-OPS-01',
  },
  {
    id: 'E2E-OPS-02', module: 'Operations', title: 'Documents screen renders with upload entry point',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner logged in', steps: ['Open Documents'], expected: 'Documents list and "Add hostel document" button are visible',
    data: 'n/a', automation: 'e2e/ops.spec.js › E2E-OPS-02',
  },
  {
    id: 'E2E-OPS-03', module: 'Operations', title: 'Expenses screen shows profit & loss summary',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner logged in', steps: ['Open Expenses'], expected: 'P&L header, income, expenses and net are displayed',
    data: 'n/a', automation: 'e2e/ops.spec.js › E2E-OPS-03',
  },
  {
    id: 'E2E-OPS-04', module: 'Operations', title: 'Visitors, deposits, ratings and SOS screens render',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner logged in', steps: ['Open each screen in turn'], expected: 'Each screen shows its heading and never the "Page Not Found" fallback',
    data: 'n/a', automation: 'e2e/ops.spec.js › E2E-OPS-04',
  },
  {
    id: 'E2E-OPS-06', module: 'Operations', title: 'Adding an expense updates the P&L',
    type: 'E2E', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner logged in', steps: ['Open Expenses', 'Tap Add expense', 'Enter title and amount', 'Save'],
    expected: 'Expense is stored and the P&L expense total increases', data: 'Electricity ₹1200', automation: 'e2e/ops.spec.js › E2E-OPS-06',
  },
  {
    id: 'MNL-OPS-01', module: 'Operations', title: 'Raise and resolve a complaint',
    type: 'Manual', priority: 'P1', severity: 'High',
    preconditions: 'Resident + owner accounts',
    steps: ['Resident raises a complaint', 'Owner opens Complaints', 'Move to In progress', 'Resolve with a note'],
    expected: 'Status moves open → in progress → resolved and the resident sees the resolution', data: 'category=Plumbing', automation: '',
  },
  {
    id: 'MNL-OPS-02', module: 'Operations', title: 'Broadcast a notice to all residents',
    type: 'Manual', priority: 'P2', severity: 'Medium',
    preconditions: 'Owner + resident accounts',
    steps: ['Owner posts a notice', 'Resident opens Notices'], expected: 'Notice appears for the resident with title and body',
    data: 'Water supply off 2-4pm', automation: '',
  },

  // ── API / platform ────────────────────────────────────────────────────────
  {
    id: 'SMK-01', module: 'API', title: 'Health endpoint responds',
    type: 'Smoke', priority: 'P1', severity: 'Critical',
    preconditions: 'Worker deployed', steps: ['GET /health'], expected: '200 with {"status":"ok"}', data: 'n/a',
    automation: 'smoketest/smoke.spec.js › SMK-01',
  },
  {
    id: 'REG-API-02', module: 'API', title: 'Register and login return a signed JWT',
    type: 'Regression', priority: 'P1', severity: 'Critical',
    preconditions: 'None', steps: ['POST /auth/register', 'POST /auth/login'],
    expected: 'Both return a three-part JWT; the user object never contains the password', data: 'new owner', automation: 'regression/api.regression.spec.js › REG-API-02',
  },
  {
    id: 'REG-API-03', module: 'API', title: 'Wrong password returns 401 without leaking the password',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'Existing owner', steps: ['POST /auth/login with a wrong password'], expected: '401 and the response body does not contain the password', data: 'WrongPass!1',
    automation: 'regression/api.regression.spec.js › REG-API-03',
  },
  {
    id: 'REG-API-04', module: 'API', title: 'Duplicate username is rejected',
    type: 'Regression', priority: 'P2', severity: 'Medium',
    preconditions: 'Existing username', steps: ['POST /auth/register with the same username'], expected: '409 (or 400) with a clear message', data: 'existing username',
    automation: 'regression/api.regression.spec.js › REG-API-04',
  },
  {
    id: 'REG-API-05', module: 'API', title: 'Boolean fields are real booleans',
    type: 'Regression', priority: 'P1', severity: 'High',
    preconditions: 'Newly registered user', steps: ['Inspect kyc_verified in the response'], expected: 'true/false, not 0/1 (a 0 breaks the Flutter models)', data: 'n/a',
    automation: 'regression/api.regression.spec.js › REG-API-05',
  },
  {
    id: 'REG-API-06', module: 'API', title: 'Tenants are isolated',
    type: 'Regression', priority: 'P1', severity: 'Critical',
    preconditions: 'Two owner accounts', steps: ['Create a property for each', 'List properties per owner'], expected: 'Each owner sees only their own property', data: 'tenant A / B',
    automation: 'regression/api.regression.spec.js › REG-API-06',
  },
  {
    id: 'MNL-API-01', module: 'API', title: 'Worker secrets are configured',
    type: 'Manual', priority: 'P1', severity: 'High',
    preconditions: 'Wrangler access', steps: ['Run wrangler secret list'], expected: 'JWT_SECRET and BETTER_AUTH_SECRET present; email key present if mail is live',
    data: 'n/a', automation: '',
  },

  // ── Platform / deployment ─────────────────────────────────────────────────
  {
    id: 'MNL-PLT-01', module: 'Platform', title: 'Custom domain serves the app over HTTPS',
    type: 'Manual', priority: 'P1', severity: 'Critical',
    preconditions: 'DNS CNAME in place', steps: ['Open https://hostelhub.mynilam.in', 'Check the certificate'],
    expected: '200 response, valid certificate for hostelhub.mynilam.in, http redirects to https', data: 'n/a', automation: '',
  },
  {
    id: 'MNL-PLT-02', module: 'Platform', title: 'Deep links work after a hard refresh',
    type: 'Manual', priority: 'P2', severity: 'Medium',
    preconditions: 'Deployed build', steps: ['Open https://hostelhub.mynilam.in/login directly in a new tab'],
    expected: 'App loads (SPA fallback) and routes to the login screen', data: 'n/a', automation: '',
  },
  {
    id: 'MNL-PLT-03', module: 'Platform', title: 'Mobile web layout is usable',
    type: 'Manual', priority: 'P2', severity: 'Medium',
    preconditions: 'Phone or devtools device emulation', steps: ['Open the app at 390px width', 'Check dashboard, inmates and forms'],
    expected: 'Two-column cards, no horizontal overflow, bottom nav reachable', data: '390x844', automation: 'playwright project web-mobile-chromium (smoke + e2e)',
  },
];

export const jiraProject = {
  key: process.env.JIRA_PROJECT_KEY || '',
  // Jira's stock issue types are Task/Story/Bug. Change to "Test" when the
  // project has a test-management app (Xray, Zephyr, …) installed.
  issueType: process.env.JIRA_ISSUE_TYPE || 'Task',
  labels: ['hostelhub', 'qa'],
};
