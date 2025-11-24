# Building Docker Image with Advanced Filtering (v1.9.0)

This guide explains how to build a Docker image containing PGMQ with the advanced JSON filtering feature.

## Summary of Changes

### Files Modified/Created:
1. **pgmq-extension/pgmq.control** - Updated version from `1.7.0` to `1.9.0`
2. **pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql** - New migration file with advanced filtering
3. **pgmq-extension/test/sql/advanced_filtering.sql** - Test suite for new features

### New Features:
- Advanced JSON filtering with comparison operators (`>`, `>=`, `<`, `<=`, `=`, `!=`, `<>`, `exists`)
- Support for nested field access (e.g., `user.age`)
- Backward compatible with existing simple containment filters

## Build Steps

### Prerequisites
- Docker installed and running
- Git repository cloned
- PostgreSQL 14, 15, 16, 17, or 18 (choose one)

### Step 1: Verify Files Are Ready

```bash
cd /home/yayahc/Documents/Code/community/pgmq

# Check version in control file
grep default_version pgmq-extension/pgmq.control
# Should show: default_version = '1.9.0'

# Verify migration file exists
ls -la pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql

# Verify Dockerfile template exists
ls -la images/pgmq-pg/Dockerfile.in
```

### Step 2: Generate Dockerfile for Your PostgreSQL Version

Choose your PostgreSQL version (14, 15, 16, 17, or 18):

```bash
# For PostgreSQL 18 (example)
./images/pgmq-pg/replace-pg-version.sh 18 ./images/pgmq-pg/Dockerfile.in ./images/pgmq-pg/Dockerfile

# Verify the generated Dockerfile
cat images/pgmq-pg/Dockerfile | head -5
# Should show: FROM postgres:18-bookworm as builder
```

### Step 3: Build the Docker Image

```bash
# Build the image
docker build \
  -f ./images/pgmq-pg/Dockerfile \
  -t pgmq/pg18-pgmq:1.9.0 \
  -t pgmq/pg18-pgmq:latest \
  .

# Or use the build script
chmod +x build-docker.sh
./build-docker.sh 18 pgmq/pg18-pgmq:1.9.0
```

**Build time:** Approximately 5-10 minutes (depends on your system and network speed)

### Step 4: Verify the Image

```bash
# Check the image was created
docker images | grep pgmq

# Start a test container
docker run -d --name pgmq-test \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  pgmq/pg18-pgmq:1.9.0

# Wait a few seconds for PostgreSQL to start
sleep 5

# Verify extension version
docker exec pgmq-test psql -U postgres -c "\dx pgmq"
# Should show version 1.9.0

# Test advanced filtering
docker exec pgmq-test psql -U postgres << 'EOF'
SELECT pgmq.create('test_queue');
SELECT pgmq.send('test_queue', '{"name": "Alice", "age": 25}');
SELECT pgmq.send('test_queue', '{"name": "Bob", "age": 30}');
SELECT msg_id, message 
FROM pgmq.read('test_queue', 0, 10, '{"field": "age", "operator": ">", "value": 20}');
EOF

# Clean up test container
docker stop pgmq-test
docker rm pgmq-test
```

## Complete Build Script

Here's a complete script that automates the entire process:

```bash
#!/bin/bash
# build-pgmq-image.sh - Complete build script for PGMQ Docker image

set -e

PG_VERSION=${1:-18}
TAG_VERSION=${2:-1.9.0}
IMAGE_TAG="pgmq/pg${PG_VERSION}-pgmq:${TAG_VERSION}"

echo "=========================================="
echo "Building PGMQ Docker Image"
echo "=========================================="
echo "PostgreSQL Version: ${PG_VERSION}"
echo "PGMQ Version: ${TAG_VERSION}"
echo "Image Tag: ${IMAGE_TAG}"
echo ""

# Step 1: Verify prerequisites
echo "Step 1: Verifying prerequisites..."
if [ ! -f "pgmq-extension/pgmq.control" ]; then
    echo "ERROR: pgmq-extension/pgmq.control not found"
    exit 1
fi

VERSION=$(grep 'default_version' pgmq-extension/pgmq.control | cut -d "'" -f 2)
echo "  ✓ PGMQ version in control file: ${VERSION}"

if [ ! -f "pgmq-extension/sql/pgmq--1.8.0--1.9.0.sql" ]; then
    echo "ERROR: Migration file not found"
    exit 1
fi
echo "  ✓ Migration file exists"

# Step 2: Generate Dockerfile
echo ""
echo "Step 2: Generating Dockerfile for PostgreSQL ${PG_VERSION}..."
chmod +x images/pgmq-pg/replace-pg-version.sh
./images/pgmq-pg/replace-pg-version.sh ${PG_VERSION} \
    ./images/pgmq-pg/Dockerfile.in \
    ./images/pgmq-pg/Dockerfile
echo "  ✓ Dockerfile generated"

# Step 3: Build image
echo ""
echo "Step 3: Building Docker image..."
echo "  This may take 5-10 minutes..."
docker build \
    -f ./images/pgmq-pg/Dockerfile \
    -t ${IMAGE_TAG} \
    -t pgmq/pg${PG_VERSION}-pgmq:latest \
    . 2>&1 | tee build.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "  ✓ Image built successfully"
else
    echo "  ✗ Build failed. Check build.log for details"
    exit 1
fi

# Step 4: Verify image
echo ""
echo "Step 4: Verifying image..."
IMAGE_SIZE=$(docker images ${IMAGE_TAG} --format "{{.Size}}")
echo "  ✓ Image created: ${IMAGE_TAG} (${IMAGE_SIZE})"

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "To run the container:"
echo "  docker run -d --name pgmq \\"
echo "    -e POSTGRES_PASSWORD=password \\"
echo "    -p 5432:5432 \\"
echo "    ${IMAGE_TAG}"
echo ""
echo "To test advanced filtering:"
echo "  docker exec -it pgmq psql -U postgres -c \""
echo "    SELECT pgmq.create('test');"
echo "    SELECT pgmq.send('test', '{\\\"age\\\": 25}');"
echo "    SELECT * FROM pgmq.read('test', 30, 10, "
echo "      '{\\\"field\\\": \\\"age\\\", \\\"operator\\\": \\\">\\\", \\\"value\\\": 20}');"
echo "  \""
echo ""
```

## Quick Start Commands

```bash
# 1. Generate Dockerfile for PostgreSQL 18
./images/pgmq-pg/replace-pg-version.sh 18 ./images/pgmq-pg/Dockerfile.in ./images/pgmq-pg/Dockerfile

# 2. Build the image
docker build -f ./images/pgmq-pg/Dockerfile -t pgmq/pg18-pgmq:1.9.0 .

# 3. Run the container
docker run -d --name pgmq \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  pgmq/pg18-pgmq:1.9.0

# 4. Test it
docker exec -it pgmq psql -U postgres
```

## Building for Multiple PostgreSQL Versions

To build for all supported versions (like the CI pipeline does):

```bash
for pg_version in 14 15 16 17 18; do
    echo "Building for PostgreSQL ${pg_version}..."
    ./images/pgmq-pg/replace-pg-version.sh ${pg_version} \
        ./images/pgmq-pg/Dockerfile.in \
        ./images/pgmq-pg/Dockerfile
    
    docker build \
        -f ./images/pgmq-pg/Dockerfile \
        -t pgmq/pg${pg_version}-pgmq:1.9.0 \
        -t pgmq/pg${pg_version}-pgmq:latest \
        .
done
```

## What Gets Included in the Image

1. **PostgreSQL** (version specified)
2. **PGMQ Extension** (v1.9.0) with:
   - All existing PGMQ functions
   - New `build_message_filter()` helper function
   - Updated `read()` function with advanced filtering
   - Updated `read_with_poll()` function with advanced filtering
3. **pg_partman** (for partitioned queues)
4. **All migration files** (including `pgmq--1.8.0--1.9.0.sql`)

## Troubleshooting

### Build fails with "function already exists"
- This is normal if you're rebuilding. The migration uses `CREATE OR REPLACE` to handle this.

### Extension version shows 1.7.0 instead of 1.9.0
- Make sure `pgmq.control` has `default_version = '1.9.0'`
- Rebuild the image

### Advanced filtering doesn't work
- Verify the migration was applied: `SELECT proname FROM pg_proc WHERE proname = 'build_message_filter';`
- Check extension version: `SELECT extversion FROM pg_extension WHERE extname = 'pgmq';`

## Next Steps

After building:
1. Test the image locally
2. Tag and push to your registry (if needed)
3. Update your deployment configurations
4. Run the test suite: `make installcheck` (in the container or locally)

