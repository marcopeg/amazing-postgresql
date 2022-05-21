-- FillFactor = 100
-- both tables work in INSERT ONLY mode

CREATE TABLE IF NOT EXISTS "public"."v3_commands" (
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
) WITH (fillfactor = 100);

CREATE TABLE IF NOT EXISTS "public"."v3_responses" (
  "cmd_id" BIGINT NOT NULL,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

CREATE INDEX "v3_commands_read_idx"
ON "v3_commands" ( "created_at" DESC );

CREATE INDEX "v3_responses_read_idx"
ON "v3_responses" ( "created_at" DESC );
