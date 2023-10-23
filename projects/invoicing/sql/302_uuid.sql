EXPLAIN ANALYZE
SELECT *
FROM "users"
where "uuid" = 'eb1851f4-be69-fccb-16f3-85b0741689e2'
LIMIT 10;

EXPLAIN ANALYZE
SELECT *
FROM "users_idx_1"
where "uuid" = 'eb1851f4-be69-fccb-16f3-85b0741689e2'
LIMIT 10;


EXPLAIN ANALYZE
SELECT *
FROM "users_idx_2"
where "uuid" = 'eb1851f4-be69-fccb-16f3-85b0741689e2'
LIMIT 10;
