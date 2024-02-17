SELECT * FROM invoices
WHERE user_id = 'user123'
  AND id > 100000
LIMIT 10;