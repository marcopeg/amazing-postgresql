-- This could take a loooong while!
-- REFRESH MATERIALIZED VIEW "public"."users_relations";

SELECT
  *
  -- List of the first 5 profiles that are followed by the current one
,  (
    SELECT
      array_agg("user_id_2")
    FROM (
      SELECT "user_id_2"
      FROM "public"."users_follows"
      WHERE "user_id_1" = "t1"."id"
      LIMIT 5
    ) AS "s1"
  ) AS "following"
  -- List of the first 5 profiles that are followers of the current one
,  (
    SELECT
      array_agg("user_id_1")
    FROM (
      SELECT "user_id_1"
      FROM "public"."users_follows"
      WHERE "user_id_2" = "t1"."id"
      LIMIT 5
    ) AS "s1"
  ) AS "followers"
FROM "public"."users" AS "t1"
LIMIT 10
;