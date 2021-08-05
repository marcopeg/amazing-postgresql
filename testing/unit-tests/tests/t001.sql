BEGIN;
SELECT plan(1);

SELECT has_table('foobar');

SELECT * FROM finish();
ROLLBACK;