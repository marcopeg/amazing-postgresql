CREATE TYPE "notify_live_stream_return" AS (
  "user_id" TEXT
, "event_ids" TEXT[]
);

CREATE OR REPLACE FUNCTION "notify_live_stream_impl"() 
RETURNS TABLE (
  "_user_id" TEXT,
  "_event_ids" TEXT[]
)
AS $$
BEGIN
  RETURN QUERY
  SELECT
    "t1"."user_id"::text as "_user_id", 
    array_agg("t3"."event_id") as "_event_ids"
  FROM "users_performers" as "t1"
  JOIN "events_performers_temp" as "t2" on "t1"."artist_id" = "t2"."artist_id"
  JOIN "all_music_events_temp" as "t3" on "t2"."event_id" = "t3"."event_id"
  WHERE "t3"."country_code" = 'XX'
    AND NOT EXISTS (
      SELECT 
      FROM "users_sent_events" as "t4"
      WHERE "t4"."event_id" = "t2"."event_id" and "t4"."user_id" = "t1"."user_id"
    )
  GROUP BY "t1"."user_id";

END; $$
LANGUAGE plpgsql
IMMUTABLE;

CREATE OR REPLACE FUNCTION "notify_live_stream"() 
RETURNS SETOF "notify_live_stream_return"
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    "_user_id" AS "user_id",
    "_event_ids" AS "event_ids"
  FROM "notify_live_stream_impl"();
END; $$
LANGUAGE plpgsql
IMMUTABLE;