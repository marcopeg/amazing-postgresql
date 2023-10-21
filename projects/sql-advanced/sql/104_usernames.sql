SELECT 
  "n", 
  concat('user-', "n") AS "user"
FROM generate_series(1, 10) "n";