SELECT * FROM invoices
WHERE user_id = 'user123'
  AND id > 1000000
LIMIT 10;