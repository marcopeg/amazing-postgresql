-- FillFactor = 100
-- both tables work in INSERT ONLY mode

CREATE TABLE IF NOT EXISTS "public"."v4_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
) WITH (fillfactor = 100);

CREATE TABLE IF NOT EXISTS "public"."v4_responses" (
  "cmd_id" BIGINT NOT NULL,
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

-- Speed up the "query by time" scenario
CREATE INDEX "v4_commands_read_idx"
ON "v4_commands" ( "ref" ASC, "created_at" DESC );

CREATE INDEX "v4_responses_read_idx"
ON "v4_responses" ( "ref" ASC, "created_at" DESC );

-- Speed up the "query by tenant" scenario
CREATE INDEX "v4_commands_read_by_tenant_idx"
ON "v4_commands" ( "ref", "created_at" DESC );

CREATE INDEX "v4_responses_read_by_tenant_idx"
ON "v4_responses" ( "ref", "created_at" DESC );