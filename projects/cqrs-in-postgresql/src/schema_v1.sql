-- FillFactor = 100
-- both tables work in INSERT ONLY mode

CREATE TABLE IF NOT EXISTS "public"."v1_commands" (
  "payload" JSONB NOT NULL,
  "cmd_id" BIGSERIAL PRIMARY KEY,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

CREATE TABLE IF NOT EXISTS "public"."v1_responses" (
  "cmd_id" BIGINT NOT NULL,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

