BEGIN;
SELECT plan(1);

PREPARE "compute_generated_users_values" AS
WITH 
  -- Static Data as JSON
  "seed_config"("doc") AS ( VALUES ('{
    "users_tot": 1,
    "user_age_min": 18,
    "user_age_max": 18,
    "usernames": ["Luke"],
    "modifiers": ["Happy"],
    "countries": ["it"]
  }'::json))

-- GENERATED USERS DATA
-- this is where we generate the data-set, with random values and
-- also some support data structures from the static data
, "generated_users_data" AS (
    SELECT
    -- Get a random age using the min/max from configuration
      (
        SELECT floor(random() * ((
          SELECT ("doc"->'user_age_max')::TEXT::INT FROM "seed_config"
        ) - (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ) + 1) + (
          SELECT ("doc"->'user_age_min')::TEXT::INT FROM "seed_config"
        ))::int
        WHERE 1 = 1
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
          (
            SELECT ("modifiers_values")[floor(random() * ("modifiers_length") + 1)]
            WHERE 1 = 1
          ),
          '_',
          (
            SELECT ("usernames_values")[floor(random() * ("usernames_length") + 1)]
            WHERE 1 = 1
          ),
          '_',
          TO_CHAR(
            NOW() - INTERVAL '1y' * "age"
            ,'YY'
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
        WHERE 1 = 1
      ) AS "country"

    FROM "generated_users_data"
  )

-- Use JSON function to estrapolate information:
-- I'm going to write an assertive test on this result!
SELECT * FROM "insert_users_values";

--
-- TESTS
--

SELECT results_eq(
  'compute_generated_users_values',
  $$VALUES (18, 'Happy_Luke_03', '2003-08-17 00:00:00+00'::timestamp with time zone, 'it')$$,
  'Should generate randomized users data'
);

SELECT * FROM finish();
ROLLBACK;

