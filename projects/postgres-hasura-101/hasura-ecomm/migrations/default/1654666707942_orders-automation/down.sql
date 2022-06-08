DROP TRIGGER "orders_lines_before_insert_trigger" ON "public"."orders_lines";
DROP FUNCTION "public"."orders_lines_before_insert_fn";

DROP TRIGGER "orders_lines_before_update_trigger" ON "public"."orders_lines";
DROP FUNCTION "public"."orders_lines_before_update_fn";

DROP TRIGGER "orders_lines_after_crud_trigger" ON "public"."orders_lines";
DROP FUNCTION "public"."orders_lines_after_crud_fn";