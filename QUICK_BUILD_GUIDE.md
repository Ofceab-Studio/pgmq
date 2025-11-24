# Quick Build Guide - PGMQ Docker Image with Advanced Filtering

## TL;DR - Build in 3 Steps

```bash
# 1. Generate Dockerfile for PostgreSQL 18
./images/pgmq-pg/replace-pg-version.sh 18 ./images/pgmq-pg/Dockerfile.in ./images/pgmq-pg/Dockerfile

# 2. Build the image
docker build -f ./images/pgmq-pg/Dockerfile -t pgmq/pg18-pgmq:1.9.0 .

# 3. Run it
docker run -d --name pgmq -e POSTGRES_PASSWORD=password -p 5432:5432 pgmq/pg18-pgmq:1.9.0
```

## Or Use the Automated Script

```bash
# Build for PostgreSQL 18 with version 1.9.0
./build-pgmq-image.sh 18 1.9.0

# Or use defaults (PG 18, v1.9.0)
./build-pgmq-image.sh
```

## What's Included

✅ PostgreSQL 18 (or your chosen version)  
✅ PGMQ Extension v1.9.0  
✅ Advanced JSON filtering feature  
✅ All migration files  
✅ pg_partman for partitioned queues  

## Verify It Works

```bash
docker exec -it pgmq psql -U postgres -c "
SELECT pgmq.create('test');
SELECT pgmq.send('test', '{\"age\": 25}');
SELECT pgmq.send('test', '{\"age\": 30}');
SELECT * FROM pgmq.read('test', 30, 10, 
  '{\"field\": \"age\", \"operator\": \">\", \"value\": 20}');
"
```

Should return messages with age > 20 (both messages in this case).

## Files Changed for This Build

- `pgmq-extension/pgmq.control` → Version updated to 1.9.0
- `pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql` → New migration with advanced filtering
- `images/pgmq-pg/Dockerfile` → Generated from template (auto-created)

## Build Time

- First build: ~10-15 minutes (downloads base images, compiles extension)
- Subsequent builds: ~5-8 minutes (uses Docker cache)

## Troubleshooting

**Build fails?** Check `build.log` for errors.

**Extension version wrong?** Verify `pgmq.control` has `default_version = '1.9.0'`

**Filtering doesn't work?** Check migration was applied:
```sql
SELECT proname FROM pg_proc WHERE proname = 'build_message_filter';
```

For detailed instructions, see `BUILD_DOCKER_IMAGE.md`

