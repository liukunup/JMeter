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
#   --all               Build all variants (not implemented yet)
#
# Example:
# ./build.sh --dockerfile jmeter/Dockerfile.Alpine --os-name alpine --os-version 3     --jmeter 5.6.3 --jre openjdk21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Ubuntu --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
#
# ./build.sh --dockerfile jmeter/Dockerfile.Plugins --os-name alpine --os-version 3     --jmeter 5.6.3 --jre openjdk21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Plugins --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
#
# ./build.sh --dockerfile jmeter/Dockerfile.Business --os-name alpine --os-version 3     --jmeter 5.6.3 --jre openjdk21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Business --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
#
# ./build.sh --dockerfile jmeter/Dockerfile.Ubuntu-with-RDP       --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Ubuntu-with-X11       --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Ubuntu-with-VNC-NoVNC --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre
# ./build.sh --dockerfile jmeter/Dockerfile.Ubuntu-FullStack      --os-name ubuntu --os-version 24.04 --jmeter 5.6.3 --jre openjdk-21-jre

set -euo pipefail

DEFAULT_DOCKERFILE="jmeter/Dockerfile.Ubuntu"
DEFAULT_OS_NAME="ubuntu"
DEFAULT_OS_VERSION="24.04"
DEFAULT_JMETER_VERSION="5.6.3"
DEFAULT_JRE_VERSION="openjdk-21-jre"
IMAGE_REPO="liukunup/jmeter"

# Display help message
show_help() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# //'
}

build_jmeter_image() {
  local dockerfile="$1"
  local os_name="$2"
  local os_version="$3"
  local jmeter_version="$4"
  local jre_version="$5"

  local tag="${jmeter_version}-${os_name}-${os_version}-${jre_version}"
  local target="${IMAGE_REPO}:${tag}"

  docker build \
    --build-arg BASE_IMAGE_VERSION="${os_version}" \
    --build-arg JMETER_VERSION="${jmeter_version}" \
    --build-arg JRE_VERSION="${jre_version}" \
    -t "${target}" \
    -f "${dockerfile}" \
    .
}

build_jmeter_image_ext() {
  local dockerfile="$1"
  local os_name="$2"
  local os_version="$3"
  local jmeter_version="$4"
  local jre_version="$5"
  local src="$6"
  local dst="$7"

  local tag="${jmeter_version}-${os_name}-${os_version}-${jre_version}"
  local target="${IMAGE_REPO}:${tag}"

  if [[ -z "${src}" ]]; then
    tag="${tag}-${src}"
  fi

  if [[ -z "${dst}" ]]; then
    target="${target}-${dst}"
  fi

  docker build \
    --build-arg BASE_JMETER_IMAGE_VERSION="${tag}" \
    -t "${target}" \
    -f "${dockerfile}" \
    .
}

get_variant() {
    local dockerfile="$1"
    local variant="${dockerfile#*.Ubuntu}"
    variant="${variant#*-}"  # Remove prefix
    variant="${variant%%.*}"  # Remove suffix
    variant="${variant:-base}"  # Default to "base" if empty
    echo "${variant,,}"  # Convert to lowercase
}

# ------------------------- Argument Parsing -------------------------
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dockerfile) DOCKERFILE="$2"; shift 2 ;;
        --os-name) OS_NAME="$2"; shift 2 ;;
        --os-version) OS_VERSION="$2"; shift 2 ;;
        --jmeter) JMETER_VERSION="$2"; shift 2 ;;
        --jre) JRE_VERSION="$2"; shift 2 ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Error: Unknown option: $1" >&2; show_help; exit 1 ;;
    esac
done

# ------------------------- Main Build Logic -------------------------
echo "Starting JMeter image build process..."
echo "Configuration:"
echo "  Dockerfile: ${DOCKERFILE}"
echo "  Image prefix: ${IMAGE_TAG_PREFIX}"
echo "  Base OS version: ${BASE_IMAGE_VERSION}"
echo "  JMeter version: ${JMETER_VERSION}"
echo "  JRE version: ${JRE_VERSION}"

# Determine build type based on Dockerfile name
case "$DOCKERFILE" in
    *Dockerfile.Alpine|*Dockerfile.Ubuntu)
        # Standard base image build
        build_jmeter_image "$DOCKERFILE" "$OS_NAME" "$OS_VERSION" "$JMETER_VERSION" "$JRE_VERSION"
        ;;
    *Dockerfile.Plugins)
        # Plugins image build - needs base image tag
        build_jmeter_image_ext "$DOCKERFILE" "$OS_NAME" "$OS_VERSION" "$JMETER_VERSION" "$JRE_VERSION" "" "plugins"
        ;;
    *Dockerfile.Business)
        # Business image build - needs base image tag
        build_jmeter_image_ext "$DOCKERFILE" "$OS_NAME" "$OS_VERSION" "$JMETER_VERSION" "$JRE_VERSION" "plugins" "business"
        ;;
    *Dockerfile.Ubuntu-*)
        # Ubuntu variant build
        build_jmeter_image_ext "$DOCKERFILE" "$OS_NAME" "$OS_VERSION" "$JMETER_VERSION" "$JRE_VERSION" "plugins" "$(get_variant "$DOCKERFILE")"
        ;;
    *)
        echo "Error: Unsupported Dockerfile specified: $DOCKERFILE" >&2
        exit 1
        ;;
esac

# Show built images
echo -e "\nBuilt images:"
docker images "${IMAGE_REPO}*" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"