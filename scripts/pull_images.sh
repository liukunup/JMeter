#!/bin/bash

# Usage: ./pull_images.sh

REGISTRY="docker.io"
JMETER_VERSION="5.6.3"

IMAGES=(
    # Alpine
    "liukunup/jmeter:${JMETER_VERSION}-alpine-3-openjdk21-jre"
    "liukunup/jmeter:${JMETER_VERSION}-alpine-3-openjdk21-jre-plugins"
    "liukunup/jmeter:${JMETER_VERSION}-alpine-3-openjdk8-jre"
    "liukunup/jmeter:${JMETER_VERSION}-alpine-3-openjdk8-jre-plugins"
    # Ubuntu
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre-plugins"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-8-jre"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-8-jre-plugins"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre-fullstack"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre-x11"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre-vnc-novnc"
    "liukunup/jmeter:${JMETER_VERSION}-ubuntu-24.04-openjdk-21-jre-rdp"
)

for IMAGE in "${IMAGES[@]}"; do
    docker pull ${REGISTRY}/${IMAGE}
    if [ "${REGISTRY}" != "docker.io" ]; then
        docker tag ${REGISTRY}/${IMAGE} docker.io/${IMAGE}
        docker rmi ${REGISTRY}/${IMAGE}
    fi
done
