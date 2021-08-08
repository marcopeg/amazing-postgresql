-- Logs a full JSON representation of the data change into a log table:
CREATE OR REPLACE FUNCTION observe_table_trigger_handler() RETURNS TRIGGER AS $$
DECLARE
	rec RECORD;
    new_data TEXT;
    old_data TEXT;
BEGIN
    -- Set record row depending on operation
    CASE TG_OP
    WHEN 'INSERT' THEN
        RAISE NOTICE 'INSERT: "%"!', TG_OP;
        rec := NEW;
        new_data = row_to_json(NEW);
        old_data := 'null';
    WHEN 'UPDATE' THEN
        rec := NEW;
        new_data = row_to_json(NEW);
        old_data := row_to_json(OLD);
    WHEN 'DELETE' THEN
        rec := OLD;
        SELECT json_agg(n)::text INTO old_data FROM json_each_text(to_json(OLD)) n;
        old_data := row_to_json(OLD);
        new_data := 'null';
    ELSE
        RAISE EXCEPTION 'Unknown TG_OP: "%". Should not occur!', TG_OP;
    END CASE;

    -- Queue the row into the changelog table
    INSERT INTO "public"."changelog" (
        "timestamp",
        "schema",
        "table",
        "operation",
        "new_data",
        "old_data"
    ) VALUES (
        CURRENT_TIMESTAMP,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        TG_OP,
        new_data::json,
        old_data::json
    );

	RETURN rec;
END; $$
LANGUAGE plpgsql;


-- Dynamically associate or remove the trigger that makes a table observable:
CREATE OR REPLACE FUNCTION observe_table(
    PAR_schema VARCHAR,
    PAR_table VARCHAR,
    PAR_dir BOOLEAN,
    OUT result BOOLEAN
) AS $$
DECLARE
	VAR_q VARCHAR = '';
BEGIN
    IF PAR_dir = true THEN
        VAR_q = VAR_q || 'CREATE TRIGGER "observe_table_%s_%s_trigger" ';
        VAR_q = VAR_q || 'AFTER INSERT OR UPDATE OR DELETE ';
        VAR_q = VAR_q || 'ON "%s"."%s" ';
        VAR_q = VAR_q || 'FOR EACH ROW EXECUTE PROCEDURE "observe_table_trigger_handler"()';
        VAR_q = FORMAT(VAR_q, PAR_schema, PAR_table, PAR_schema, PAR_table);
    ELSE
        VAR_q = VAR_q || 'DROP TRIGGER "observe_table_%s_%s_trigger" ';
        VAR_q = VAR_q || 'ON "%s"."%s" ';
        VAR_q = FORMAT(VAR_q, PAR_schema, PAR_table, PAR_schema, PAR_table);
    END IF;

    EXECUTE VAR_q;
    result = true;
END; $$
LANGUAGE plpgsql;