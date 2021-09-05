BEGIN;
SELECT plan(2);

CREATE OR REPLACE FUNCTION "test_log_event"(OUT result BOOLEAN) 
AS $$
DECLARE
  VAR_r1 RECORD;
  VAR_r2 RECORD;
BEGIN
  SELECT * INTO VAR_r1 FROM log_event('{"a": 1}');
  SELECT * INTO VAR_r2 FROM log_event('{"a": 2}');
  result = VAR_r2.etag > VAR_r1.etag;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "test_log_events"(OUT result BOOLEAN) 
AS $$
DECLARE
  VAR_r1 RECORD;
  VAR_r2 RECORD;
BEGIN
  PERFORM log_events('[{"a": 1}, {"a": 2}]');
  SELECT * INTO VAR_r1 FROM "events_log" LIMIT 1;
  SELECT * INTO VAR_r2 FROM "events_log" OFFSET 1 LIMIT 1;
  result = VAR_r2.etag > VAR_r1.etag;
END; $$
LANGUAGE plpgsql;


SELECT results_eq(
  'SELECT * FROM test_log_event()',
  $$VALUES (true)$$,
  'It should add events with increased etags'
);

SELECT results_eq(
  'SELECT * FROM test_log_events()',
  $$VALUES (true)$$,
  'It should add multiple events from a json array'
);

SELECT * FROM finish();
ROLLBACK;

