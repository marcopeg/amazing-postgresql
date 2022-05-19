-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS "public"."queue_v1" (
  "payload" JSONB,
  "task_id" BIGSERIAL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS "public"."queue_v2" (
  "payload" JSONB,
  "is_available" BOOLEAN DEFAULT true,
  "task_id" BIGSERIAL PRIMARY KEY
);

CREATE INDEX "queue_v2_pick_idx" 
ON "queue_v2" ( "task_id" ASC ) 
WHERE ( "is_available" = true );

--WITH (fillfactor = 90);
