SELECT *
FROM invoices
WHERE user_id = 'user50'
  AND (amount > :amount OR (amount = :amount AND id > 0))
ORDER BY amount ASC, id ASC
LIMIT 10;
