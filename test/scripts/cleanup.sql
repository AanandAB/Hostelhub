-- Purge data created by the automated suites.
-- Run each statement separately (wrangler d1 execute takes one statement at a time):
--   cd workers && npx wrangler d1 execute hostelhub --remote --command "$(sed -n '5p' ../test/scripts/cleanup.sql)"
--
-- Or pipe the whole file on a local DB:
--   npx wrangler d1 execute hostelhub --local --file=../test/scripts/cleanup.sql

DELETE FROM poll_responses WHERE poll_id IN (SELECT id FROM polls WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test')));
DELETE FROM polls      WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM notices    WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM complaints WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM payments   WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM inmates    WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM rooms      WHERE property_id IN (SELECT id FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test'));
DELETE FROM properties WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test');
DELETE FROM subscriptions WHERE owner_id IN (SELECT id FROM users WHERE email LIKE '%@hostelhub.test');
DELETE FROM users      WHERE email LIKE '%@hostelhub.test';
