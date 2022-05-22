
-- Get query timing:
-- https://stackoverflow.com/questions/9063402/get-execution-time-of-postgresql-query
DO $$
DECLARE
  _start_ts         timestamptz;
  _end_ts           timestamptz;
  _timing           numeric;
  _cmd_loops        numeric = 10;
  _cmd_batch        numeric = 2;
  _cmd_tenants      numeric = 5000;
  _rows_before      numeric;
  _rows_after       numeric;
  _rows_expected    numeric;
BEGIN

  SELECT count(*) INTO _rows_before FROM "v7_commands";

  FOR _loop_count IN 1.._cmd_loops LOOP
    RAISE INFO 'v7 - Ingest % new rows; run: % of %;', _cmd_batch, _loop_count, _cmd_loops;

    -- Run the query
    _start_ts := clock_timestamp();
    INSERT INTO "v7_commands" SELECT
      (SELECT (ARRAY(SELECT concat('tenant-', t) FROM generate_series(1, _cmd_tenants) AS "t"))[floor(random() * _cmd_tenants + 1)] where "t" = "t"),
      json_build_object(
        'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
        'cmd_target', CONCAT('task', "t")
      ),
      now() - '24h'::INTERVAL * random()
    FROM generate_series(1, _cmd_batch) AS "t";
    _end_ts   := clock_timestamp();

    -- Build stats
    COMMIT;
    SELECT count(*) INTO _rows_after FROM "v7_commands";

    _timing   := round(1000 *(extract(epoch FROM _end_ts - _start_ts)));
    _rows_expected = _rows_before + _cmd_batch;

    RAISE INFO 
      'v7 - Lapsed: %;  Ins/s: %'
      , _timing
      , round((_cmd_batch / _timing * 1000))
    ;

    INSERT INTO "stats" VALUES (
      'commands_ingest_v7',
      _timing,
      json_build_object(
        'loop_count', _loop_count,
        'loop_limit', _cmd_loops,
        'start_ts', _start_ts,
        'end_ts', _end_ts,
        'timing', _timing,
        'insert_per_sec', round((_cmd_batch / _timing * 1000)),
        'rows_before', _rows_before,
        'rows_after', _rows_after,
        'rows_expected', _rows_expected
      )
    );
    COMMIT;

    -- Prepare for next loop:
    _rows_before = _rows_after;
  END LOOP;
END $$;



SELECT 
	"query",
	sum(("payload" -> 'rows_after')::integer) AS "tot_rows",
	round(avg("duration_ms")) AS "duration_ms_avg",
	round(min("duration_ms")) AS "duration_ms_min",
	round(max("duration_ms")) AS "duration_ms_max",
	round(avg(("payload" -> 'insert_per_sec')::integer)) AS "ins_s_avg",
	round(min(("payload" -> 'insert_per_sec')::integer)) AS "ins_s_min",
	round(max(("payload" -> 'insert_per_sec')::integer)) AS "ins_s_max"
FROM "stats"
GROUP BY "query";

SELECT * FROM "v7_commands";