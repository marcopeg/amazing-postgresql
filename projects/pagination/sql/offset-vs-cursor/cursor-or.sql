SELECT *
FROM invoices
WHERE user_id = 'user50'
  AND (amount > :amount OR (amount = :amount AND id > :id))
ORDER BY amount ASC, id ASC
LIMIT :pageSize;
