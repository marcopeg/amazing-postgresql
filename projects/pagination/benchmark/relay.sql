WITH
params(page_size, user_id, last_cursor) AS (
  VALUES (20, 'user123', null)
),
tokens AS (
  SELECT
    COALESCE(NULLIF(SPLIT_PART(convert_from(decode(last_cursor, 'base64'), 'UTF8'), '-', 1), ''), '0')::INT AS last_amount,
    COALESCE(NULLIF(SPLIT_PART(convert_from(decode(last_cursor, 'base64'), 'UTF8'), '-', 2), ''), '0')::INT AS last_id
  FROM params
),
dataset as (
  (
    SELECT * FROM invoices
    WHERE user_id = (SELECT user_id FROM params)
      AND amount > (SELECT last_amount FROM tokens)
    ORDER BY amount ASC, id ASC
    LIMIT (SELECT page_size + 1 FROM params)
  ) UNION ALL (
    SELECT * FROM invoices
    WHERE user_id = (SELECT user_id FROM params)
      AND amount = (SELECT last_amount FROM tokens)
      AND id > (SELECT last_id FROM tokens)
    ORDER BY amount ASC, id ASC
    LIMIT (SELECT page_size + 1 FROM params)
  )
  ORDER BY amount ASC, id ASC
  LIMIT (SELECT page_size + 1 FROM params)
)
SELECT json_build_object(
  'cursor', (SELECT encode(convert_to(amount || '-' || id, 'UTF8'), 'base64') AS cursor FROM dataset LIMIT 1 OFFSET (SELECT page_size FROM params)),
  'has_more', (SELECT count(*) > (SELECT page_size FROM params) FROM dataset),
  'num_rows', (SELECT count(*) FROM dataset),
  'rows', (SELECT json_agg(t) FROM (SELECT * FROM dataset LIMIT (SELECT page_size FROM params)) t)
) AS result;