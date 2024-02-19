SELECT * FROM invoices
WHERE user_id = 'user123'
ORDER BY id ASC
LIMIT 10
OFFSET 10 * (100 - 1);
