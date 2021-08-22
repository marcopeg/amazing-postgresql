
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Generate seeding settings into a temporary table
CREATE TEMPORARY TABLE "seed_settings" ("doc" JSONB);
INSERT INTO "seed_settings" VALUES ('{
  "users_count": 5000000
}'::jsonb);

-- Generate random users with serial IDs
INSERT INTO "users_with_ids" ("uname")
SELECT CONCAT('u', "gs1")
FROM generate_series(1, (
  SELECT ("doc"->'users_count')::int FROM "seed_settings"
)) "gs1";

-- Generate random users with UUIDs
INSERT INTO "users_with_uuids" ("uname")
SELECT CONCAT('u', "gs1")
FROM generate_series(1, (
  SELECT ("doc"->'users_count')::int FROM "seed_settings"
)) "gs1";
