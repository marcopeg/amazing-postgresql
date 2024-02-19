SELECT *
FROM invoices
WHERE user_id = 'user50'
  AND (amount > 0 OR (amount = 0 AND id > 0))
ORDER BY amount ASC, id ASC
LIMIT 10;
