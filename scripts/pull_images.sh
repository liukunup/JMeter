#!/bin/bash
# Usage: .\pull_images.sh

REGISTRY="docker.io"
JMETER_VERSION="5.6.3"

# OpenJDK 21
docker pull ${REGISTRY}/liukunup/jmeter:${JMETER_VERSION}
docker pull ${REGISTRY}/liukunup/jmeter:plugins-${JMETER_VERSION}
docker pull ${REGISTRY}/liukunup/jmeter:business-${JMETER_VERSION}

# OpenJDK 8
docker pull ${REGISTRY}/liukunup/jmeter:openjdk8-${JMETER_VERSION}
docker pull ${REGISTRY}/liukunup/jmeter:openjdk8-plugins-${JMETER_VERSION}
