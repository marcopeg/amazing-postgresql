
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Generate seeding settings into a temporary table
CREATE TEMPORARY TABLE "seed_settings" ("doc" JSONB);
INSERT INTO "seed_settings" VALUES ('{
  "users_count": 10000,
  "artists_count": 10000,
  "events_count": 10000,

  "artists_id_max": 99999999,
  "events_id_max": 99999999,

  "users_performers_min": 0,
  "users_performers_max": 25,
  "users_gaps_perc": 0.3
}'::jsonb);

-- Generate random users (temporary table)
CREATE TEMPORARY TABLE "users_tmp" ("user_id" UUID, "prog_id" INTEGER);
INSERT INTO "users_tmp"
SELECT
  uuid_generate_v4() AS "user_id"
, "gs1" -- will be used to randomize the selection
FROM generate_series(1, (
  SELECT ("doc"->'users_count')::int FROM "seed_settings"
)) "gs1";

-- Generate random artists (temporary table)
CREATE TEMPORARY TABLE "artists_tmp" ("artist_id" TEXT, "prog_id" INTEGER);
INSERT INTO "artists_tmp"
SELECT 
  CONCAT('artist_', floor(random() * (
    SELECT ("doc"->'artists_id_max')::int FROM "seed_settings"
  ) + 1)::int) AS "artist_id"
, "gs1" -- will be used to randomize the selection
FROM generate_series(1, (
  SELECT ("doc"->'artists_count')::int FROM "seed_settings"
)) "gs1";

-- Generate random events
TRUNCATE "all_music_events_temp";
INSERT INTO "all_music_events_temp"
SELECT
    CONCAT('event_', floor(random() * (
      SELECT ("doc"->'events_id_max')::int FROM "seed_settings"
    ) + 1)::int) AS "event_id"
  , (
      SELECT (array['SE', 'NO', 'XX'])[floor(random() * 3 + 1)]
      WHERE "gs1" = "gs1"
    ) as "country_code"
FROM generate_series(1, (
  SELECT ("doc"->'events_count')::int FROM "seed_settings"
)) "gs1"
ON CONFLICT ON CONSTRAINT "all_music_events_temp_pkey" DO NOTHING;



--
-- INSERT RELATIONS
-- USERS > ARTIST
--

WITH
  "seed_info" AS (
  SELECT
    (
      SELECT ("doc"->'users_performers_min')::INT FROM "seed_settings"
    ) AS "following_min"
  , (
      SELECT ("doc"->'users_performers_max')::INT FROM "seed_settings"
    ) AS "following_max"
  , (
      (SELECT ("doc"->'users_performers_max')::INT FROM "seed_settings")
      +
      (SELECT ("doc"->'users_performers_max')::INT FROM "seed_settings")
      *
      (SELECT ("doc"->'users_gaps_perc')::REAL FROM "seed_settings")
    )::INT AS "following_random_pool"
  , (
      SELECT ("doc"->'artists_count')::int FROM "seed_settings"
    ) AS "prog_rand_max"
)
, "aggregated_values" AS (
  SELECT
    "user_id" AS "target",
    (
      SELECT array_agg("artist_id")
      FROM (
        SELECT "artist_id"
        FROM (
          SELECT (
            0 + trunc(random() * (SELECT "prog_rand_max" FROM "seed_info"))::int
          ) AS "prog_id"
          FROM generate_series(1, (SELECT "following_random_pool" FROM "seed_info"))
        ) AS "gs1"

        JOIN "artists_tmp" USING ("prog_id")
        WHERE "t1"."user_id" = "t1"."user_id"

        LIMIT (
          floor(random() * ((
            SELECT "following_max" FROM "seed_info"
          ) - (
            SELECT "following_min" FROM "seed_info"
          ) + 1) + (
            SELECT "following_min" FROM "seed_info"
          ))
        )
      ) AS "sq1"
    ) AS "values"
  FROM "users_tmp" AS "t1"
)
, "insert_values" AS (
  INSERT INTO "public"."users_performers"
  SELECT
    "target" AS "user_id"
  , "value" AS "artist_id"
  FROM "aggregated_values", unnest("values") AS "value"
  -- GROUP BY "user_id_1", "user_id_2"
  ON CONFLICT ON CONSTRAINT "users_performers_pkey"
  DO NOTHING
  RETURNING *
)
-->> Output >>
SELECT COUNT(*) AS "inserted_users_artists"
FROM "insert_values";

























-- Populate relation "UsersPerformers"
-- TRUNCATE "users_performers";
-- INSERT INTO "users_performers"
-- SELECT
--   (
--     SELECT "user_id" 
--     FROM "users_tmp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "user_id",
--   (
--     SELECT "artist_id" 
--     FROM "artists_tmp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "artist_id"
-- FROM generate_series(1, 1000) "gs1"
-- ON CONFLICT ON CONSTRAINT "users_performers_pkey"
-- DO NOTHING;

-- Populate relation "EventsPerformers"
-- TRUNCATE "events_performers_temp";
-- INSERT INTO "events_performers_temp"
-- SELECT
--   (
--     SELECT "event_id" 
--     FROM "all_music_events_temp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "event_id",
--   (
--     SELECT "artist_id" 
--     FROM "artists_tmp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "artist_id"
-- FROM generate_series(1, 1000) "gs1"
-- ON CONFLICT ON CONSTRAINT "events_performers_temp_event_id_artist_id"
-- DO NOTHING;

-- Populate relation "SentEvents"
-- TRUNCATE "users_sent_events";
-- INSERT INTO "users_sent_events"
-- SELECT
--   (
--     SELECT "user_id" 
--     FROM "users_tmp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "user_id",
--   (
--     SELECT "event_id" 
--     FROM "all_music_events_temp" 
--     WHERE "gs1" = "gs1" 
--     ORDER BY random()
--     LIMIT 1 
--   ) AS "event_id"
-- FROM generate_series(1, 1000) "gs1"
-- ON CONFLICT ON CONSTRAINT "users_sent_events_pkey"
-- DO NOTHING;

-- Cleanup
DROP TABLE "users_tmp";
DROP TABLE "artists_tmp";
DROP EXTENSION IF EXISTS "uuid-ossp";