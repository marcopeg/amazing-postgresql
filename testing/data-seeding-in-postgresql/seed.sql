WITH 
  -- SEED CONFIGURATION AND STATIC DATA
  -- (we use this as source for dictionary-based randomic selections)
 "seed_config"("doc") AS ( VALUES ('{
    "users_tot": 10000,
    "user_age_min": 18,
    "user_age_max": 80,
    "user_rand_min": 9999,
    "user_rand_max": 999999,
    "usernames": [
      "Luke",
      "Leia",
      "Darth",
      "Han",
      "Obi-One",
      "Chube",
      "Yoda",
      "Jabba",
      "Kylo",
      "Padme",
      "Jar-Jar",
      "Ray",
      "C-3PO",
      "R2-D2"
    ],
    "modifiers": [
      "Happy",
      "Glorious",
      "Sad",
      "Fortunate",
      "Unluky",
      "Lonely",
      "Ferocious"
    ],
    "countries": ["it","us","fr","es","de","se","dk","no"]
  }'::json))

  -- GENERATED USERS DATA
  -- this is where we generate the data-set, with random values and
  -- also some support data structures from the static data
, "generated_users_data" AS (
    SELECT
      "id"

    -- Get a random age using the min/max from configuration
    , (
        SELECT floor(random() * ((
          SELECT ("doc"->'user_age_max')::TEXT::INT FROM "seed_config"
        ) - (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ) + 1) + (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ))::int
        WHERE "id" = "id"
      ) AS "age"

    -- Casting static data to PostgreSQL's ARRAY will
    -- facilitate a lot the randomization of dictionary-based values
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'usernames')) FROM "seed_config"
      ) AS "usernames_values"
    , (
        SELECT json_array_length("doc"->'usernames') FROM "seed_config"
      ) AS "usernames_length"
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'modifiers')) FROM "seed_config"
      ) AS "modifiers_values"
    , (
        SELECT json_array_length("doc"->'modifiers') FROM "seed_config"
      ) AS "modifiers_length"
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'countries')) FROM "seed_config"
      ) AS "countries_values"
    , (
        SELECT json_array_length("doc"->'countries') FROM "seed_config"
      ) AS "countries_length"
    
    -- Generate a serie of rows as big as the configuration requires:
    FROM generate_series(1, (
      SELECT ("doc" -> 'users_tot')::TEXT::INT FROM "seed_config"
    )) "id"
  )

  -- INSERT USERS VALUES
  -- we can finally generate a dataset that can populate our "users" table:
  -- in here we we use the generated randomic values, plus a bunch of
  -- cool functions, to generate realistic usernames
, "insert_users_values" AS (
    SELECT
      "id"

      -- Age
      -- (reporting from the previous query)
    , "age"

      -- Username 
      -- (random value from a list + year of birth)
    , (
        CONCAT(
          -- Random value from "modifiers"
          (
            SELECT ("modifiers_values")[floor(random() * ("modifiers_length") + 1)]
            WHERE "id" = "id"
          ),
          -- Random value from "usernames"
          '_',
          (
            SELECT ("usernames_values")[floor(random() * ("usernames_length") + 1)]
            WHERE "id" = "id"
          ),
          -- Add the last 2 digits from the Year of Birth
          -- (yeah, this is just to show off)
          '_',
          TO_CHAR(
            NOW() - INTERVAL '1y' * "age"
            ,'YY'
          ),
          -- Add another randomization factor to the username to allow for
          -- a very large amount of items in the table
          '_',
          (
            SELECT floor(random() * ((
              SELECT ("doc"->'user_rand_max')::TEXT::INT FROM "seed_config"
            ) - (
              SELECT ("doc"->'user_rand_min')::TEXT::INT FROM "seed_config"
            ) + 1) + (
              SELECT ("doc"->'user_rand_min')::TEXT::INT FROM "seed_config"
            ))::int
            WHERE "id" = "id"
          )
        )
      ) AS "uname"

    -- Year of Birth
    -- (current time minus random age)  
    , DATE_TRUNC(
        'day',
        NOW() - INTERVAL '1y' * "age"
    ) AS "bday"

    -- Country
    -- (random value from a list)
    , (
        SELECT ("countries_values")[floor(random() * ("countries_length") + 1)]
        WHERE "id" = "id"
      ) AS "country"

    FROM "generated_users_data"
  )

  -- INSERT USERS
  -- Here we run the real insert, even with a big dictionary we will encounter
  -- duplicated usernames (there is a UNIQUE constraint on the table)
  -- so it is best to just ignore duplicates
  --
  -- In order to create millions of users, we have to choose:
  -- 1. Increase the size of the dictionary (modifiers and usernames)
  -- 2. Remove the UNIQUE constraint
  -- 3. Add another randomization factor to the username
, "insert_users" AS (
  INSERT INTO "public"."users" ("age", "uname", "bday", "country")
  SELECT "age", "uname", "bday", "country" FROM "insert_users_values"
  ON CONFLICT ON CONSTRAINT "users_uname_key"
  DO NOTHING
  RETURNING *
)

-->> Output >>
SELECT * FROM "insert_users" LIMIT 10;





WITH 
  -- SEED CONFIGURATION AND STATIC DATA
  -- (we use this as source for dictionary-based randomic selections)
 "seed_config"("doc") AS ( VALUES ('{
    "followers_limit_min": 50,
    "followers_limit_max": 75,
    "following_limit_min": 1,
    "following_limit_max": 10
  }'::json))

  -- produce a randomized list of "follow"
, "users_follows_data" AS (
    SELECT
      -- left user
      "id" 

      -- right users, the list of "who to follow"
      -- create an array of randomic users to follow
    , (
        SELECT array_agg("id")
        FROM (
          SELECT "id" FROM "public"."users" AS "t2"

          -- enforce random values
          -- and make sure a user doesn't follow itself
          WHERE "t1"."id" != "t2"."id"
            AND "t1" = "t1"
          ORDER BY random()

          -- limit the amount to a configurable range
          LIMIT (
            SELECT
              floor(random() * ((
                SELECT ("doc"->'following_limit_max')::TEXT::INT FROM "seed_config"
              ) - (
                SELECT ("doc"->'following_limit_min')::TEXT::INT FROM "seed_config"
              ) + 1) + (
                SELECT ("doc"->'following_limit_min')::TEXT::INT FROM "seed_config"
              ))
            WHERE "t1" = "t1"
          )
        ) AS "sq1"
      ) AS "following"

    FROM "public"."users" AS "t1"
    WHERE "id" = "id"
    ORDER BY random()

    -- Limit the amount of following users to a percentage of the
    -- total amount of users.
    LIMIT (
      (SELECT COUNT(*) FROM "public"."users")::int
      *
      -- The percentage itself is randomized between two margins
      -- all of this comes from the JSON
      (SELECT floor(random() * ((
        SELECT ("doc"->'followers_limit_max')::TEXT::INT FROM "seed_config"
      ) - (
        SELECT ("doc"->'followers_limit_min')::TEXT::INT FROM "seed_config"
      ) + 1) + (
        SELECT ("doc"->'followers_limit_min')::TEXT::INT FROM "seed_config"
      ))::int) / 100
    )
  )

, "insert_users_follows" AS (
  INSERT INTO "public"."users_follows"
  SELECT
    "id" AS "user_id_1"
  , "user_id_2" 
  FROM "users_follows_data", unnest("following") AS "user_id_2"
  RETURNING *
)

-->> Output >>
SELECT * FROM "users_follows_data" LIMIT 10;
