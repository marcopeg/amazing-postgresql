SELECT * FROM invoices
WHERE user_id = 'user123'
  AND date < now()
ORDER BY date DESC
LIMIT 10;