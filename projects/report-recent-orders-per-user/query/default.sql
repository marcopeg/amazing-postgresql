
SELECT
  "usr"."id" AS "user_id",
  "ord"."id" AS "order_id",
  "ord"."date" AS "order_date",
  "ord"."amount" AS "order_amount"
FROM "orders" AS "ord"
LEFT JOIN "users" AS "usr" ON "usr"."id" = "ord"."user_id"
WHERE "ord"."date" >= now() - '1w'::interval
ORDER BY "ord"."date" DESC;
