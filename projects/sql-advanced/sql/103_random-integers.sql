-- floor(random() * (max - min + 1) + min)
SELECT floor(random() * (20 - 10 + 1) + 10) as "random";

-- Generate multiple random numbers
SELECT "n", floor(random() * 10 + 1)::integer AS "r"
FROM generate_series(1, 10) "n";
