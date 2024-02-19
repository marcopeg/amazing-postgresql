SELECT *
FROM invoices
WHERE user_id = 'user50'
  AND (amount > 75 OR (amount = 75 AND id > 0))
ORDER BY amount ASC, id ASC
LIMIT 10;
