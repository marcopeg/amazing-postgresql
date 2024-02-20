INSERT INTO invoices (user_id, date, amount, product_id)
SELECT
  'user' || floor(random() * 100)::text AS user_id,
  timestamp 'now' - interval '1 day' * floor(random() * 3650) AS date,
  floor(random() * 1000),
  'product' || floor(random() * 100)::text AS product_id
FROM generate_series(1, :amount) s;
