#!/bin/bash
# Build Docker image for pgmq following the project's build pipeline
# Usage: ./build-docker.sh [PG_VERSION] [TAG]
# Example: ./build-docker.sh 18 pgmq/pg18-pgmq:1.9.0

set -e

PG_VERSION=${1:-18}
TAG=${2:-pgmq/pg${PG_VERSION}-pgmq:test}

echo "Building Docker image for PostgreSQL ${PG_VERSION}"
echo "Tag: ${TAG}"

# Get version from pgmq.control
cd "$(dirname "$0")"
VERSION=$(grep 'default_version' pgmq-extension/pgmq.control | cut -d "'" -f 2)
SHORT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

echo "PGMQ Version: ${VERSION}"
echo "Git SHA: ${SHORT_SHA}"

# Generate Dockerfile from template
echo "Generating Dockerfile..."
./images/pgmq-pg/replace-pg-version.sh ${PG_VERSION} ./images/pgmq-pg/Dockerfile.in ./images/pgmq-pg/Dockerfile

# Build the Docker image
echo "Building Docker image..."
docker build \
  -f ./images/pgmq-pg/Dockerfile \
  -t ${TAG} \
  -t pgmq/pg${PG_VERSION}-pgmq:latest \
  .

echo ""
echo "Build complete!"
echo "Image tagged as: ${TAG}"
echo "Image also tagged as: pgmq/pg${PG_VERSION}-pgmq:latest"
echo ""
echo "To run the container:"
echo "  docker run -d --name pgmq-test -e POSTGRES_PASSWORD=postgres -p 5432:5432 ${TAG}"

