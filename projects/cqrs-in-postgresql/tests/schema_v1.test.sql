BEGIN;
SELECT plan(1);

SELECT ok(true);

SELECT * FROM finish();
ROLLBACK;

