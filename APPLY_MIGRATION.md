# Applying the Advanced Filtering Migration

The advanced filtering feature requires the extension to be updated to version 1.9.0. Here are the steps to apply it:

## Option 1: If you're using a Docker container (Recommended)

Since you're running a Docker container, you need to rebuild it with the new migration file:

1. **Stop the current container:**
   ```bash
   docker stop <container_name>
   ```

2. **Rebuild the Docker image with the new migration:**
   ```bash
   cd /home/yayahc/Documents/Code/community/pgmq
   ./build-docker.sh 18 pgmq/pg18-pgmq:1.9.0
   ```

3. **Start a new container:**
   ```bash
   docker run -d --name pgmq-test -e POSTGRES_PASSWORD=postgres -p 5432:5432 pgmq/pg18-pgmq:1.9.0
   ```

4. **Connect and verify:**
   ```sql
   psql postgres://postgres:postgres@localhost:5432/postgres
   \dx pgmq
   -- Should show version 1.9.0
   ```

## Option 2: Manual SQL Application (If you can't rebuild)

If you can't rebuild the Docker image, you can manually apply the migration:

1. **Connect to your PostgreSQL instance:**
   ```bash
   psql -h localhost -U postgres -d postgres
   ```

2. **Apply the migration SQL directly:**
   ```bash
   psql -h localhost -U postgres -d postgres -f pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql
   ```

   Or copy the contents of `pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql` and run it in psql.

3. **Verify the function exists:**
   ```sql
   SELECT proname FROM pg_proc 
   WHERE proname = 'build_message_filter' 
     AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pgmq');
   ```

## Option 3: Quick Fix Script

Run the verification and fix script:

```bash
psql -h localhost -U postgres -d postgres -f pgmq-extension/verify_and_fix_filtering.sql
```

This script will:
- Check if the function exists
- Create it if it doesn't
- Update the read functions
- Test the functionality

## Testing After Migration

Once the migration is applied, test with:

```sql
-- Create a test queue
SELECT pgmq.create('test_filter');

-- Send test messages
SELECT pgmq.send('test_filter', '{"name": "Alice", "age": 25}');
SELECT pgmq.send('test_filter', '{"name": "Bob", "age": 30}');
SELECT pgmq.send('test_filter', '{"name": "Charlie", "age": 20}');

-- Test advanced filtering
SELECT msg_id, message 
FROM pgmq.read('test_filter', 0, 10, '{"field": "age", "operator": ">", "value": 20}');
-- Should return Alice (25) and Bob (30)
```

## Troubleshooting

If you get an error like "function build_message_filter does not exist":

1. Check extension version:
   ```sql
   SELECT extversion FROM pg_extension WHERE extname = 'pgmq';
   ```

2. If it's less than 1.9.0, you need to apply the migration manually using Option 2 or 3 above.

3. If the migration file doesn't exist in your container, you'll need to rebuild the image (Option 1).

