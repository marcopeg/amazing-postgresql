CREATE OR REPLACE FUNCTION jsonb_array_element_index(arr jsonb, element text)
RETURNS int LANGUAGE plpgsql AS $$
DECLARE
  i int := 0;
  elem text;
BEGIN
  FOR elem IN SELECT jsonb_array_elements_text(arr)
  LOOP
    IF elem = element THEN
      RETURN i;
    END IF;
    i := i + 1;
  END LOOP;
  RETURN -1; -- Return -1 if the element is not found
END;
$$;
