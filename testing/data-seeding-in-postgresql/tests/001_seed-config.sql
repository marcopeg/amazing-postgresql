BEGIN;
SELECT plan(1);

PREPARE "compute_json_config" AS
WITH 
-- Static Data as JSON:
-- This is just a nice way to provide parameters and/or
-- configuration for a complex job.
"seed_config"("doc") AS ( VALUES ('{
  "users_tot": 30,
  "user_age_min": 18,
  "user_age_max": 18,
  "usernames": ["Luke"],
  "modifiers": ["Happy"],
  "countries": ["it"]
}'::json))

-- Use JSON function to estrapolate information:
-- I'm going to write an assertive test on this result!
SELECT
  ("doc" -> 'users_tot')::TEXT::INT AS "users_tot"
, (
    (SELECT ARRAY(SELECT json_array_elements_text("doc"->'usernames')) FROM "seed_config")[1]
  ) AS "first_username"
, (
    (SELECT ARRAY(SELECT json_array_elements_text("doc"->'modifiers')) FROM "seed_config")[1]
  ) AS "first_modifier"
, (
    (SELECT ARRAY(SELECT json_array_elements_text("doc"->'countries')) FROM "seed_config")[1]
  ) AS "first_country"
FROM "seed_config";

--
-- TESTS
--

SELECT results_eq(
  'compute_json_config',
  $$VALUES ( 30, 'Luke', 'Happy', 'it' )$$,
  'Should parse the json config'
);

SELECT * FROM finish();
ROLLBACK;

