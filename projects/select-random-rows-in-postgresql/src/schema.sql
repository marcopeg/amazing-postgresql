CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE "public"."users_with_ids" (
    "user_id" SERIAL PRIMARY KEY,
    "uname" VARCHAR(50) UNIQUE NOT NULL
) WITH (oids = false);

CREATE TABLE "public"."users_with_uuids" (
    "user_id" SERIAL PRIMARY KEY,
    "uname" VARCHAR(50) UNIQUE NOT NULL
) WITH (oids = false);
