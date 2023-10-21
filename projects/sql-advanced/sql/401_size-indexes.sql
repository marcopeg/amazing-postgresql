SELECT 
  indrelid::regclass AS table_name, 
  indexrelid::regclass AS index_name, 
  pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size
FROM pg_index
JOIN pg_class ON pg_class.oid = pg_index.indexrelid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE nspname = 'public'
ORDER BY table_name, index_name;