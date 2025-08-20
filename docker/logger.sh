#!/bin/bash
# brief : logger
# author: Liu Kun
# email : liukunup@outlook.com
# date  : 2025/08/18 20:08:07

# 确保出错时立即退出
set -euo pipefail

# ==================================================
# 日志工具类
# ==================================================
# 使用说明
#
# 1. 引入日志工具类
# source logger.sh
#
# 2. 示例用法
# debug "这是一条调试信息"
# info "这是一条普通信息"
# warn "这是一条警告信息"
# error "这是一条错误信息"
# critical "这是一条严重错误信息"
#
# 3. 设置环境变量来改变行为
# export LOG_LEVEL="DEBUG" # 设置日志级别
# export LOG_FILE="/var/log/myapp.log" # 设置日志文件
# export LOG_SHOW_CALLER="false" # 禁用调用者信息显示
# ==================================================

# 定义日志级别
declare -A LOG_LEVELS=(
  ["DEBUG"]=0
  ["INFO"]=1
  ["WARN"]=2
  ["ERROR"]=3
  ["CRITICAL"]=4
)

# 默认日志级别 (INFO)
LOG_LEVEL=${LOG_LEVEL:-"INFO"}

# 定义颜色常量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志文件路径 (设置为空则不写入文件)
LOG_FILE=${LOG_FILE:-""}

# 确保日志文件目录存在
_ensure_log_dir() {
  if [ -n "$LOG_FILE" ]; then
    local log_dir=$(dirname "$LOG_FILE")
    if [ ! -d "$log_dir" ]; then
      mkdir -p "$log_dir" 2>/dev/null || {
        echo -e "${RED}ERROR: 无法创建日志目录: $log_dir${NC}" >&2
        LOG_FILE=""  # 禁用文件日志
        return 1
      }
    fi
    # 确保文件可写
    touch "$LOG_FILE" 2>/dev/null || {
      echo -e "${RED}ERROR: 无法写入日志文件: $LOG_FILE${NC}" >&2
      LOG_FILE=""  # 禁用文件日志
      return 1
    }
  fi
}

# 获取当前时间戳
_get_timestamp() {
  echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

# 获取调用者信息
_get_caller_info() {
  local caller_info=""
  if [ "${LOG_SHOW_CALLER:-true}" = "true" ]; then
    local caller_file="${BASH_SOURCE[3]}"
    local caller_line="${BASH_LINENO[2]}"
    # caller_info="[${caller_file}:${caller_line}]"
    caller_info="[$(basename ${caller_file}):${caller_line}]"
  fi
  echo "$caller_info"
}

# 日志函数
log() {
  local level=$1
  shift
  local message="$*"
  local timestamp=$(_get_timestamp)
  local caller_info=$(_get_caller_info)

  # 检查日志级别是否足够
  if [ ${LOG_LEVELS[$level]} -lt ${LOG_LEVELS[$LOG_LEVEL]} ]; then
    return 0
  fi

  # 设置颜色
  local color=""
  case "$level" in
    "DEBUG") color="${CYAN}" ;;
    "INFO") color="${GREEN}" ;;
    "WARN") color="${YELLOW}" ;;
    "ERROR") color="${RED}" ;;
    "CRITICAL") color="${PURPLE}" ;;
    *) color="${NC}" ;;
  esac

  # 控制台输出
  local log_line="[${timestamp}] ${color}${level}${NC} - ${caller_info} ${message}"
  echo -e "$log_line"

  # 文件输出 (无颜色)
  if [ -n "$LOG_FILE" ]; then
    local file_line="[${timestamp}] ${level} - ${caller_info} ${message}"
    echo -e "$file_line" >> "$LOG_FILE"
  fi
}

# 快捷函数
debug() { log "DEBUG" "$@"; }
info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }
critical() { log "CRITICAL" "$@"; }

# 初始化日志目录（如果设置了LOG_FILE）
_ensure_log_dir
