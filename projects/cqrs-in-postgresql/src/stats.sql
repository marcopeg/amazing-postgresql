CREATE TABLE IF NOT EXISTS "public"."stats" (
  "query" TEXT NOT NULL,
  "duration_ms" INTEGER NOT NULL,
  "payload" JSONB NOT NULL DEFAULT '{}',
  "run" BIGSERIAL PRIMARY KEY
);
