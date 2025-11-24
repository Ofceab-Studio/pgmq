#!/bin/bash
# build-pgmq-image.sh - Complete build script for PGMQ Docker image with advanced filtering

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
    echo "ERROR: Migration file pgmq--1.8.0--1.9.0.sql not found"
    exit 1
fi
echo "  ✓ Migration file exists"

if [ ! -f "images/pgmq-pg/Dockerfile.in" ]; then
    echo "ERROR: Dockerfile template not found"
    exit 1
fi
echo "  ✓ Dockerfile template exists"

# Step 2: Generate Dockerfile
echo ""
echo "Step 2: Generating Dockerfile for PostgreSQL ${PG_VERSION}..."
chmod +x images/pgmq-pg/replace-pg-version.sh
./images/pgmq-pg/replace-pg-version.sh ${PG_VERSION} \
    ./images/pgmq-pg/Dockerfile.in \
    ./images/pgmq-pg/Dockerfile

if [ ! -f "images/pgmq-pg/Dockerfile" ]; then
    echo "ERROR: Failed to generate Dockerfile"
    exit 1
fi
echo "  ✓ Dockerfile generated"

# Verify Dockerfile content
if ! grep -q "postgres:${PG_VERSION}-bookworm" images/pgmq-pg/Dockerfile; then
    echo "WARNING: Dockerfile may not have correct PostgreSQL version"
fi

# Step 3: Build image
echo ""
echo "Step 3: Building Docker image..."
echo "  This may take 5-10 minutes depending on your system..."
echo "  Building with context: $(pwd)"
echo ""

docker build \
    -f ./images/pgmq-pg/Dockerfile \
    -t ${IMAGE_TAG} \
    -t pgmq/pg${PG_VERSION}-pgmq:latest \
    . 2>&1 | tee build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}

if [ ${BUILD_EXIT_CODE} -eq 0 ]; then
    echo ""
    echo "  ✓ Image built successfully"
else
    echo ""
    echo "  ✗ Build failed with exit code ${BUILD_EXIT_CODE}"
    echo "  Check build.log for details"
    exit 1
fi

# Step 4: Verify image
echo ""
echo "Step 4: Verifying image..."
if docker images ${IMAGE_TAG} --format "{{.Repository}}:{{.Tag}}" | grep -q "${IMAGE_TAG}"; then
    IMAGE_SIZE=$(docker images ${IMAGE_TAG} --format "{{.Size}}")
    IMAGE_ID=$(docker images ${IMAGE_TAG} --format "{{.ID}}")
    echo "  ✓ Image created successfully"
    echo "    Tag: ${IMAGE_TAG}"
    echo "    Size: ${IMAGE_SIZE}"
    echo "    ID: ${IMAGE_ID}"
else
    echo "  ✗ Image verification failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Image Details:"
echo "  Repository: pgmq/pg${PG_VERSION}-pgmq"
echo "  Tags: ${TAG_VERSION}, latest"
echo "  PostgreSQL: ${PG_VERSION}"
echo "  PGMQ: ${VERSION}"
echo ""
echo "To run the container:"
echo "  docker run -d --name pgmq \\"
echo "    -e POSTGRES_PASSWORD=password \\"
echo "    -p 5432:5432 \\"
echo "    ${IMAGE_TAG}"
echo ""
echo "To test advanced filtering:"
echo "  docker exec -it pgmq psql -U postgres"
echo "  Then run:"
echo "    SELECT pgmq.create('test');"
echo "    SELECT pgmq.send('test', '{\"age\": 25}');"
echo "    SELECT pgmq.send('test', '{\"age\": 30}');"
echo "    SELECT * FROM pgmq.read('test', 30, 10, "
echo "      '{\"field\": \"age\", \"operator\": \">\", \"value\": 20}');"
echo ""
echo "To view logs:"
echo "  docker logs pgmq"
echo ""
echo "To stop and remove:"
echo "  docker stop pgmq && docker rm pgmq"
echo ""

