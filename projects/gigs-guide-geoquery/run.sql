

-- Find events near Amsterdam in a radius of 1km,
-- sorted by distance (in meters)
SELECT
  "event"."title",
  "event"."start_date_utc" AS "start_date",
  "geo"."distance"
FROM get_events_nearby('Amsterdam', 1000) AS "geo"
JOIN "all_music_events_temp" AS "event" USING ("event_id")
ORDER BY "geo"."distance";

-- SELECT * FROM get_events_nearby('Berlin', 1000);
-- SELECT * FROM get_events_nearby('Copenhagen', 1000);
-- SELECT * FROM get_events_nearby('Las Vegas', 1000);
-- SELECT * FROM get_events_nearby('London', 1000);
-- SELECT * FROM get_events_nearby('Milan', 1000);
-- SELECT * FROM get_events_nearby('Rome', 1000);
