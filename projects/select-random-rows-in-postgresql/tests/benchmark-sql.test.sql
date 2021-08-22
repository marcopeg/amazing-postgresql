BEGIN;
SELECT plan(2);

-- Prepare data:
CREATE TABLE "foo" ( "bar" TEXT );
INSERT INTO "foo" VALUES ( 'bar' );

-- Test running plain sql:
PREPARE "plain_sql" AS SELECT * FROM benchmark_sql('select count(*) from foo', 1);
SELECT lives_ok('plain_sql');

-- Test running a prepared statement:
PREPARE "target_sql" AS select count(*) from foo;
PREPARE "prepared_sql" AS SELECT * FROM benchmark_sql('target_sql', 1);
SELECT lives_ok('prepared_sql');

SELECT * FROM finish();
ROLLBACK;

