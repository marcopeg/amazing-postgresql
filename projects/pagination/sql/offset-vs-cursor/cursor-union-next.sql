
SELECT concat(amount, '-', id) as cursor FROM (
  (
    SELECT * FROM invoices
    WHERE user_id = 'user50'
      AND amount > :amount
    ORDER BY amount ASC, id ASC
    LIMIT :pageSize
  )
  UNION ALL
  (
    SELECT * FROM invoices
    WHERE user_id = 'user50'
      AND amount = :amount
      AND id > :id
    ORDER BY amount ASC, id ASC
    LIMIT :pageSize
  )
  ORDER BY amount ASC, id ASC
  LIMIT :pageSize
) f
LIMIT 1
OFFSET (:pageSize - 1);