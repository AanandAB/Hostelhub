#!/usr/bin/env node
/**
 * Builds the QA deliverables from testcases.data.js:
 *
 *   HostelHub_TestCases.xlsx  — Summary, Test Cases and Jira Import sheets
 *   jira-import.csv           — Issues → Import in Jira (CSV), one row per case
 *
 * Usage: npm run testcases
 */
import ExcelJS from 'exceljs';
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { testCases, jiraProject } from './testcases.data.js';
import { env } from '../config/env.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const xlsxPath = path.join(here, 'HostelHub_TestCases.xlsx');
const csvPath = path.join(here, 'jira-import.csv');

const HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2F4FE0' } };
const HEADER_FONT = { bold: true, color: { argb: 'FFFFFFFF' }, size: 11 };
const ZEBRA = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF3F5FF' } };

const PRIORITY_COLOR = { P1: 'FFFFE0E0', P2: 'FFFFF6E0', P3: 'FFEFFFE0' };
const TYPE_COLOR = { Smoke: 'FFE3F7E8', E2E: 'FFE6EEFF', Regression: 'FFFFF0E6', Manual: 'FFF0F0F0' };

const stepsCell = (steps) => steps.map((s, i) => `${i + 1}. ${s}`).join('\n');

const jiraDescription = (tc) => [
  `h3. ${tc.title}`,
  '',
  `*Test case ID:* ${tc.id}`,
  `*Module:* ${tc.module}`,
  `*Type:* ${tc.type}`,
  `*Priority:* ${tc.priority}`,
  `*Severity:* ${tc.severity}`,
  '',
  '*Preconditions:*',
  tc.preconditions,
  '',
  '*Steps:*',
  ...tc.steps.map((s, i) => `# ${s}`),
  '',
  '*Expected result:*',
  tc.expected,
  '',
  `*Test data:* ${tc.data || 'n/a'}`,
  tc.automation ? `*Automated by:* ${tc.automation}` : '*Automated by:* manual check',
].join('\n');

const jiraLabels = (tc) => [...jiraProject.labels, tc.type.toLowerCase(), tc.priority.toLowerCase()].join(' ');

// ── Workbook ────────────────────────────────────────────────────────────────
const wb = new ExcelJS.Workbook();
wb.creator = 'HostelHub QA';
wb.created = new Date();

const addHeader = (ws, headers) => {
  ws.addRow(headers);
  const row = ws.getRow(1);
  row.eachCell((cell) => {
    cell.fill = HEADER_FILL;
    cell.font = HEADER_FONT;
    cell.alignment = { vertical: 'middle', horizontal: 'left', wrapText: true };
  });
  row.height = 24;
  ws.views = [{ state: 'frozen', ySplit: 1 }];
};

const styleTable = (ws, rowCount, widths) => {
  for (let r = 2; r <= rowCount; r += 1) {
    const row = ws.getRow(r);
    row.eachCell((cell) => {
      cell.alignment = { vertical: 'top', wrapText: true };
      cell.border = { bottom: { style: 'hair', color: { argb: 'FFDDDDDD' } } };
      if (r % 2 === 0) cell.fill = ZEBRA;
    });
  }
  ws.columns.forEach((col, i) => { col.width = widths[i] || 20; });
  ws.autoFilter = { from: 'A1', to: { row: 1, column: widths.length } };
};

// ── Sheet 1: Summary ────────────────────────────────────────────────────────
const summary = wb.addWorksheet('Summary', { properties: { tabColor: { argb: 'FF2F4FE0' } } });
summary.columns = [{ width: 34 }, { width: 22 }, { width: 22 }, { width: 22 }];
summary.addRow(['HostelHub — Test Case Catalogue']).font = { size: 16, bold: true };
summary.addRow(['Generated', new Date().toISOString().replace('T', ' ').slice(0, 19) + ' UTC']);
summary.addRow(['Web under test', env.webBaseUrl]);
summary.addRow(['API under test', env.apiBaseUrl]);
summary.addRow(['Total test cases', testCases.length]);
summary.addRow([]);

const countBy = (key) => testCases.reduce((acc, tc) => ({ ...acc, [tc[key]]: (acc[tc[key]] || 0) + 1 }), {});

summary.addRow(['By type', 'Count']).font = { bold: true };
Object.entries(countBy('type')).forEach(([k, v]) => summary.addRow([k, v]));
summary.addRow(['Manual (not automated)', testCases.filter((t) => !t.automation).length]);
summary.addRow([]);

summary.addRow(['By priority', 'Count']).font = { bold: true };
Object.entries(countBy('priority')).sort().forEach(([k, v]) => summary.addRow([k, v]));
summary.addRow([]);

summary.addRow(['By module', 'Count']).font = { bold: true };
Object.entries(countBy('module')).sort().forEach(([k, v]) => summary.addRow([k, v]));
summary.addRow([]);

summary.addRow(['How to use', '']).font = { bold: true };
[
  'Test Cases sheet: full detail (steps, expected result, automation link).',
  'Jira Import sheet + jira-import.csv: upload in Jira → Issues → Import issues from CSV.',
  'Map "Summary", "Issue Type", "Priority", "Labels", "Description" and "External issue ID" when prompted.',
  'External issue ID is the test case ID, so re-importing updates instead of duplicating.',
].forEach((line) => summary.addRow(['', line]));

// ── Sheet 2: Test Cases ─────────────────────────────────────────────────────
const ws = wb.addWorksheet('Test Cases', { properties: { tabColor: { argb: 'FF00C2A8' } } });
const headers = [
  'Test Case ID', 'Module', 'Title', 'Type', 'Priority', 'Severity',
  'Preconditions', 'Steps', 'Expected Result', 'Test Data', 'Automated By', 'Automation Status',
];
addHeader(ws, headers);

testCases.forEach((tc) => {
  const row = ws.addRow([
    tc.id, tc.module, tc.title, tc.type, tc.priority, tc.severity,
    tc.preconditions, stepsCell(tc.steps), tc.expected, tc.data || 'n/a',
    tc.automation || '—', tc.automation ? 'Automated' : 'Manual',
  ]);
  row.getCell(1).font = { bold: true };
  const typeCell = row.getCell(4);
  typeCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: TYPE_COLOR[tc.type] || 'FFFFFFFF' } };
  const prioCell = row.getCell(5);
  prioCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: PRIORITY_COLOR[tc.priority] || 'FFFFFFFF' } };
  prioCell.font = { bold: true };
});
styleTable(ws, testCases.length + 1, [13, 14, 42, 11, 9, 10, 30, 52, 52, 20, 46, 14]);

// ── Sheet 3: Jira Import ────────────────────────────────────────────────────
const jira = wb.addWorksheet('Jira Import', { properties: { tabColor: { argb: 'FFFFB020' } } });
addHeader(jira, ['External issue ID', 'Summary', 'Issue Type', 'Priority', 'Labels', 'Description', 'Test Case ID', 'Module']);
testCases.forEach((tc) => {
  const row = jira.addRow([
    tc.id,
    `${tc.id} — ${tc.title}`,
    jiraProject.issueType,
    tc.priority === 'P1' ? 'Highest' : tc.priority === 'P2' ? 'High' : 'Medium',
    jiraLabels(tc),
    jiraDescription(tc),
    tc.id,
    tc.module,
  ]);
  row.getCell(1).font = { bold: true };
});
styleTable(jira, testCases.length + 1, [16, 52, 12, 10, 30, 70, 13, 14]);

await wb.xlsx.writeFile(xlsxPath);

// ── CSV for Jira ────────────────────────────────────────────────────────────
const esc = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`;
const csvRows = [
  ['External issue ID', 'Summary', 'Issue Type', 'Priority', 'Labels', 'Description', 'Test Case ID', 'Module'].map(esc).join(','),
  ...testCases.map((tc) => [
    tc.id,
    `${tc.id} — ${tc.title}`,
    jiraProject.issueType,
    tc.priority === 'P1' ? 'Highest' : tc.priority === 'P2' ? 'High' : 'Medium',
    jiraLabels(tc),
    jiraDescription(tc),
    tc.id,
    tc.module,
  ].map(esc).join(',')),
];
writeFileSync(csvPath, csvRows.join('\r\n'), 'utf8');

const automated = testCases.filter((t) => t.automation).length;
console.log(`✔ ${testCases.length} test cases written`);
console.log(`  ${xlsxPath}`);
console.log(`  ${csvPath}`);
console.log(`  automated: ${automated} · manual: ${testCases.length - automated}`);
