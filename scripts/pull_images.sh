#!/bin/bash

# Usage: ./pull_images.sh

REGISTRY="docker.io"
JMETER_VERSION="5.6.3"

IMAGES=(
    # OpenJDK 21
    "liukunup/jmeter:${JMETER_VERSION}"
    "liukunup/jmeter:plugins-${JMETER_VERSION}"
    # OpenJDK 8
    "liukunup/jmeter:openjdk8-${JMETER_VERSION}"
    "liukunup/jmeter:openjdk8-plugins-${JMETER_VERSION}"
)

for IMAGE in "${IMAGES[@]}"; do
    docker pull ${REGISTRY}/${IMAGE}
    if [ "${REGISTRY}" != "docker.io" ]; then
        docker tag ${REGISTRY}/${IMAGE} docker.io/${IMAGE}
        docker rmi ${REGISTRY}/${IMAGE}
    fi
done
