BEGIN;
SELECT plan(2);

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
      date2txt_ms("pit"::timestamptz)::text as "pushid", 
      "pit"::text
    FROM "dates"
    ORDER BY "pushid" ASC;
  $$,
  $$VALUES 
    ('--------', '1970-01-01'),
    ('----Ciu-', '1970-01-01 01:00:00'),
    ('-LxTbSP-', '2020-01-01 01:00:00')
  $$,
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
      date2txt_mu("pit"::timestamptz)::text as "pushid", 
      "pit"::text
    FROM "dates"
    ORDER BY "pushid" ASC;
  $$,
  $$VALUES 
    ('----------', '1970-01-01'),
    ('----2LZuF-', '1970-01-01 01:00:00'),
    ('-4akaNYTEz', '2020-01-01 00:59:59.999999'),
    ('-4akaNYTF-', '2020-01-01 01:00:00'),
    ('-4akaNYTF0', '2020-01-01 01:00:00.000001')
  $$,
  'It should generate a text based k-sortable dates to the microseconds'
);



-- SELECT results_eq(
--   $$WITH
--     "dates" AS (
--       SELECT * FROM ( VALUES
--         ('2010-11-29 09:00:00.000000+00'),
--         ('2000-11-29 09:00:00.000000+00'),
--         ('2000-11-29 09:00:00.000001+00'),
--         ('2000-11-29 08:59:59.999999+00'),
--         ('1980-11-29 09:00:00.000000+00')
--       ) AS "t" ("pit")
--     )
--     SELECT 
--       date_to_text_mu("pit"::timestamptz)::text as "pushid", 
--       "pit"::text
--     FROM "dates"
--     ORDER BY "pushid" ASC;
--   $$,
--   $$VALUES 
--     ('-0DHkFnXF-', '1980-11-29 09:00:00.000000+00'),
--     ('-2SnDMZ7Ez', '2000-11-29 08:59:59.999999+00'),
--     ('-2SnDMZ7F-', '2000-11-29 09:00:00.000000+00'),
--     ('-2SnDMZ7F0', '2000-11-29 09:00:00.000001+00'),
--     ('-3_XpB0VF-', '2010-11-29 09:00:00.000000+00')
--   $$,
--   'It should generate a text based k-sortable dates to the microsecond'
-- );


-- SELECT results_eq(
--   $$WITH
--     "dates" AS (
--       SELECT * FROM ( VALUES
--         ('2010-11-29 09:00:00.000000+00'),
--         ('2000-11-29 09:00:00.000000+00'),
--         ('2000-11-29 09:00:00.100000+00'),
--         ('2000-11-29 08:59:59.999999+00'),
--         ('1980-11-29 09:00:00.000000+00')
--       ) AS "t" ("pit")
--     )
--     SELECT 
--       date_to_text_ms("pit"::timestamptz)::text as "pushid", 
--       "pit"::text
--     FROM "dates"
--     ORDER BY "pushid" ASC;
--   $$,
--   $$VALUES 
--     ('3f15t--', '1980-11-29 09:00:00.000000+00'),
--     ('CATbucy-', '2000-11-29 08:59:59.999999+00'),
--     ('CATbud--', '2000-11-29 09:00:00.000000+00'),
--     ('CATbueY-', '2000-11-29 09:00:00.100000+00'),
--     ('GlKq0d--', '2010-11-29 09:00:00.000000+00')
--   $$,
--   'It should generate a text based k-sortable dates to the milliseconds'
-- );



SELECT * FROM finish();
ROLLBACK;


