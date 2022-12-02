BEGIN;
SELECT plan(6);

SELECT results_eq(
  $$WITH
    "dates" AS (
      SELECT * FROM ( VALUES
        ('1970-01-01'),
        ('1970-01-01 01:00:00'),
        ('2020-01-01 01:00:00')
      ) AS "t" ("pit")
    )
    SELECT 
      pushid_encode_date('ms', "pit"::timestamptz)::text as "pushid", 
      "pit"::text
    FROM "dates"
    ORDER BY "pushid" ASC;$$,
  $$VALUES 
    ('--------', '1970-01-01'),
    ('----Ciu-', '1970-01-01 01:00:00'),
    ('-LxTbSP-', '2020-01-01 01:00:00')$$,
  'It should generate a text based k-sortable dates to the milliseconds'
);

SELECT results_eq(
  $$WITH
    "dates" AS (
      SELECT * FROM ( VALUES
        ('1970-01-01'),
        ('1970-01-01 01:00:00'),
        ('2020-01-01 01:00:00'),
        ('2020-01-01 01:00:00.000001'),
        ('2020-01-01 00:59:59.999999')
      ) AS "t" ("pit")
    )
    SELECT 
      pushid_encode_date('mu', "pit"::timestamptz)::text as "pushid", 
      "pit"::text
    FROM "dates"
    ORDER BY "pushid" ASC;$$,
  $$VALUES 
    ('----------', '1970-01-01'),
    ('----2LZuF-', '1970-01-01 01:00:00'),
    ('-4akaNYTEz', '2020-01-01 00:59:59.999999'),
    ('-4akaNYTF-', '2020-01-01 01:00:00'),
    ('-4akaNYTF0', '2020-01-01 01:00:00.000001')$$,
  'It should generate a text based k-sortable dates to the microseconds'
);

SELECT results_eq(
  $$SELECT "query" FROM (
      SELECT 'q1' as "query", * FROM pushid_generate_v1('ms', '2022-01-01') UNION ALL
      SELECT 'q2' as "query", * FROM pushid_generate_v1('ms', '2021-01-01') UNION ALL
      SELECT 'q3' as "query", * FROM pushid_generate_v1('ms', '2023-01-01') UNION ALL
      SELECT 'q4' as "query", * FROM pushid_generate_v1('ms', '2022-01-01 01:00:00.000') UNION ALL
      SELECT 'q5' as "query", * FROM pushid_generate_v1('ms', '2022-01-01 00:59:59.999')
      ORDER BY "value" ASC
    ) t;$$,
  $$VALUES ('q2'),  ('q1'), ('q5'), ('q4'), ('q3')$$,
  'It should generate sortable PushID with millisecond precision'
);

SELECT results_eq(
  $$SELECT "query" FROM (
      SELECT 'q1' as "query", * FROM pushid_generate_v1('mu', '2022-01-01') UNION ALL
      SELECT 'q2' as "query", * FROM pushid_generate_v1('mu', '2021-01-01') UNION ALL
      SELECT 'q3' as "query", * FROM pushid_generate_v1('mu', '2023-01-01') UNION ALL
      SELECT 'q4' as "query", * FROM pushid_generate_v1('mu', '2022-01-01 01:00:00.000000') UNION ALL
      SELECT 'q5' as "query", * FROM pushid_generate_v1('mu', '2022-01-01 00:59:59.999999')
      ORDER BY VALUE ASC
    ) t;$$,
  $$VALUES ('q2'),  ('q1'), ('q5'), ('q4'), ('q3')$$,
  'It should generate sortable PushID with microseconds precision'
);

SELECT results_eq(
  $$WITH
    "id1" as (
      SELECT * FROM pushid_generate_v1('mu', '2022-01-01', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,61')
    ),
    "id2" as (
      SELECT * FROM pushid_generate_v1('mu', '2022-01-01', (SELECT last_push_date from id1), (SELECT last_rand_chars FROM id1))
    ),
    "id3" as (
      SELECT * FROM pushid_generate_v1('mu', '2022-01-01', (SELECT last_push_date FROM id2), (SELECT last_rand_chars FROM id2))
    ),
    "id4" as (
      SELECT * FROM pushid_generate_v1('mu', '2022-01-01', (SELECT last_push_date FROM id3), (SELECT last_rand_chars FROM id3))
    ),
    "all" as (
    	SELECT 'id1' as "query", * FROM "id1" UNION ALL
      SELECT 'id2' as "query", * FROM "id2" UNION ALL
      SELECT 'id3' as "query", * FROM "id3" UNION ALL
      SELECT 'id4' as "query", * FROM "id4"
      ORDER BY "value" ASC
    )
    SELECT
      "query"::text,
      "value"::text,
      "last_push_date"::text,
      "last_rand_chars"::text 
    FROM "all";$$,
  $$VALUES 
    ('id1', '-4p6bryL--S0UNEh8K2y', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,62'),
    ('id2', '-4p6bryL--S0UNEh8K2z', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,63'),
    ('id3', '-4p6bryL--S0UNEh8K3-', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,4,0'),
    ('id4', '-4p6bryL--S0UNEh8K30', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,4,1')$$,
  'It should generate sortable PushID within the same microseconds'
);

SELECT results_eq(
  $$WITH
    "id1" as (
      SELECT * FROM pushid_generate_v1('ms', '2022-01-01', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,61')
    ),
    "id2" as (
      SELECT * FROM pushid_generate_v1('ms', '2022-01-01', (SELECT last_push_date from id1), (SELECT last_rand_chars FROM id1))
    ),
    "id3" as (
      SELECT * FROM pushid_generate_v1('ms', '2022-01-01', (SELECT last_push_date FROM id2), (SELECT last_rand_chars FROM id2))
    ),
    "id4" as (
      SELECT * FROM pushid_generate_v1('ms', '2022-01-01', (SELECT last_push_date FROM id3), (SELECT last_rand_chars FROM id3))
    ),
    "all" as (
    	SELECT 'id1' as "query", * FROM "id1" UNION ALL
      SELECT 'id2' as "query", * FROM "id2" UNION ALL
      SELECT 'id3' as "query", * FROM "id3" UNION ALL
      SELECT 'id4' as "query", * FROM "id4"
      ORDER BY "value" ASC
    )
    SELECT
      "query"::text,
      "value"::text,
      "last_push_date"::text,
      "last_rand_chars"::text 
    FROM "all";$$,
  $$VALUES 
    ('id1', '-MsHvtk-S0UNEh8K230y', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,62'),
    ('id2', '-MsHvtk-S0UNEh8K230z', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,63'),
    ('id3', '-MsHvtk-S0UNEh8K231-', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,2,0'),
    ('id4', '-MsHvtk-S0UNEh8K2310', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,2,1')$$,
  'It should generate sortable PushID within the same millisecond'
);

SELECT * FROM finish();
ROLLBACK;


