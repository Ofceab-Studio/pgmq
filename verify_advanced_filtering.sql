-- Active: 1762355844622@@127.0.0.1@5432@postgres
-- Verification script for advanced filtering
-- Run this to ensure everything is set up correctly

\echo '========================================'
\echo 'Verifying Advanced Filtering Setup'
\echo '========================================'

-- 1. Check extension version
\echo ''
\echo '1. Checking extension version...'
SELECT 
    CASE 
        WHEN extversion >= '1.9.0' THEN '✓ Extension version: ' || extversion
        ELSE '✗ Extension version too old: ' || extversion || ' (need 1.9.0+)'
    END AS version_check
FROM pg_extension WHERE extname = 'pgmq';

-- 2. Check if build_message_filter exists
\echo ''
\echo '2. Checking build_message_filter function...'
SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ build_message_filter function exists'
        ELSE '✗ build_message_filter function NOT found'
    END AS function_check
FROM pg_proc 
WHERE proname = 'build_message_filter' 
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgmq');

-- 3. Test the helper function
SELECT pgmq.build_message_filter('{"field": "age", "operator": ">", "value": 20}'::jsonb) AS test_output;

-- 4. Check read function signature

SELECT 
    CASE 
        WHEN COUNT(*) > 0 THEN '✓ read function with conditional parameter exists'
        ELSE '✗ read function not found or missing conditional parameter'
    END AS read_check
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'pgmq' 
  AND p.proname = 'read'
  AND pg_get_function_arguments(p.oid) LIKE '%conditional%';

-- 5. Functional test
\echo ''
\echo '5. Running functional test...'
DO $$
DECLARE
    test_result TEXT;
BEGIN
    -- Create test queue
    PERFORM pgmq.drop_queue('verify_test');
    PERFORM pgmq.create('verify_test');
    
    -- Send test messages
    PERFORM pgmq.send('verify_test', '{"name": "Alice", "age": 25}');
    PERFORM pgmq.send('verify_test', '{"name": "Bob", "age": 30}');
    PERFORM pgmq.send('verify_test', '{"name": "Charlie", "age": 20}');
    
    -- Test filtering
    SELECT COUNT(*) INTO test_result
    FROM pgmq.read('verify_test', 0, 10, '{"field": "age", "operator": ">", "value": 20}');
    
    IF test_result::int = 2 THEN
        RAISE NOTICE '✓ Functional test PASSED: Found 2 messages with age > 20';
    ELSE
        RAISE WARNING '✗ Functional test FAILED: Expected 2 messages, got %', test_result;
    END IF;
    
    -- Cleanup
    PERFORM pgmq.drop_queue('verify_test');
END $$;

\echo ''
\echo '========================================'
\echo 'Verification Complete'
\echo '========================================'

