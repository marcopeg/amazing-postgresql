BEGIN;
SELECT plan(1);

PREPARE "compute_generated_users_data" AS
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

-- Use JSON function to estrapolate information:
-- I'm going to write an assertive test on this result!
SELECT * FROM "generated_users_data";

--
-- TESTS
--

SELECT results_eq(
  'compute_generated_users_data',
  $$VALUES (18, '{Luke}'::text[], 1, '{Happy}'::text[], 1, '{it}'::text[], 1)$$,
  'Should generate randomized data'
);

SELECT * FROM finish();
ROLLBACK;

