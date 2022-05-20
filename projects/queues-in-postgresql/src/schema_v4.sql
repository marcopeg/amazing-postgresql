
CREATE TABLE IF NOT EXISTS "public"."queue_v4" (
  "payload" JSONB,
  "next_iteration" TIMESTAMP NOT NULL DEFAULT now(),
  "task_id" BIGSERIAL PRIMARY KEY
);
