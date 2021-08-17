

WITH
  -- collects a few settings for the data generation
  "limits" AS (
    SELECT
      -- 70 to 90% of users
      (
        (SELECT COUNT(*) FROM "public"."users")::int
        *
        (SELECT floor(random() * (90 - 70 + 1) + 70)::int) / 100
      ) AS "left_users_limit"

      -- Max amount of followers
    , 0 AS "following_limit_min"
    , 5 AS "following_limit_max"
  )

  -- produce a randomized list of "follow"
, "following" AS (
    SELECT
      -- left user
      "id" 

      -- right users, the list of "who to follow"
      -- create an array of randomic users to follow
    , (
        SELECT array_agg("id")
        FROM (
          SELECT "id" FROM "public"."users" 

          -- enforce random values
          -- and make sure a user doesn't follow itself
          WHERE "t1" = "t1"
            AND "id" != "t1"."id"
          ORDER BY random()

          -- limit the amount to a configurable range
          LIMIT (
            SELECT
              floor(random() * ((
                SELECT "following_limit_max" FROM "limits"
              ) - (
                SELECT "following_limit_min" FROM "limits"
              ) + 1) + (
                SELECT "following_limit_min" FROM "limits"
              ))
            WHERE "t1" = "t1"
          )
        ) AS "sq1"
      ) AS "following"

    FROM "public"."users" AS "t1"
    ORDER BY random()
    LIMIT (SELECT "left_users_limit" FROM "limits")
  )
, "users_follows_source" AS (
  SELECT
    "id" AS "user_id_1"
  , "user_id_2" 
  FROM "following", unnest("following") AS "user_id_2"
)

select * from "users_follows_source";

