CREATE OR REPLACE FUNCTION "queue_live_stream"() 
RETURNS SETOF "notify_live_stream_return"
AS $$
BEGIN
  RETURN QUERY
  INSERT INTO "notify_live_stream_queue"
  SELECT * FROM "notify_live_stream"()
  ON CONFLICT ON CONSTRAINT "notify_live_stream_queue_pkey"
  DO UPDATE SET "event_ids" = EXCLUDED."event_ids"
  RETURNING "user_id", "event_ids";
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "pick_live_stream_notification"(
  PAR_lock INTERVAL
) 
RETURNS SETOF "notify_live_stream_return"
AS $$
BEGIN
  RETURN QUERY
  UPDATE "notify_live_stream_queue"
     SET "lock_until" = NOW() + PAR_lock
   WHERE "user_id" IN (
     SELECT "user_id" FROM "notify_live_stream_queue" 
     WHERE "lock_until" <= NOW()
     LIMIT 1 
     FOR UPDATE SKIP LOCKED 
   )
  RETURNING "user_id", "event_ids";
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "pick_live_stream_notification"() 
RETURNS SETOF "notify_live_stream_return"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM "pick_live_stream_notification"('20s');
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "drop_live_stream_notification"(
  PAR_user_id TEXT
) 
RETURNS SETOF "notify_live_stream_return"
AS $$
BEGIN
  RETURN QUERY
  DELETE FROM "notify_live_stream_queue"
  WHERE "user_id" IN (
    SELECT "user_id"
    FROM "notify_live_stream_queue"
    WHERE "user_id" = PAR_user_id
      AND "lock_until" > NOW()
    FOR UPDATE SKIP LOCKED
  )
  RETURNING "user_id", "event_ids";
END; $$
LANGUAGE plpgsql;