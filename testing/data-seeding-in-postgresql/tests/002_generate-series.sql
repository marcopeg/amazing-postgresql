BEGIN;
SELECT plan(1);

PREPARE "compute_generated_users_data" AS
WITH 
  -- SEED CONFIGURATION AND STATIC DATA
  -- (we use this as source for dictionary-based randomic selections)
  "seed_config"("doc") AS ( VALUES ('{
    "users_tot": 1,
    "user_age_min": 18,
    "user_age_max": 18,
    "user_rand_min": 1,
    "user_rand_max": 1,
    "usernames": ["Luke"],
    "modifiers": ["Happy"],
    "countries": ["it"]
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

-- Just output the data from the last CTE:
SELECT * FROM "generated_users_data";

--
-- TESTS
--

SELECT results_eq(
  'compute_generated_users_data',
  $$VALUES (
      18                 -- age
    , '{Luke}'::text[]   -- usernames_values
    , 1                  -- usernames_length
    , '{Happy}'::text[]  -- modifiers_values
    , 1                  -- modifiers_length
    , '{it}'::text[]     -- countries_values
    , 1                  -- countries_length
    , 1                  -- user_rand_min
    , 1                  -- user_rand_max
  )$$,
  'Should generate randomized data'
);

SELECT * FROM finish();
ROLLBACK;

