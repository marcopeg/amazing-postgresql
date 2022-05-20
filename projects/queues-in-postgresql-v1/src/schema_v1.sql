-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS "public"."queue_v1" (
  "payload" JSONB,
  "task_id" BIGSERIAL PRIMARY KEY
);


--WITH (fillfactor = 90);
