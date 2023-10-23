ANALYZE "users";
ANALYZE "users_idx_1";
ANALYZE "users_idx_2";
ANALYZE "users_idx_3";


--
-- HIT
--

EXPLAIN ANALYZE
SELECT * FROM "users"
WHERE "date_of_birth" >= '1981-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_1"
WHERE "date_of_birth" >= '1981-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_2"
WHERE "date_of_birth" >= '1981-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;




--
-- NO HIT
--

EXPLAIN ANALYZE
SELECT * FROM "users"
WHERE "date_of_birth" >= '2781-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_1"
WHERE "date_of_birth" >= '2781-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;

EXPLAIN ANALYZE
SELECT * FROM "users_idx_2"
WHERE "date_of_birth" >= '2781-06-30'
ORDER BY "date_of_birth" ASC
LIMIT 10;
