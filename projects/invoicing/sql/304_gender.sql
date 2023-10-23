ANALYZE "users";
ANALYZE "users_idx_1";
ANALYZE "users_idx_2";
ANALYZE "users_idx_3";

--
-- Hit
--

EXPLAIN ANALYZE
SELECT *
FROM "users"
where "gender" = 'M'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_1"
where "gender" = 'M'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "gender" = 'M'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_3"
where "gender" = 'M'
LIMIT 10;


--
-- No Hit
--

EXPLAIN ANALYZE
SELECT *
FROM "users"
where "gender" = 'M*'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_1"
where "gender" = 'M*'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "gender" = 'M*'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_3"
where "gender" = 'M*'
LIMIT 10;
