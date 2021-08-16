
CREATE OR REPLACE FUNCTION "notify_live_stream_impl"() 
RETURNS TABLE (
  "_user_id" TEXT,
  "_event_ids" TEXT[]
)
AS $$
BEGIN
  RETURN QUERY
  WITH
    "events_followed_by_users" as (
        SELECT
        "t1"."user_id",
        "t1"."artist_id",
        "t2"."event_id"
        FROM "users_performers" as "t1"
        JOIN "events_performers_temp" as "t2" on "t1"."artist_id" = "t2"."artist_id"
    )
  , "events_by_country_code" as (
      SELECT 
      "t1".*, 
      "t2"."country_code" 
      FROM "events_followed_by_users" as "t1"
      JOIN "all_music_events_temp" as "t2" on "t1"."event_id" = "t2"."event_id"
      WHERE "t2".country_code = 'XX'
  )
  , "users_events_notifications" as (
      SELECT
      "t1"."user_id",
      "t1"."event_id",
      "t1"."country_code"
      FROM "events_by_country_code" as "t1"
      WHERE NOT EXISTS (
        SELECT 
        FROM "users_sent_events" as "t2"
        WHERE "t2"."event_id" = "t1"."event_id" and "t2"."user_id" = "t1"."user_id"
    )
  )
  SELECT 
  "t1"."user_id"::text as "_user_id", 
  array_agg("t1"."event_id") as "_event_ids"
  FROM "users_events_notifications" as "t1"
  GROUP BY "t1"."user_id";

END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "notify_live_stream"() 
RETURNS TABLE (
  "user_id" TEXT,
  "event_ids" TEXT[]
)
AS $$
BEGIN
  RETURN QUERY
  SELECT
    "_user_id" AS "user_id",
    "_event_ids" AS "event_ids"
  FROM "notify_live_stream_impl"();
END; $$
LANGUAGE plpgsql;
