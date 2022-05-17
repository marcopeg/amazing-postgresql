-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS "public"."queue_v1" (
  "id" BIGSERIAL PRIMARY KEY,
  "payload" JSONB
);

--WITH (fillfactor = 90);
