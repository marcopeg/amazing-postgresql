SELECT *
FROM invoices
WHERE user_id = 'user50'
  AND (amount > 50 OR (amount = 50 AND id > 0))
ORDER BY amount ASC, id ASC
LIMIT 10;
