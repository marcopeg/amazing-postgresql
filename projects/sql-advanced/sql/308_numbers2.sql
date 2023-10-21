ANALYZE "users";
ANALYZE "users_idx_1";
ANALYZE "users_idx_2";
ANALYZE "users_idx_3";


EXPLAIN ANALYZE
SELECT * FROM "users"
WHERE "favourite_number" > 999998038
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_1"
WHERE "favourite_number" > 999998038
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_2"
WHERE "favourite_number" > 999998038
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_3"
WHERE "favourite_number" > 91938038
LIMIT 10;

