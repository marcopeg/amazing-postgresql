BEGIN;
SELECT plan(5);

-- 1669991730001
SELECT results_eq(
  $$select * from date2txt_ms('2022-12-02 15:35:30.001+01')$$,
  $$VALUES ('-NIIFshG'::varchar)$$,
  't1'
);

-- 1669991730002
SELECT results_eq(
  $$select * from date2txt_ms('2022-12-02 15:35:30.002+01')$$,
  $$VALUES ('-NIIFshH'::varchar(8))$$,
  't2'
);

-- 1669991730003
SELECT results_eq(
  $$select * from date2txt_ms('2022-12-02 15:35:30.003+01')$$,
  $$VALUES ('-NIIFshI'::varchar(8))$$,
  't3'
);

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


SELECT * FROM finish();
ROLLBACK;


