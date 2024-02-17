SELECT * FROM invoices
WHERE user_id = 'user123'
  AND date < now() - '1 month'::interval
ORDER BY date DESC
LIMIT 10;