CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE "public"."changelog" (
  "id" UUID DEFAULT uuid_generate_v1(),
  "timestamp" TIMESTAMP WITH TIME ZONE,
  "schema" VARCHAR(255),
  "table" VARCHAR(255),
  "operation" VARCHAR(255),
  "new_data" JSON,
  "old_data" JSON
  PRIMARY KEY ("id")
);
