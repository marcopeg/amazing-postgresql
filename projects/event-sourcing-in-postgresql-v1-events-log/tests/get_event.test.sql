BEGIN;
SELECT plan(2);

INSERT INTO "public"."events_log" ("payload")
SELECT json_build_object('v', "t") AS "payload"
FROM generate_series(1, 10) AS "t";

CREATE OR REPLACE FUNCTION "test_get_event_001"(OUT result INT) 
AS $$
DECLARE
  VAR_log1 RECORD;
  VAR_log2 RECORD;
BEGIN
  SELECT * INTO VAR_log1 FROM get_event();
  SELECT * INTO VAR_log2 FROM get_event(VAR_log1.etag);
  result = VAR_log2.etag - VAR_log1.etag;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "test_get_event_002"(OUT result INT) 
AS $$
DECLARE
  VAR_log1 RECORD;
BEGIN
  SELECT COUNT(*) INTO VAR_log1 FROM get_event(0, 3);
  result = VAR_log1.count;
END; $$
LANGUAGE plpgsql;

SELECT results_eq(
  'SELECT * FROM test_get_event_001()',
  $$VALUES (1)$$,
  'It should read events in sequence'
);

SELECT results_eq(
  'SELECT * FROM test_get_event_002()',
  $$VALUES (3)$$,
  'It should read multiple events with a limit'
);

SELECT * FROM finish();
ROLLBACK;

