(
  SELECT * FROM invoices
  WHERE user_id = 'user123'
    AND amount > 750
  ORDER BY amount ASC, id ASC
  LIMIT 10
)
UNION ALL
(
  SELECT * FROM invoices
  WHERE user_id = 'user123'
    AND amount = 750
    AND id > 0
  ORDER BY amount ASC, id ASC
  LIMIT 10
)
ORDER BY amount ASC, id ASC
LIMIT 10;