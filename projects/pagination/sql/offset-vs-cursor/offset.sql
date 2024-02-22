SELECT * FROM invoices
WHERE user_id = 'user50'
ORDER BY amount ASC, id ASC
LIMIT :limit
OFFSET :limit * (:page - 1);