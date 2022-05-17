-- Seed with direct insert:
INSERT INTO "public"."queue_v1" ("payload")
SELECT json_build_object('insert', "t") AS "payload"
FROM generate_series(1, 10) AS "t";

-- Seed using the function:
WITH "gen" as (SELECT "prog" FROM generate_series(1, 10) AS "prog")
SELECT "t2".* 
  FROM "gen"
  JOIN append_v1(
    json_build_object('append', "gen".prog::TEXT::JSON)
  ) AS "t2" ON 1 = 1
;
