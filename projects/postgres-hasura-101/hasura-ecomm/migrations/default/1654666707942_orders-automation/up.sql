---
--- When adding a new Line to the Order
--- Fill the OrderLine referred data automatically
---

CREATE FUNCTION "public"."orders_lines_before_insert_fn"() 
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  VAR_order RECORD;
  VAR_product RECORD;
BEGIN

  -- Fill information related to the Order
  SELECT "user_id" INTO VAR_order FROM "public"."orders" WHERE "id" = NEW."order_id";
  NEW."user_id" = VAR_order."user_id";

  -- Fill information related to the Product
  SELECT "tenant_id", "price", "name" INTO VAR_product FROM "public"."products" WHERE "id" = NEW."product_id";
  NEW."tenant_id" = VAR_product."tenant_id";
  NEW."price" = VAR_product."price";
  NEW."name" = VAR_product."name";

  RETURN NEW;
END;
$$;

CREATE TRIGGER "orders_lines_before_insert_trigger" 
BEFORE INSERT ON "public"."orders_lines" 
FOR EACH 
ROW EXECUTE FUNCTION "public"."orders_lines_before_insert_fn"();




---
--- When modifying an exiting OrderLine
--- Enforce immutability of the other fields
---

CREATE FUNCTION "public"."orders_lines_before_update_fn"() 
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN

  -- Enforce Immutability
  NEW."user_id" = OLD."user_id";
  NEW."tenant_id" = OLD."tenant_id";
  NEW."order_id" = OLD."order_id";
  NEW."product_id" = OLD."product_id";
  NEW."price" = OLD."price";
  NEW."name" = OLD."name";
  NEW."created_at" = OLD."created_at";

  RETURN NEW;
END;
$$;

CREATE TRIGGER "orders_lines_before_update_trigger" 
BEFORE UPDATE ON "public"."orders_lines" 
FOR EACH 
ROW EXECUTE FUNCTION "public"."orders_lines_before_update_fn"();





---
--- When inserting, modifying or deleting an OrderLine
--- the referred Order.units should be re-calculated
---

CREATE FUNCTION "public"."orders_lines_after_crud_fn"() 
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  VAR_r RECORD;
BEGIN

  -- Get the proper reference to the Order.id based on the operation name
  IF (TG_OP = 'DELETE') THEN
    VAR_r = OLD;
  ELSE
    VAR_r = NEW;
  END IF;

  -- Update the Order.
  UPDATE "public"."orders"
  SET "total" = (
    SELECT SUM(units * price) AS sum FROM "public"."orders_lines"
    WHERE "order_id" = VAR_r.order_id
  )
  WHERE "id" = VAR_r.order_id;

  RETURN NEW;
END;
$$;

CREATE TRIGGER "orders_lines_after_crud_trigger" 
AFTER INSERT OR UPDATE OR DELETE ON "public"."orders_lines" 
FOR EACH 
ROW EXECUTE FUNCTION "public"."orders_lines_after_crud_fn"();