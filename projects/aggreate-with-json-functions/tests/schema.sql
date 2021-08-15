BEGIN;
SELECT plan(3);

SELECT has_table('public'::name, 'accounts'::name);
SELECT has_table('public'::name, 'profiles'::name);
SELECT has_table('public'::name, 'articles'::name);

SELECT * FROM finish();
ROLLBACK;

