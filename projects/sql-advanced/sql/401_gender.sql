ANALYZE "users";

--
-- Hit
--

EXPLAIN ANALYZE
SELECT *
FROM "users"
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

