ANALYZE "users";

EXPLAIN ANALYZE
SELECT *
FROM "users"
where "name" = 'User-100';

EXPLAIN ANALYZE
SELECT "name", "date_of_birth"
FROM "users"
where "name" = 'User-999';
