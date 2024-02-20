(
  SELECT * FROM invoices
  WHERE user_id = 'user50'
    AND amount > :amount
  ORDER BY amount ASC, id ASC
  LIMIT 10
)
UNION ALL
(
  SELECT * FROM invoices
  WHERE user_id = 'user50'
    AND amount = :amount
    AND id > 0
  ORDER BY amount ASC, id ASC
  LIMIT 10
)
ORDER BY amount ASC, id ASC
LIMIT 10;