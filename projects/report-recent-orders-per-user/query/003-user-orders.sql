SELECT
  "user_id",
  array_agg("order") as "orders"
FROM (
  SELECT
    "usr"."id" AS "user_id",
    json_build_object(
      'id', "ord"."id",
      'date', "ord"."date",
      'amount', "ord"."amount"
    ) as "order"
  FROM "orders" AS "ord"
  LEFT JOIN "users" AS "usr" ON "usr"."id" = "ord"."user_id"
  WHERE "ord"."date" >= now() - '1w'::interval
  ORDER BY "ord"."date" DESC
  LIMIT 1000
) "t"
GROUP BY "user_id";