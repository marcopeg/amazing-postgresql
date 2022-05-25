
CREATE TABLE IF NOT EXISTS "public"."queue_v4" (
  "payload" JSONB,
  "next_iteration" TIMESTAMP NOT NULL DEFAULT now(),
  "task_id" BIGSERIAL PRIMARY KEY
);

CREATE INDEX "queue_v4_pick_idx"
ON "queue_v4" ( "next_iteration" ASC );
