-- Add the missing visitor columns (visiting_inmate_name, in_time, out_time).
ALTER TABLE visitors ADD COLUMN visiting_inmate_name TEXT NOT NULL DEFAULT '';
ALTER TABLE visitors ADD COLUMN in_time TEXT;
ALTER TABLE visitors ADD COLUMN out_time TEXT;
