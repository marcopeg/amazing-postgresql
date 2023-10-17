BEGIN;
SELECT plan(1);

SELECT has_table('users');

SELECT * FROM finish();
ROLLBACK;