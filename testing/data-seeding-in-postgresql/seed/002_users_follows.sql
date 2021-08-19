WITH 
  -- SEED CONFIGURATION AND STATIC DATA
  -- (we use this as source for dictionary-based randomic selections)
 "seed_config"("doc") AS ( VALUES ('{
    "users_gaps_perc": 0.2,
    "followers_limit": 0.25,
    "following_limit_min": 0,
    "following_limit_max": 25
  }'::json))

  -- COLLECTS METRICS FROM THE CURRENT DATA SET
  -- In order to apply smart and fast randomization, we need to collect
  -- a few information from the "users" table:
, "seed_metrics" AS (
  -- Compute the total amount of rows in the "users" table:
  -- (we can't use estimation techniques here as the VACUUM hasn't passed during seed)
  SELECT
    (
      SELECT COUNT(*) FROM "public"."users"
    ) AS "rows_count"
  -- Calculate (and cache) the data-space of existing users IDs.
  -- Those will be the margins for the randomization of a user's ID.
  , (
    SELECT min("id") FROM "public"."users"
  ) AS "id_rand_min"
  , (
    SELECT max("id") - min("id") FROM "public"."users"
  ) AS "id_rand_max"
)

  -- REFINED VARIABLES FOR THE SEEDING
  -- We use this intermediate query to simplify the real randomization ones.
  -- In here we pre-calculate some parameters out of the JSON configuration
  -- and the metrics that we have already collected.
, "seed_info" AS (
  SELECT
  -- Calculate max amount of followers to iterate:
    (
      (SELECT "rows_count" FROM "seed_metrics") * 
      (SELECT ("doc"->'followers_limit')::TEXT::REAL FROM "seed_config")
    )::INT AS "followers_limit"

  -- Calculate the follower's randomic pool size based on the
  -- estimated gaps between the idexed ID:
  -- (tot + tot * buffer)
  , (
      (SELECT "rows_count" FROM "seed_metrics") * 
      (SELECT ("doc"->'followers_limit')::TEXT::REAL FROM "seed_config")
      +
      (SELECT "rows_count" FROM "seed_metrics") * 
      (SELECT ("doc"->'followers_limit')::TEXT::REAL FROM "seed_config")
      *
      (SELECT ("doc"->'users_gaps_perc')::TEXT::REAL FROM "seed_config")
    )::INT AS "followers_random_pool"

  -- Export the min/max amount of users to follow
  , (
      SELECT ("doc"->'following_limit_min')::TEXT::INT FROM "seed_config"
    ) AS "following_limit_min"
  , (
      SELECT ("doc"->'following_limit_max')::TEXT::INT FROM "seed_config"
    ) AS "following_limit_max"

  -- Calculate the following's randomic pool size based on the
  -- estimated gaps between the idexed ID:
  -- (tot + tot * buffer)
  , (
      (SELECT ("doc"->'following_limit_max')::TEXT::INT FROM "seed_config")
      +
      (SELECT ("doc"->'following_limit_max')::TEXT::INT FROM "seed_config")
      *
      (SELECT ("doc"->'users_gaps_perc')::TEXT::REAL FROM "seed_config")
    )::INT AS "following_random_pool"
)

  -- RANDOMIZED POOL OF FOLLOWERS
  -- Here we try to select a given portion of the "users" while randomizing
  -- the selection. We are going to approximate this amounts in order to obtain
  -- a fast randomization by generating a given amount of probable user IDs.
  -- Normally, this technique yelds slightly less amounts of data compared to
  -- the desired amount, and it is difficult to reach the 100% of the dataset.
, "randomized_users" AS (
    -- Generate a list of randomic userIDs
    SELECT "id" FROM (
      -- Generate a random userID assigned to this 
      SELECT 
        (SELECT "id_rand_min" FROM "seed_metrics") 
        + trunc(random() * (SELECT "id_rand_max" FROM "seed_metrics"))::int 
        AS "id"

      -- Generate a dataset that extends to the maximum number of possible following profiles.
      FROM generate_series(1, (SELECT "followers_random_pool" FROM "seed_info"))
    ) AS "r"

    -- Join with the real users so to exclude all the randomic IDs that
    -- don't match any record in the "users" table.
    -- Based on the gaps between the IDs, this JOIN could exclude many of the
    -- randomized IDs. That's why we need a buffer around the maximum number
    -- of possible following profile.
    JOIN "public"."users" USING ("id")

    -- Removed duplicates, but also forces the sorting of the data
    GROUP BY 1

    -- Limit the amount of following users to a randomic value using 
    -- the range configured in the JSON document.
    LIMIT (SELECT "followers_limit" FROM "seed_info")
  )


  -- produce a randomized list of "follow"
, "users_follows_data" AS (
    SELECT
      -- left user, the follower
      "id" 

      -- right users, the list of "who to follow"
      -- create an array of randomic users to follow
    , (
        SELECT array_agg("id")  
        FROM (
          -- Generate a list of randomic userIDs
          SELECT "id" FROM (
            -- Generate a random userID assigned to this 
            SELECT 
              (
                (SELECT "id_rand_min" FROM "seed_metrics") + trunc(random() * (SELECT "id_rand_max" FROM "seed_metrics"))::int 
              ) AS "id"

            -- Generate a dataset that extends to the maximum number of possible following profiles.
            FROM generate_series(1, (SELECT "following_random_pool" FROM "seed_info"))
          ) AS "r"

          -- Join with the real users so to exclude all the randomic IDs that
          -- don't match any record in the "users" table.
          -- Based on the gaps between the IDs, this JOIN could exclude many of the
          -- randomized IDs. That's why we need a buffer around the maximum number
          -- of possible following profile.
          JOIN "public"."users" USING ("id")
          WHERE "t1"."id" = "t1"."id"

          -- Limit the amount of following users to a randomic value using 
          -- the range configured in the JSON document.
          LIMIT (
            floor(random() * ((
              SELECT "following_limit_max" FROM "seed_info"
            ) - (
              SELECT "following_limit_min" FROM "seed_info"
            ) + 1) + (
              SELECT "following_limit_min" FROM "seed_info"
            ))
          )
        ) AS "sq1"
      ) AS "following"

    -- Randomize the users in the first table
    FROM "randomized_users" AS "t1"
  )

, "insert_users_follows" AS (
  INSERT INTO "public"."users_follows"
  SELECT
    "id" AS "user_id_1"
  , "user_id_2" 
  FROM "users_follows_data", unnest("following") AS "user_id_2"
  GROUP BY "user_id_1", "user_id_2"
  ON CONFLICT ON CONSTRAINT "users_follows_pkey"
  DO NOTHING
  RETURNING *
)

-->> Output >>
SELECT * FROM "users_follows_data" 
LIMIT 10
;


