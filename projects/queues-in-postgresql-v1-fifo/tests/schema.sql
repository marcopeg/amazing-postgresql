BEGIN;
SELECT plan(4);

PREPARE "ins_one_from_object" AS
SELECT COUNT(*)::INT FROM append_v1('{"a":123}');
SELECT results_eq('ins_one_from_object', 'VALUES (1::INT)');

PREPARE "ins_one_from_number" AS
SELECT COUNT(*)::INT FROM append_v1('123');
SELECT results_eq('ins_one_from_number', 'VALUES (1::INT)' );

PREPARE "ins_one_from_string" AS
SELECT COUNT(*)::INT FROM append_v1('"foobar"');
SELECT results_eq('ins_one_from_string', 'VALUES (1::INT)' );

PREPARE "ins_many_from_object" AS
SELECT COUNT(*)::INT FROM append_v1('[{"a":1},{"b":2}]');
SELECT results_eq('ins_many_from_object', 'VALUES (2::INT)' );

SELECT * FROM finish();
ROLLBACK;

