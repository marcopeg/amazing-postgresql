CREATE SCHEMA "v1";

CREATE TABLE "v1"."users" (
  "id" TEXT PRIMARY KEY
);

CREATE TABLE "v1"."orders" (
  "user_id" TEXT NOT NULL,
  "amount" INT DEFAULT 0,
  "date" TIMESTAMPTZ NOT NULL,
  "notes" TEXT,
  "id" SERIAL PRIMARY KEY
);

CREATE UNIQUE INDEX ON "v1"."orders" ("user_id", "date");
