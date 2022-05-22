
-- Get query timing:
-- https://stackoverflow.com/questions/9063402/get-execution-time-of-postgresql-query
DO $$
DECLARE
  _start_ts         timestamptz;
  _end_ts           timestamptz;
  _timing           numeric;
  _loop_max         numeric = 5;
  _loop_ins         numeric = 100;
  _max_tenants      numeric = 5000;
  _rows_before      numeric;
  _rows_after       numeric;
  _rows_expected    numeric;
BEGIN

  --
  -- v4
  --
  SELECT count(*) INTO _rows_before FROM "v4_commands";
  FOR _loop_count IN 1.._loop_max LOOP
    RAISE NOTICE 'Ingest % new rows; run: % of %;', _loop_ins, _loop_count, _loop_max;

    -- Run the query
    _start_ts := clock_timestamp();
    INSERT INTO "v4_commands" SELECT
      (SELECT (ARRAY(SELECT concat('tenant-', t) FROM generate_series(1, _max_tenants) AS "t"))[floor(random() * _max_tenants + 1)] where "t" = "t"),
      json_build_object(
        'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
        'cmd_target', CONCAT('task', "t")
      ),
      now() - '24h'::INTERVAL * random()
    FROM generate_series(1, _loop_ins) AS "t";
    _end_ts   := clock_timestamp();

    -- Build stats
    COMMIT;
    SELECT count(*) INTO _rows_after FROM "v4_commands";

    _timing   := round(1000 *(extract(epoch FROM _end_ts - _start_ts)));
    _rows_expected = _rows_before + _loop_ins;

    RAISE NOTICE 
      'Lapsed: %;  Ins/s: %'
      , _timing
      , round((_loop_ins / _timing * 1000))
    ;

    INSERT INTO "stats" VALUES (
      'commands_ingest_v4',
      _timing,
      json_build_object(
        'loop_count', _loop_count,
        'loop_max', _loop_max,
        'start_ts', _start_ts,
        'end_ts', _end_ts,
        'timing', _timing,
        'insert_per_sec', round((_loop_ins / _timing * 1000)),
        'rows_before', _rows_before,
        'rows_after', _rows_after,
        'rows_expected', _rows_expected
      )
    );
    COMMIT;

    -- Prepare for next loop:
    _rows_before = _rows_after;
  END LOOP;

  --
  -- v6
  --
  SELECT count(*) INTO _rows_before FROM "v6_commands";
  FOR _loop_count IN 1.._loop_max LOOP
    RAISE NOTICE 'Ingest % new rows; run: % of %;', _loop_ins, _loop_count, _loop_max;

    -- Run the query
    _start_ts := clock_timestamp();
    INSERT INTO "v6_commands" SELECT
      (SELECT (ARRAY(SELECT concat('tenant-', t) FROM generate_series(1, _max_tenants) AS "t"))[floor(random() * _max_tenants + 1)] where "t" = "t"),
      json_build_object(
        'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
        'cmd_target', CONCAT('task', "t")
      ),
      now() - '24h'::INTERVAL * random()
    FROM generate_series(1, _loop_ins) AS "t";
    _end_ts   := clock_timestamp();

    -- Build stats
    COMMIT;
    SELECT count(*) INTO _rows_after FROM "v6_commands";

    _timing   := round(1000 *(extract(epoch FROM _end_ts - _start_ts)));
    _rows_expected = _rows_before + _loop_ins;

    RAISE NOTICE 
      'Lapsed: %;  Ins/s: %'
      , _timing
      , round((_loop_ins / _timing * 1000))
    ;

    INSERT INTO "stats" VALUES (
      'commands_ingest_v6',
      _timing,
      json_build_object(
        'loop_count', _loop_count,
        'loop_max', _loop_max,
        'start_ts', _start_ts,
        'end_ts', _end_ts,
        'timing', _timing,
        'insert_per_sec', round((_loop_ins / _timing * 1000)),
        'rows_before', _rows_before,
        'rows_after', _rows_after,
        'rows_expected', _rows_expected
      )
    );
    COMMIT;

    -- Prepare for next loop:
    _rows_before = _rows_after;
  END LOOP;

  --
  -- v7
  --
  SELECT count(*) INTO _rows_before FROM "v7_commands";
  FOR _loop_count IN 1.._loop_max LOOP
    RAISE NOTICE 'Ingest % new rows; run: % of %;', _loop_ins, _loop_count, _loop_max;

    -- Run the query
    _start_ts := clock_timestamp();
    INSERT INTO "v7_commands" SELECT
      (SELECT (ARRAY(SELECT concat('tenant-', t) FROM generate_series(1, _max_tenants) AS "t"))[floor(random() * _max_tenants + 1)] where "t" = "t"),
      json_build_object(
        'cmd_name', CASE WHEN random() >= 0.5 THEN 'insert' WHEN random() >= 0.5 THEN 'update' ELSE 'delete' END,
        'cmd_target', CONCAT('task', "t")
      ),
      now() - '24h'::INTERVAL * random()
    FROM generate_series(1, _loop_ins) AS "t";
    _end_ts   := clock_timestamp();

    -- Build stats
    COMMIT;
    SELECT count(*) INTO _rows_after FROM "v7_commands";

    _timing   := round(1000 *(extract(epoch FROM _end_ts - _start_ts)));
    _rows_expected = _rows_before + _loop_ins;

    RAISE NOTICE 
      'Lapsed: %;  Ins/s: %'
      , _timing
      , round((_loop_ins / _timing * 1000))
    ;

    INSERT INTO "stats" VALUES (
      'commands_ingest_v7',
      _timing,
      json_build_object(
        'loop_count', _loop_count,
        'loop_max', _loop_max,
        'start_ts', _start_ts,
        'end_ts', _end_ts,
        'timing', _timing,
        'insert_per_sec', round((_loop_ins / _timing * 1000)),
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