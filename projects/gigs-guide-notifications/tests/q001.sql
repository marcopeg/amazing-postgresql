BEGIN;
SELECT plan(2);

--
-- POPULATE DATA
--

INSERT INTO "public"."users_performers"("user_id", "artist_id") VALUES
  ('e2e04390-fe90-11eb-9a03-0242ac130001', 'artist1')
, ('e2e04390-fe90-11eb-9a03-0242ac130001', 'artist2')
, ('e2e04390-fe90-11eb-9a03-0242ac130002', 'artist1')
RETURNING "user_id", "artist_id";

INSERT INTO "public"."events_performers_temp"("event_id", "artist_id") VALUES
  ('event1', 'artist1') 
, ('event2', 'artist1') 
, ('event3', 'artist2') 
RETURNING "event_id", "artist_id";

INSERT INTO "all_music_events_temp" ("event_id", "country_code") VALUES
  ('event1', 'XX')
, ('event2', 'XX')
, ('event3', 'XX')
RETURNING *;

-- should be idempotent
SELECT * FROM queue_live_stream();
SELECT * FROM queue_live_stream();
SELECT * FROM queue_live_stream();

--
-- TEST
--

SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "notify_live_stream_queue"',
  ARRAY[2],
  'There should be 2 notifications to send'
);

--
-- CONSUME THE QUEUE
--

-- Symulte picking and completing a notification
SELECT pick_live_stream_notification();
-- create payload with queries
-- send it to sendgrid
SELECT drop_live_stream_notification('e2e04390-fe90-11eb-9a03-0242ac130001');

SELECT results_eq(
  'SELECT COUNT(*)::INT FROM "notify_live_stream_queue"',
  ARRAY[1],
  'There should be 1 notification left'
);


SELECT * FROM finish();
ROLLBACK;

