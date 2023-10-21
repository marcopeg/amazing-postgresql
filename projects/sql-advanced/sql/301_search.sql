EXPLAIN ANALYZE
SELECT * FROM "users"
where "id" = 500
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "uuid" = 'eb1851f4-be69-fccb-16f3-85b0741689e2'
LIMIT 1;


--
-- Sequential scans on full-cardinality are heavily affected
-- by the position of the hit.
--
-- 👉 Only if "LIMIT=1" because the sequential scan can exit the loop 👈
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "name" = 'User-500'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "name" = 'Foobar-500'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "name" = 'User-40999'
LIMIT 1;


--
-- Same partterns with almost zero cardinality:
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "gender" = 'M'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "gender" = 'M*'
LIMIT 1;

--
-- Same partterns with dates:
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "date_of_birth" = '1981-06-30'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "date_of_birth" = '1781-06-30'
LIMIT 1;

--
-- Note hitting results VS no-results matters a lot
-- when it comes to low cardinality results!
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_color" = 'Red'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_color" = 'Red*'
LIMIT 1;

--
-- NOTE: the size of the number won't impact the execution time!
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_number" = 1
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_number" = 9999
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_number" = 99999999
LIMIT 1;


--
-- Mid level cardinality (5000) still goes by the same pattern
--

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_word" = 'word-3676'
LIMIT 1;

EXPLAIN ANALYZE
SELECT * FROM "users"
where "favourite_word" = 'word-3676*'
LIMIT 1;
