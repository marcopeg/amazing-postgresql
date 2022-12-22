INSERT INTO "v1"."users"
SELECT
  CONCAT('user-', t) AS "id"
FROM generate_series(1, 100000) t
ON CONFLICT ON CONSTRAINT "users_pkey" DO NOTHING;

INSERT INTO "v1"."orders"
SELECT 
  concat(
    'user-',
    floor(random() * 50000 + 1)
  ) AS "user_id",
  floor(random() * 1000 + 1) AS "amount",
  clock_timestamp() - concat(floor(random() * 14 + 1), 'd')::interval AS "date"
FROM generate_series(1, 2500000) t;

INSERT INTO "v1"."orders"
SELECT 
  concat(
    'user-',
    floor(random() * 100000 + 1)
  ) AS "user_id",
  floor(random() * 1000 + 1) AS "amount",
  clock_timestamp() - concat(floor(random() * 14 + 1), 'd')::interval AS "date"
FROM generate_series(1, 250000) t;

