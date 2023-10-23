EXPLAIN ANALYZE
SELECT *
FROM "users"
where "name" = 'User-20999'
LIMIT 10;

--
-- Hit
--

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_1"
where "name" = 'User-20999'
LIMIT 10;


EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "name" = 'User-20999'
LIMIT 10;

--
-- No Hit
--

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_1"
where "name" = 'User-20999*'
LIMIT 10;


EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "name" = 'User-20999*'
LIMIT 10;