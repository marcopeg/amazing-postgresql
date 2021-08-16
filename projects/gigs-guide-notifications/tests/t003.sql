BEGIN;
SELECT plan(2);

--
-- POPULATE DATA
--

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


--
-- TEST
-- User1 SHOULD be notified of 1 events
-- User2 SHOULD be notified of 2 eventes
--

-- User1 was already notified of one event so it should only end up
-- having one single notification to be sent.
PREPARE "user1_notifications" AS
WITH
  "all_notifications" AS (
    SELECT * FROM notify_live_stream()
  )
, "user_notifications" AS (
    SELECT "user_id", unnest("event_ids") as "event_id" 
    FROM "all_notifications"
    WHERE "user_id" = 'e2e04390-fe90-11eb-9a03-0242ac130001'
  )
SELECT COUNT(*)::INT FROM "user_notifications";

SELECT results_eq(
  'user1_notifications',
  ARRAY[1],
  'User1 should have 1 notification'
);

-- User2 wasn't notified EVER, it should receive 2 notifications.
PREPARE "user2_notifications" AS
WITH
  "all_notifications" AS (
    SELECT * FROM notify_live_stream()
  )
, "user_notifications" AS (
    SELECT "user_id", unnest("event_ids") as "event_id" 
    FROM "all_notifications"
    WHERE "user_id" = 'e2e04390-fe90-11eb-9a03-0242ac130002'
  )
SELECT COUNT(*)::INT FROM "user_notifications";

SELECT results_eq(
  'user2_notifications',
  ARRAY[2],
  'User2 should have 2 notification'
);

SELECT * FROM finish();
ROLLBACK;

