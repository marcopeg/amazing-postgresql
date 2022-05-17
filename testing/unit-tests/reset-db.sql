-- Drop existing connections to the database:
-- https://stackoverflow.com/a/63493002/1308023
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'test-db'
  AND pid <> pg_backend_pid();

-- Recreate the target database:
DROP DATABASE IF EXISTS "test-db";
CREATE DATABASE "test-db";



