SELECT 
  t.table_name,
  pg_stat.n_live_tup AS total_rows,
  pg_size_pretty(pg_total_relation_size(t.table_name::text) - pg_indexes_size(t.table_name::text)) AS data_disk_space,
  array_agg(i.index_name) AS index_names,
  pg_size_pretty(SUM(pg_relation_size(i.index_name::text))) AS total_index_space
FROM 
  information_schema.tables t
LEFT JOIN pg_stat_user_tables pg_stat ON t.table_name = pg_stat.relname
LEFT JOIN (
    SELECT 
      indrelid::regclass::text AS table_name,
      indexrelid::regclass::text AS index_name
    FROM pg_index
    JOIN pg_class ON pg_class.oid = pg_index.indexrelid
    JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE nspname = 'public'
  ) i ON t.table_name = i.table_name
WHERE 
  t.table_schema = 'public'
GROUP BY t.table_name, pg_stat.n_live_tup
ORDER BY t.table_name ASC;