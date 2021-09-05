
CREATE TABLE IF NOT EXISTS "public"."events_log" (
  "etag" BIGSERIAL,
  "ctime" TIMESTAMP DEFAULT clock_timestamp(),
  "payload" JSON,
  PRIMARY KEY ("etag")
);
