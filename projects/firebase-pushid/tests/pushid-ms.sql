BEGIN;
SELECT plan(2);

SELECT results_eq(
  $$SELECT "query" FROM (
      SELECT 'q1' as "query", * FROM pushid_ms('2022-01-01') UNION ALL
      SELECT 'q2' as "query", * FROM pushid_ms('2021-01-01') UNION ALL
      SELECT 'q3' as "query", * FROM pushid_ms('2023-01-01') UNION ALL
      SELECT 'q4' as "query", * FROM pushid_ms('2022-01-01 01:00:00.000') UNION ALL
      SELECT 'q5' as "query", * FROM pushid_ms('2022-01-01 00:59:59.999')
      ORDER BY "value" ASC
    ) t;
  $$,
  $$VALUES ('q2'),  ('q1'), ('q5'), ('q4'), ('q3')
  $$,
  'It should generate sortable PushID with millisecond precision'
);


SELECT results_eq(
  $$WITH
    "id1" as (
      SELECT * FROM pushid_ms('2022-01-01', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,61')
    ),
    "id2" as (
      SELECT * FROM pushid_ms('2022-01-01', (SELECT last_push_date from id1), (SELECT last_rand_chars FROM id1))
    ),
    "id3" as (
      SELECT * FROM pushid_ms('2022-01-01', (SELECT last_push_date FROM id2), (SELECT last_rand_chars FROM id2))
    ),
    "id4" as (
      SELECT * FROM pushid_ms('2022-01-01', (SELECT last_push_date FROM id3), (SELECT last_rand_chars FROM id3))
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
    FROM "all";
  $$,
  $$VALUES 
    ('id1', '-MsHvtk-S0UNEh8K230y', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,62'),
    ('id2', '-MsHvtk-S0UNEh8K230z', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,1,63'),
    ('id3', '-MsHvtk-S0UNEh8K231-', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,2,0'),
    ('id4', '-MsHvtk-S0UNEh8K2310', '2022-01-01 00:00:00+00', '29,1,31,24,15,45,9,21,3,4,2,1')
  $$,
  'It should generate sortable PushID within the same millisecond'
);


SELECT * FROM finish();
ROLLBACK;


