CREATE OR REPLACE FUNCTION pgmq.read(
    queue_name TEXT,
    vt INTEGER,
    qty INTEGER,
    conditional JSONB DEFAULT '{}'::jsonb
)
RETURNS SETOF pgmq.message_record AS $$
DECLARE
    sql TEXT;
    qtable TEXT := pgmq.format_table_name(queue_name, 'q');
    condition_clause TEXT;
    field_name TEXT;
    operator_name TEXT;
    compare_value JSONB;
    value_type TEXT;
BEGIN
    IF conditional ? 'operator' THEN
        field_name := conditional->>'field';
        operator_name := conditional->>'operator';
        compare_value := conditional->'value';
        value_type := jsonb_typeof(compare_value);
        
        IF value_type = 'null' THEN
            IF operator_name = '=' THEN
                condition_clause := FORMAT('message->>%L IS NULL', field_name);
            ELSIF operator_name = '!=' THEN
                condition_clause := FORMAT('message->>%L IS NOT NULL', field_name);
            ELSE
                RAISE EXCEPTION 'Null values only supported with = and != operators';
            END IF;
        ELSIF value_type = 'number' THEN
            condition_clause := FORMAT('(message->>%L)::numeric %s %s', field_name, operator_name, compare_value::text);
        ELSIF value_type = 'string' THEN
            condition_clause := FORMAT('message->>%L %s %L', field_name, operator_name, compare_value#>>'{}');
        ELSIF value_type = 'boolean' THEN
            condition_clause := FORMAT('(message->>%L)::boolean %s %s::boolean', field_name, operator_name, compare_value::text);
        ELSE
            condition_clause := FORMAT('message->>%L %s %L', field_name, operator_name, compare_value#>>'{}');
        END IF;
        
    ELSIF conditional != '{}'::jsonb THEN
        condition_clause := FORMAT('message @> %L', conditional);
    ELSE
        condition_clause := 'true';
    END IF;

    sql := FORMAT(
        $QUERY$
        WITH cte AS
        (
            SELECT msg_id
            FROM pgmq.%I
            WHERE vt <= clock_timestamp() AND %s
            ORDER BY msg_id ASC
            LIMIT $1
            FOR UPDATE SKIP LOCKED
        )
        UPDATE pgmq.%I m
        SET
            vt = clock_timestamp() + %L,
            read_ct = read_ct + 1
        FROM cte
        WHERE m.msg_id = cte.msg_id
        RETURNING m.msg_id, m.read_ct, m.enqueued_at, m.vt, m.message, m.headers;
        $QUERY$,
        qtable, condition_clause, qtable, make_interval(secs => vt)
    );
    
    RAISE NOTICE 'Final SQL: %', sql;
    
    RETURN QUERY EXECUTE sql USING qty;
END;
$$ LANGUAGE plpgsql;