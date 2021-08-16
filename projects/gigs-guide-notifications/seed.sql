
INSERT INTO "public"."users_performers"("user_id", "artist_id") VALUES
  ('e2e04390-fe90-11eb-9a03-0242ac130001', 'artist1'), 
  ('e2e04390-fe90-11eb-9a03-0242ac130002', 'artist1') 
RETURNING "user_id", "artist_id";

INSERT INTO "public"."events_performers_temp"("event_id", "artist_id") VALUES
  ('event1', 'artist1') 
, ('event2', 'artist1') 
RETURNING "event_id", "artist_id";

INSERT INTO "all_music_events_temp" ("event_id", "country_code") VALUES
  ('event1', 'XX')
, ('event2', 'XX')
RETURNING *;

INSERT INTO "public"."users_sent_events"("user_id", "event_id") VALUES
  ('e2e04390-fe90-11eb-9a03-0242ac130001', 'event1') 
RETURNING "user_id", "event_id";



WITH
  "all_notifications" AS (
    SELECT * FROM notify_live_stream()
  )
SELECT * FROM "all_notifications";