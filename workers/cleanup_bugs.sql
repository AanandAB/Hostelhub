-- Clean up orphaned test records from bug-diagnosis (empty property_id/owner_id)
-- plus the throwaway "Diag Hostel" / "bugdiag" / "rahul" test data.
DELETE FROM payments WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM complaints WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM polls WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM deposits WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM inmates WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM rooms WHERE property_id IS NULL OR property_id = '' OR property_id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM properties WHERE owner_id IS NULL OR owner_id = '' OR owner_id = '197609' OR id = 'a6cad6e8-29f0-4b40-90b3-cb51c3706e4c';
DELETE FROM users WHERE username = 'bugdiag' OR username LIKE 'rahul%';
