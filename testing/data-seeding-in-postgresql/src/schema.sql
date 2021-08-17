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
