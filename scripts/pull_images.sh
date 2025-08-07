#!/bin/bash

# Usage: ./pull_images.sh [-s <git_short_sha>]

# Parse command line arguments
SHA=""
while getopts ":s:" opt; do
  case $opt in
    s) SHA="$OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Common parameters
REGISTRY="docker.io"
JMETER="5.6.3"
IMAGE_BASE="liukunup/jmeter"

# OS versions
declare -A OS=(
  ["ALPINE"]="alpine-3"
  ["UBUNTU"]="ubuntu-24.04"
)

# JRE versions
declare -A JRE_ALPINE=(
  ["JDK21"]="openjdk21-jre"
  ["JDK8"]="openjdk8-jre"
)
declare -A JRE_UBUNTU=(
  ["JDK21"]="openjdk-21-jre"
  ["JDK8"]="openjdk-8-jre"
)

# List of images to pull
IMAGES=(
  # Alpine images
  "${IMAGE_BASE}:${JMETER}-${OS[ALPINE]}-${JRE_ALPINE[JDK21]}"
  "${IMAGE_BASE}:${JMETER}-${OS[ALPINE]}-${JRE_ALPINE[JDK21]}-plugins"
  "${IMAGE_BASE}:${JMETER}-${OS[ALPINE]}-${JRE_ALPINE[JDK8]}"
  "${IMAGE_BASE}:${JMETER}-${OS[ALPINE]}-${JRE_ALPINE[JDK8]}-plugins"

  # Ubuntu images
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}-plugins"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK8]}"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK8]}-plugins"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}-fullstack"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}-x11"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}-vnc-novnc"
  "${IMAGE_BASE}:${JMETER}-${OS[UBUNTU]}-${JRE_UBUNTU[JDK21]}-rdp"
)

# Pull images
for IMAGE in "${IMAGES[@]}"; do
  IMAGE_REF="${REGISTRY}/${IMAGE}"

  if [ -n "$SHA" ]; then
    IMAGE_REF="${IMAGE_REF}-${SHA}"
  fi

  echo "Pulling ${IMAGE_REF}"
  docker pull "${IMAGE_REF}"

  if [ "$REGISTRY" != "docker.io" ]; then
    docker tag "${IMAGE_REF}" "docker.io/${IMAGE}"
    docker rmi "${IMAGE_REF}"
  fi
done
