#!/bin/bash

# Usage: ./build.sh [OPTIONS]
# Options:
#   --image <VERSION>   Base image version (default: latest)
#   --jmeter <VERSION>  JMeter version (default: 5.6.3)
#   --java <VERSION>    Java version (default: openjdk-21-jre)

# 默认值
TARGET_DOCKERFILE="jmeter/Dockerfile.Ubuntu"
IMAGE_TAG="jmeter:ubuntu"
IMAGE_VERSION="latest"
JMETER_VERSION="5.6.3"
JAVA_VERSION="openjdk-21-jre"

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --image) IMAGE_VERSION="$2"; shift 2 ;;
        --jmeter) JMETER_VERSION="$2"; shift 2 ;;
        --java) JAVA_VERSION="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# 构建 Docker 镜像
docker build \
    --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
    --build-arg JMETER_VERSION="${JMETER_VERSION}" \
    --build-arg JAVA_VERSION="${JAVA_VERSION}" \
    -t "${IMAGE_TAG}" \
    -f "${TARGET_DOCKERFILE}" \
    .
