#!/bin/bash
# Apply the advanced filtering migration to your PostgreSQL instance
# Usage: ./apply_migration.sh

set -e

echo "Applying pgmq migration 1.8.0 -> 1.9.0..."
echo "This will add advanced JSON filtering functionality."

# Apply the migration
psql postgres://postgres:password@localhost:5432/postgres -f pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql

echo ""
echo "Migration applied successfully!"
echo ""
echo "Verifying installation..."

# Verify the function exists
psql postgres://postgres:password@localhost:5432/postgres -c "
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'build_message_filter' 
              AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgmq')
        ) THEN '✓ build_message_filter function exists'
        ELSE '✗ build_message_filter function NOT found'
    END AS status;
"

echo ""
echo "Testing the function..."

# Test the function
psql postgres://postgres:password@localhost:5432/postgres -c "
SELECT pgmq.build_message_filter('{\"field\": \"age\", \"operator\": \">\", \"value\": 20}'::jsonb) AS test_result;
"

echo ""
echo "Done! You can now use advanced filtering in pgmq.read() and pgmq.read_with_poll()"

