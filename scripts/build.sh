#!/bin/bash

# Usage: .\scripts\build.sh

docker build \
    --build-arg IMAGE_VERSION="latest" \
    --build-arg JMETER_VERSION="5.6.3" \
    --build-arg JAVA_VERSION="openjdk-21-jre" \
    -t "jmeter:ubuntu" \
    -f .\jmeter-with-remote-gui\Dockerfile.Ubuntu \
    .
