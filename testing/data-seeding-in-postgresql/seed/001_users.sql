WITH 
  -- SEED CONFIGURATION AND STATIC DATA
  -- (we use this as source for dictionary-based randomic selections)
  "seed_config"("doc") AS ( VALUES ('{
    "users_tot": 50000,
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
  -- This is where we generate the data-set, with random values and
  -- also some support data structures from the static data
  -- It may be a bit of a waste of memory to spread the dictionaries
  -- in each row, but the queries in the next CTE are much more readable this way!
, "generated_users_data" AS (
    SELECT
    -- Get a random age using the min/max from configuration:
    -- random() * (MAX - MIN + 1) + MIN)
      (
        floor(random() * ((
          SELECT ("doc"->'user_age_max')::TEXT::INT FROM "seed_config"
        ) - (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ) + 1) + (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ))
      )::INT AS "age"

    -- Casting static data to PostgreSQL's ARRAY will
    -- facilitate a lot the randomization of dictionary-based values
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'usernames')) FROM "seed_config"
      ) AS "usernames_values"
    , (
        SELECT json_array_length("doc"->'usernames') FROM "seed_config"
      )::INT AS "usernames_length"
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'modifiers')) FROM "seed_config"
      ) AS "modifiers_values"
    , (
        SELECT json_array_length("doc"->'modifiers') FROM "seed_config"
      )::INT AS "modifiers_length"
    , (
        SELECT ARRAY(SELECT json_array_elements_text("doc"->'countries')) FROM "seed_config"
      ) AS "countries_values"
    , (
        SELECT json_array_length("doc"->'countries') FROM "seed_config"
      )::INT AS "countries_length"

    -- We can also extract some other information from the JSON so that
    -- it become easily available to further manipulation:
    , (
        SELECT ("doc"->'user_rand_min')::TEXT::INT FROM "seed_config"
      )::INT AS "user_rand_min"
    , (
        SELECT ("doc"->'user_rand_max')::TEXT::INT FROM "seed_config"
      )::INT AS "user_rand_max"
    
    -- Generate a serie of rows as big as the configuration requires:
    FROM generate_series(1, (
      SELECT ("doc" -> 'users_tot')::TEXT::INT FROM "seed_config"
    ))
  )

  -- INSERT USERS VALUES
  -- we can finally generate a dataset that can populate our "users" table:
  -- in here we we use the generated randomic values, plus a bunch of
  -- cool functions, to generate realistic usernames
, "insert_users_values" AS (
    SELECT
      -- Age
      -- (reporting from the previous query)
      "age"

      -- Username 
      -- (random value from a list + year of birth)
    , (
        CONCAT(
          -- Random username as `{modifier}_{username}_{YearOfBirth}_{randomization}`
          ("modifiers_values")[floor(random() * ("modifiers_length") + 1)],
          '_',
          ("usernames_values")[floor(random() * ("usernames_length") + 1)],
          -- Add the last 2 digits from the Year of Birth
          -- (yeah, this is just to show off)
          '_',
          TO_CHAR(NOW() - INTERVAL '1y' * "age" ,'YY'),
          -- Add another randomization factor to the username to allow for
          -- a very large amount of items in the table without conflicts
          '_',
          floor(random() * ("user_rand_max" - "user_rand_min" + 1) + "user_rand_min")
        )
      ) AS "uname"

    -- Year of Birth
    -- (current time minus random number of days within the year of birth)  
    , DATE_TRUNC(
        'day',
        NOW() - INTERVAL '1d' * (
          floor(random() * ((
            ("age" + 1) * 365
          ) - (
            "age" * 365
          ) + 1) + (
            "age" * 365
          ))::int
        )
    ) AS "bday"

    -- Country
    -- (random value from a list)
    , ("countries_values")[floor(random() * ("countries_length") + 1)]
      AS "country"

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
    ON CONFLICT ON CONSTRAINT "users_uname_key" DO NOTHING
    RETURNING *
)

-->> Output >>
SELECT * FROM "insert_users" LIMIT 10;

