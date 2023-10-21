SELECT 
  table_name, 
  pg_size_pretty(pg_total_relation_size(table_name::text) - pg_indexes_size(table_name::text)) AS table_size
FROM (
  SELECT table_name
  FROM information_schema.tables
  WHERE table_schema = 'public'
) AS sub
ORDER BY table_name ASC;
