ANALYZE "users";

-- This will hit the index
EXPLAIN ANALYZE
SELECT *
FROM "users"
WHERE "name" = 'User-100'
  AND "date_of_birth" > '1980-01-01';

-- This will hit the Index Only
-- (both requested columns are available within the index itself)
-- NOTE: the order in the conditions is irrelevant
EXPLAIN ANALYZE
SELECT "name", "date_of_birth"
FROM "users"
WHERE "date_of_birth" > '1980-01-01'
  AND "name" = 'User-100';

-- This will hit the index anyway but still require to look into the
-- table's data for the gender.
EXPLAIN ANALYZE
SELECT "name", "date_of_birth"
FROM "users"
WHERE "date_of_birth" > '1980-01-01'
  AND "name" = 'User-100'
  AND "gender" = 'M';

-- This will NOT hit the index
EXPLAIN ANALYZE
SELECT *
FROM "users"
WHERE "date_of_birth" > '1980-01-01'
  AND "gender" = 'M';

-- This will NOT hit the index
EXPLAIN ANALYZE
SELECT *
FROM "users"
WHERE "date_of_birth" > '1980-01-01';
