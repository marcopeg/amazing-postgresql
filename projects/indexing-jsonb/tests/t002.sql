BEGIN;
SELECT plan(1);

-- Wrap some complex test logic into a function:
-- (the function is defined within the transaction, hence it will be removed at the end of the test)
CREATE OR REPLACE FUNCTION t002(
    OUT result BOOLEAN
) AS $$
BEGIN
    RAISE INFO 'Info raised by t002';
    result = true;
END; $$
LANGUAGE plpgsql;

-- Execute the test function and build an expectation on the result:
SELECT results_eq(
  'SELECT * FROM t002()',
  ARRAY[true]
);

SELECT * FROM finish();
ROLLBACK;