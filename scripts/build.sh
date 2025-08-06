#!/bin/bash

# Docker Image Builder for JMeter
# 
# Usage: ./build.sh [OPTIONS]
# Options:
#   --dockerfile <FILE>  Specify Dockerfile to build (default: jmeter/Dockerfile.Ubuntu)
#   --prefix <PREFIX>    Tag prefix for the built image (default: ubuntu)
#   --base <VERSION>     Base OS image version (default: 24.04)
#   --jmeter <VERSION>   JMeter version (default: 5.6.3)
#   --jre <VERSION>      Java Runtime Environment version (default: openjdk-21-jre)
#
# Example:
# ./scripts/build.sh --dockerfile jmeter/Dockerfile.Ubuntu --prefix ubuntu --base 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
# ./scripts/build.sh --dockerfile jmeter/Dockerfile.Alpine --prefix alpine --base 3     --jmeter 5.6.3 --jre openjdk21-jre

# ------------------------- Configuration Variables -------------------------
# Default build configuration
DOCKERFILE_PATH="jmeter/Dockerfile.Ubuntu"
IMAGE_TAG_PREFIX="ubuntu"
BASE_IMAGE_VERSION="24.04"
JMETER_VERSION="5.6.3"
JRE_VERSION="openjdk-21-jre"  # Package names differ between distros:
                              # Alpine: openjdk21-jre
                              # Ubuntu: openjdk-21-jre

# ------------------------- Argument Parsing -------------------------
# Process command line arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dockerfile) DOCKERFILE_PATH="$2"; shift 2 ;;
    --prefix) IMAGE_TAG_PREFIX="$2"; shift 2 ;;
    --base) BASE_IMAGE_VERSION="$2"; shift 2 ;;
    --jmeter) JMETER_VERSION="$2"; shift 2 ;;
    --jre) JRE_VERSION="$2"; shift 2 ;;
    *) echo "Error: Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ------------------------- Image Building -------------------------
# Build Docker image with specified parameters
docker build \
    --build-arg BASE_IMAGE_VERSION="${BASE_IMAGE_VERSION}" \
    --build-arg JMETER_VERSION="${JMETER_VERSION}" \
    --build-arg JRE_VERSION="${JRE_VERSION}" \
    -t "jmeter:${IMAGE_TAG_PREFIX}-${BASE_IMAGE_VERSION}" \
    -f "${DOCKERFILE_PATH}" \
    .

# Show image list 
docker images
