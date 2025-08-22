#!/bin/bash

# set -x  # Uncomment for debugging

# Ensure script exits on error and unset variables
set -euo pipefail

# ------------ Constants (Do not modify) ------------
readonly SCRIPT_VERSION="1.0.0"
# shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}") || exit 1

# ------------ Defaults ------------
JMETER_VERSION="5.6.3"
REGISTRY="docker.io"
IMAGE_BASE="liukunup/jmeter"
TAG_OS="ubuntu-24.04"
TAG_JRE="openjdk-21-jre"
TAG_GUI="vnc"

# ------------ Toolkit ------------
# Load logger if available, else define basic logging functions
LOGGER_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/logger.sh"
if [[ -f "${LOGGER_SCRIPT}" && -r "${LOGGER_SCRIPT}" ]]; then
  # shellcheck disable=SC1090
  source "${LOGGER_SCRIPT}"
  export LOG_LEVEL="INFO"
  export LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"
else
  debug()    { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[DEBUG] ${timestamp} - $*"; }
  info()     { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[INFO] ${timestamp} - $*"; }
  warn()     { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[WARN] ${timestamp} - $*"; }
  error()    { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[ERROR] ${timestamp} - $*"; }
  critical() { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[CRITICAL] ${timestamp} - $*"; }
fi

# 检查日志文件最后N行是否匹配给定的正则表达式
# 参数: 日志文件 行数 正则表达式
# 返回: 0-匹配成功, 1-匹配失败, 2-其他错误
check_logfile_pattern() {
  local logfile="$1"
  local last_line_count="${2:-1}"
  local pattern="$3"

  # 参数最少3个 & 日志文件可读
  [ $# -lt 3 ] || [ ! -f "$logfile" ] || [ ! -r "$logfile" ] || [ ! -s "$logfile" ] && return 1

  # 行数为数字且大于0
  [[ "$last_line_count" =~ ^[0-9]+$ ]] && [ "$last_line_count" -gt 0 ] || return 1

  # 执行匹配
  tail -n "$last_line_count" "$logfile" | grep -E -q "$pattern" 2>/dev/null

  return $?
}

# 提取 JMeter 版本号
# 参数: 日志文件
# 返回: 版本号
get_jmeter_version() {
  local logfile=$1
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$logfile" | head -n 1
}

# 标准的容器测试流程
# 参数: 待测镜像 行数 正则表达式
# 返回: 0-成功, 1-失败
test_docker_container() {
  local image="$1"
  local last_line_count="${2:-1}"
  local pattern="$3"
  local container_name="test-jmeter"
  local logfile="entrypoint.log"

  # 1. 拉取
  docker pull "${image}" || {
    error "拉取镜像失败"
    return 1
  }
  # 2. 启动
  docker run -d -v "${logfile}:/var/log/entrypoint.log" --name "${container_name}" "${image}" || {
    error "启动容器失败"
    return 1
  }
  # 3. 等待容器内服务运行稳定
  sleep 30
  # 4. 停止
  docker stop "${container_name}" || {
    error "停止容器失败"
    return 1
  }
  # 5. 删除
  docker rm "${container_name}" || {
    error "删除容器失败"
    return 1
  }

  # 日志断言
  if ! check_logfile_pattern "${logfile}" "${last_line_count}" "${pattern}"; then
    error "日志断言失败"
    cat "${logfile}" && rm "${logfile}"
    return 1
  else
    info "${image} 测试通过"
    rm "${logfile}"
    return 0
  fi
}

# ------------ TEST --------------

# 冒烟测试
test_smoke() {
  info "冒烟测试 - JMeter ${JMETER_VERSION} (SHA: ${GIT_COMMIT_SHA})"

  test_docker_container "$TARGET_IMAGE" 100 "JMeter ${JMETER_VERSION} started"

  info "冒烟测试通过"
}

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --JMeter)
        JMETER_VERSION="$2"
        shift 2
        ;;
      --OS)
        TAG_OS="$2"
        shift 2
        ;;
      --JRE)
        TAG_JRE="$2"
        shift 2
        ;;
      --GUI)
        TAG_GUI="$2"
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

  export TARGET_IMAGE="${REGISTRY}/${IMAGE_BASE}:${JMETER_VERSION}-${TAG_OS}-${TAG_JRE}-${TAG_GUI}-${GIT_COMMIT_SHA}"
}

main() {
  parse_args "$@"

  # 运行所有测试
  test_smoke

  log_info "所有测试通过!"
}

main "$@"
