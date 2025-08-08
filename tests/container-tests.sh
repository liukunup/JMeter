#!/bin/bash

# Ensure script exits on error and unset variables
set -euo pipefail

DEFAULT_JMETER_VERSION="5.6.3"
IMAGE_BASE="liukunup/jmeter"
TAG_OS="ubuntu-24.04"
TAG_JRE="openjdk-21-jre"
TAG_TYPE="fullstack"

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --JMeter)
        JMETER_VERSION="$2"
        shift 2
        ;;
      --SHA)
        GIT_COMMIT_SHA="$2"
        shift 2
        ;;
      *)
        log_failed "未知参数: $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "${GIT_COMMIT_SHA:-}" ]]; then
    echo "请提供 --SHA 参数"
    exit 1
  fi

  JMETER_VERSION="${JMETER_VERSION:-$DEFAULT_JMETER_VERSION}"
  TARGET_IMAGE="${IMAGE_BASE}:${JMETER_VERSION}-${TAG_OS}-${TAG_JRE}-${TAG_TYPE}-${GIT_COMMIT_SHA}"
}

# Define the script name and log file
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="${SCRIPT_NAME%.*}.log"

# Colors for logging (if terminal supports it)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local log_entry="[$level] ${timestamp} - ${message}"

  # Always write to log file (no color codes)
  echo "$log_entry" >> "$LOG_FILE"

  # Write to stderr (with color for terminal)
  if [ -t 2 ]; then
    case $level in
      ERROR)   echo -e "${RED}${log_entry}${NC}" >&2 ;;
      WARNING) echo -e "${YELLOW}${log_entry}${NC}" >&2 ;;
      SUCCESS) echo -e "${GREEN}${log_entry}${NC}" >&2 ;;
      INFO)    echo -e "${BLUE}${log_entry}${NC}" >&2 ;;
      *)       echo "$log_entry" >&2 ;;
    esac
  else
    echo "$log_entry" >&2
  fi
}

log_info()    { log "INFO" "$1"; }
log_warning() { log "WARNING" "$1"; }
log_failed()  { log "ERROR" "$1"; }
log_passed()  { log "SUCCESS" "$1"; }

log_section() {
  log_info "========================================"
  log_info "$1"
  log_info "========================================"
}

# 提取版本号
get_jmeter_version() {
  local log_file=$1

  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$log_file" | head -n 1
}

# ------------ TEST --------------

# 冒烟测试
test_smoke() {
  log_section "冒烟测试 - JMeter ${JMETER_VERSION} (SHA: ${GIT_COMMIT_SHA})"

  # 检查/拉取镜像
  if ! docker image inspect "$TARGET_IMAGE" &>/dev/null; then
    log_info "镜像不存在，尝试拉取: $TARGET_IMAGE"
    if ! docker pull "$TARGET_IMAGE"; then
      log_failed "镜像拉取失败"
      exit 1
    fi
  fi

  # 版本检查
  local TEMP_LOG=$(mktemp)
  log_info "执行 JMeter 版本验证..."

  if ! docker run --rm "$TARGET_IMAGE" jmeter -v > "$TEMP_LOG" 2>&1; then
    log_failed "获取版本号失败"
    cat "$TEMP_LOG"
    rm "$TEMP_LOG"
    exit 1
  fi

  # 验证版本号
  detected_version=$(get_jmeter_version "$TEMP_LOG")
  if [ -z "$detected_version" ]; then
    log_failed "无法提取JMeter版本号"
    cat "$TEMP_LOG"
    rm "$TEMP_LOG"
    exit 1
  elif [ "$detected_version" != "$JMETER_VERSION" ]; then
    log_failed "版本不匹配 (期望: $JMETER_VERSION, 实际: $detected_version)"
    cat "$TEMP_LOG"
    rm "$TEMP_LOG"
    exit 1
  fi

  log_passed "冒烟测试通过"
}

main() {
  parse_args "$@"

  # 运行所有测试
  test_smoke

  log_info "所有测试通过!"
}

main "$@"
