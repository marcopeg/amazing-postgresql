CREATE TABLE IF NOT EXISTS "public"."users" (
  "id" SERIAL PRIMARY KEY
, "uname" VARCHAR(50) UNIQUE NOT NULL
, "bday" TIMESTAMP WITH TIME ZONE NOT NULL
, "age" INTEGER NOT NULL
, "country" VARCHAR(2) NOT NULL
) WITH (oids = false);

CREATE TABLE IF NOT EXISTS "public"."users_follows" (
  "user_id_1" INTEGER NOT NULL
, "user_id_2" INTEGER NOT NULL
, PRIMARY KEY ("user_id_1", "user_id_2")
, CONSTRAINT "fk_user_id_1" FOREIGN KEY("user_id_1") REFERENCES "public"."users"("id")
, CONSTRAINT "fk_user_id_2" FOREIGN KEY("user_id_2") REFERENCES "public"."users"("id")
) WITH (oids = false);

CREATE MATERIALIZED VIEW IF NOT EXISTS "public"."users_relations" AS
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
FROM "public"."users" AS "t1";