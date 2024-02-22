WITH
params(page_size, user_id, last_cursor) AS (
  VALUES (10, 'user12', null)
),
tokens AS (
  SELECT
    COALESCE(NULLIF(SPLIT_PART(convert_from(decode(last_cursor, 'base64'), 'UTF8'), '-', 1), ''), '0')::INT AS last_amount,
    COALESCE(NULLIF(SPLIT_PART(convert_from(decode(last_cursor, 'base64'), 'UTF8'), '-', 2), ''), '0')::INT AS last_id
  FROM params
)(
  SELECT *, encode(convert_to(amount || '-' || id, 'UTF8'), 'base64') AS cursor FROM invoices
  WHERE user_id = (SELECT user_id FROM params)
    AND amount > (SELECT last_amount FROM tokens)
  ORDER BY amount ASC, id ASC
  LIMIT (SELECT page_size FROM params)
) UNION ALL (
  SELECT *, encode(convert_to(amount || '-' || id, 'UTF8'), 'base64') AS cursor FROM invoices
  WHERE user_id = (SELECT user_id FROM params)
    AND amount = (SELECT last_amount FROM tokens)
    AND id > (SELECT last_id FROM tokens)
  ORDER BY amount ASC, id ASC
  LIMIT (SELECT page_size FROM params)
)
ORDER BY amount ASC, id ASC
LIMIT (SELECT page_size FROM params);