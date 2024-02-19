SELECT * FROM invoices
WHERE user_id = 'user50'
ORDER BY amount ASC, id ASC
LIMIT 10
OFFSET 10 * (100 - 1);