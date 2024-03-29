BEGIN;
SELECT plan(4);

SELECT results_eq(
  $$SELECT date2ts_ms('2022-12-02 15:35:30.001+01'::timestamptz)$$,
  $$VALUES (1669991730001)$$,
  'd1'
);

SELECT results_eq(
  $$SELECT date2ts_ms('2022-12-02 15:35:30.002+01'::timestamptz)$$,
  $$VALUES (1669991730002)$$,
  'd2'
);

SELECT results_eq(
  $$WITH
    "dates" AS (
      SELECT * FROM ( VALUES
        ('1970-01-01 01:00:00'),
        ('1980-01-01 01:01:01'),
        ('2000-11-12 20:12:10.000000+00'),
        ('2000-11-12 20:12:10.000001+00'),
        ('2100-11-12 20:12:10.000000+00'),
        ('1970-01-01')
      ) AS "t" ("pit")
    )
    SELECT 
      "pit"::text,
      date2ts_mu("pit"::timestamptz) as "ts"
    FROM "dates"
    ORDER BY "ts" ASC;
  $$,
  $$VALUES 
    ('1970-01-01', 0),
    ('1970-01-01 01:00:00', 3600000000),
    ('1980-01-01 01:01:01', 315536461000000),
    ('2000-11-12 20:12:10.000000+00', 974059930000000),
    ('2000-11-12 20:12:10.000001+00', 974059930000001),
    ('2100-11-12 20:12:10.000000+00', 4129733530000000)
  $$,
  'It should generate timestamps to the microseconds'
);

SELECT results_eq(
  $$WITH
    "dates" AS (
      SELECT * FROM ( VALUES
        ('1970-01-01 01:00:00'),
        ('1980-01-01 01:01:01'),
        ('2000-11-12 20:12:10.000000+00'),
        ('2000-11-12 20:12:10.000001+00'),
        ('2100-11-12 20:12:10.000000+00'),
        ('1970-01-01')
      ) AS "t" ("pit")
    )
    SELECT 
      "pit"::text,
      date2ts_ms("pit"::timestamptz) as "ts"
    FROM "dates"
    ORDER BY "ts" ASC;
  $$,
  $$VALUES 
    ('1970-01-01', 0),
    ('1970-01-01 01:00:00', 3600000),
    ('1980-01-01 01:01:01', 315536461000),
    ('2000-11-12 20:12:10.000000+00', 974059930000),
    ('2000-11-12 20:12:10.000001+00', 974059930000),
    ('2100-11-12 20:12:10.000000+00', 4129733530000)
  $$,
  'It should generate timestamps to the milliseconds'
);

SELECT * FROM finish();
ROLLBACK;


