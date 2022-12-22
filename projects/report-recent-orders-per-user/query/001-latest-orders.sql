SELECT *
FROM "v1"."orders" AS "ord"
WHERE "ord"."date" >= now() - '1w'::interval;