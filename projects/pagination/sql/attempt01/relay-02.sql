WITH
params(page_size, user_id, last_cursor) AS (
  VALUES (10, 'user123', 'NTAwLTA=')
),
decode_cursor as (
  SELECT convert_from(decode(last_cursor, 'base64'), 'UTF8') as decoded from params
),
tokens AS (
  SELECT
    COALESCE(NULLIF(SPLIT_PART(decoded, '-', 1), ''), '0')::INT AS last_amount,
    COALESCE(NULLIF(SPLIT_PART(decoded, '-', 2), ''), '0')::INT AS last_id
  FROM decode_cursor
),
dataset as (
  (
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
  LIMIT (SELECT page_size FROM params)
)
SELECT json_build_object(
  'next', (SELECT id FROM dataset ORDER BY id DESC LIMIT 1 OFFSET 10),
  'has_more', (SELECT count(*) > 10 FROM dataset),
  'data', (SELECT json_agg(t) FROM (SELECT * FROM dataset LIMIT 10) t),
  'dto', (
    SELECT json_object_agg(column_name, data_type) AS dto
    FROM information_schema.columns
    WHERE table_schema = 'public' -- or your specific schema if different
    AND table_name = 'invoices'
  )
) AS result_json;