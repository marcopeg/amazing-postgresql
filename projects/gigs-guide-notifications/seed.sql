
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Generate seeding settings into a temporary table
CREATE TEMPORARY TABLE "seed_settings" ("doc" JSONB);
INSERT INTO "seed_settings" VALUES ('{
  "users_count": 100,
  "artists_count": 1000,
  "events_count": 50000,

  "artists_id_max": 99999999,
  "events_id_max": 99999999,

  "users_performers_min": 0,
  "users_performers_max": 50,

  "events_performers_min": 0,
  "events_performers_max": 8,
  
  "sent_events_min": 0,
  "sent_events_max": 25,

  "users_gaps_perc": 0.3,
  "events_gaps_perc": 0.3
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








--
-- INSERT RELATIONS
-- ARTIST > EVENT
--
WITH
  "seed_info" AS (
  SELECT
    (
      SELECT ("doc"->'events_performers_min')::INT FROM "seed_settings"
    ) AS "following_min"
  , (
      SELECT ("doc"->'events_performers_max')::INT FROM "seed_settings"
    ) AS "following_max"
  , (
      (SELECT ("doc"->'events_performers_max')::INT FROM "seed_settings")
      +
      (SELECT ("doc"->'events_performers_max')::INT FROM "seed_settings")
      *
      (SELECT ("doc"->'events_gaps_perc')::REAL FROM "seed_settings")
    )::INT AS "following_random_pool"
  , (
      SELECT ("doc"->'artists_count')::int FROM "seed_settings"
    ) AS "prog_rand_max"
)
, "aggregated_values" AS (
  SELECT
    "event_id" AS "target",
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
        WHERE "t1"."event_id" = "t1"."event_id"

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
  FROM "all_music_events_temp" AS "t1"
)
, "insert_values" AS (
  INSERT INTO "public"."events_performers_temp"
  SELECT
    "target" AS "event_id"
  , "value" AS "artist_id"
  FROM "aggregated_values", unnest("values") AS "value"
  ON CONFLICT ON CONSTRAINT "events_performers_temp_event_id_artist_id"
  DO NOTHING
  RETURNING *
)
-->> Output >>
SELECT COUNT(*) AS "inserted_events_artists"
FROM "insert_values"
;


















--
-- INSERT RELATIONS SENT EVENTS
-- USER > EVENT
--
WITH
  "seed_info" AS (
  SELECT
    (
      SELECT ("doc"->'sent_events_min')::INT FROM "seed_settings"
    ) AS "following_min"
  , (
      SELECT ("doc"->'sent_events_max')::INT FROM "seed_settings"
    ) AS "following_max"
  , (
      (SELECT ("doc"->'sent_events_max')::INT FROM "seed_settings")
      +
      (SELECT ("doc"->'sent_events_max')::INT FROM "seed_settings")
      *
      (SELECT ("doc"->'events_gaps_perc')::REAL FROM "seed_settings")
    )::INT AS "following_random_pool"
  , (
      SELECT ("doc"->'users_count')::int FROM "seed_settings"
    ) AS "prog_rand_max"
)
, "aggregated_values" AS (
  SELECT
    "event_id" AS "target",
    (
      SELECT array_agg("user_id")
      FROM (
        SELECT "user_id"
        FROM (
          SELECT (
            0 + trunc(random() * (SELECT "prog_rand_max" FROM "seed_info"))::int
          ) AS "prog_id"
          FROM generate_series(1, (SELECT "following_random_pool" FROM "seed_info"))
        ) AS "gs1"

        JOIN "users_tmp" USING ("prog_id")
        WHERE "t1"."event_id" = "t1"."event_id"

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
  FROM "all_music_events_temp" AS "t1"
)
, "insert_values" AS (
  INSERT INTO "public"."users_sent_events"
  SELECT
    "value"::uuid AS "user_id"
  , "target" AS "event_id"
  FROM "aggregated_values", unnest("values") AS "value"
  ON CONFLICT ON CONSTRAINT "users_sent_events_pkey"
  DO NOTHING
  RETURNING *
)
-->> Output >>
SELECT COUNT(*) AS "inserted_events_artists"
FROM "insert_values"
;














-- Cleanup
DROP TABLE "users_tmp";
DROP TABLE "artists_tmp";
DROP EXTENSION IF EXISTS "uuid-ossp";