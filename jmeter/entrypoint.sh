#!/bin/bash

# =================================================
# Entry Point Script for JMeter Docker Container
#
# This script sets up and runs JMeter in various modes including:
# - Console mode
# - Server mode
# - Mirror Server mode
# - Custom commands
# - Server Agent for monitoring
# - VNC/NoVNC Server
# - RDP Server
# =================================================

# ------------ Constants (Do not modify) ----------
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.*}.lock"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"

# Colors for logging (if terminal supports it)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ------------ Initialization --------------------
# Ensure script exits on error and unset variables
set -euo pipefail

# ------------ Function Definitions --------------
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
log_error()   { log "ERROR" "$1"; }
log_success() { log "SUCCESS" "$1"; }

log_section() {
  log_info "========================================"
  log_info "$1"
  log_info "========================================"
}

# Create lock file to prevent multiple instances
create_lock() {
  if [ -f "$LOCK_FILE" ]; then
    log_error "Lock file exists: $LOCK_FILE. Another instance may be running."
    exit 1
  fi
  touch "$LOCK_FILE"
  trap 'rm -f "$LOCK_FILE"' EXIT
}

# Get container memory limit in MB
get_container_memory_limit() {
  local mem_limit
  local max_sane_memory=$(( 128 * 1024 * 1024 * 1024 )) # 128GB in bytes (防止极端值)

  # 1. 优先检查 cgroup v2 (Alpine 3.x+/Ubuntu 22.04+ 默认)
  if [ -f "/sys/fs/cgroup/memory.max" ]; then
    mem_limit=$(cat /sys/fs/cgroup/memory.max)
    [ "$mem_limit" = "max" ] && mem_limit=$(awk '/MemTotal/ { print int($2 * 1024) }' /proc/meminfo)

  # 2. 检查 cgroup v1 (旧版 Docker/Kubernetes)
  elif [ -f "/sys/fs/cgroup/memory/memory.limit_in_bytes" ]; then
    mem_limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

  # 3. 非容器环境或 systemd 容器 (Ubuntu 24.04 可能用 systemd)
  elif [ -f "/proc/self/cgroup" ] && grep -q "memory:" /proc/self/cgroup; then
    local cgroup_path=$(grep "memory:" /proc/self/cgroup | cut -d: -f3)
    if [ -f "/sys/fs/cgroup/memory$cgroup_path/memory.limit_in_bytes" ]; then
      mem_limit=$(cat "/sys/fs/cgroup/memory$cgroup_path/memory.limit_in_bytes")
    else
      mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
    fi

  # 4. 兜底方案 (非容器环境)
  else
    mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
  fi

  # 5. 处理超大的内存限制 (如 Kubernetes 未设限时可能返回 2^64)
  if [ "$mem_limit" -gt "$max_sane_memory" ]; then
    mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
  fi

  # 6. 转换为 MB (并确保最小值为 256MB)
  mem_limit=$(( mem_limit / 1024 / 1024 ))
  [ "$mem_limit" -lt 256 ] && mem_limit=256

  echo "$mem_limit"
}

# Get Java version
get_java_version() {
  local java_version
  if command -v java > /dev/null 2>&1; then
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "$java_version"
  else
    echo "ERROR: Java not found in PATH!" >&2
    exit 1
  fi
}

# Calculate and set JVM memory parameters
calculate_jvm_memory() {
  local container_mem=$(get_container_memory_limit)
  local java_version=$(get_java_version)
  local jvm_opts=""

  log_info "Container memory limit: ${container_mem} MB"

  # Extract major version (e.g., "1.8.0_312" → 8, "11.0.14" → 11)
  local major_version
  if [[ "$java_version" =~ ^1\.8 ]]; then
    major_version=8
  else
    major_version=$(echo "$java_version" | cut -d '.' -f 1)
  fi

  # Java 8u131+ needs explicit container support
  if [ "$major_version" -eq 8 ]; then
    jvm_opts="-XX:+UseContainerSupport"
    # Use 70% of container memory for heap
    local heap_size=$(( container_mem * 70 / 100 ))
    jvm_opts="$jvm_opts -Xms${heap_size}m -Xmx${heap_size}m"
  # Java 10+ supports dynamic memory allocation
  elif [ "$major_version" -ge 10 ]; then
    jvm_opts="-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"
  else
    # Fallback for other versions
    local heap_size=$(( container_mem * 70 / 100 ))
    jvm_opts="-Xms${heap_size}m -Xmx${heap_size}m"
  fi

  # Common JVM optimizations
  jvm_opts="$jvm_opts -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/heapdump.hprof"

  export JVM_ARGS=${jvm_opts}
}

# Copy custom plugins to JMeter
copy_plugins() {
  if [[ -d "${JMETER_CUSTOM_PLUGINS_FOLDER:-}" ]]; then
    log_section "Copying custom JMeter plugins"
    local plugin_count=0

    for plugin in "${JMETER_CUSTOM_PLUGINS_FOLDER}"/*.jar; do
      if [ -f "$plugin" ]; then
        cp -v "$plugin" "${JMETER_HOME}/lib/ext/" >> "$LOG_FILE" 2>&1
        ((plugin_count++))
      fi
    done

    log_info "Copied $plugin_count plugin(s) to JMeter"
  fi
}

# Run JMeter in Console mode
run_jmeter() {
  log_section "Starting JMeter in Console mode"

  local args=(
    -Dlog4j2.formatMsgNoLookups=true
  )

  [ $# -eq 0 ] && { log_error "No test file or arguments provided (usage: jmeter <test.jmx> [options])"; exit 1; }

  log_info "Using JVM Args: $JVM_ARGS"
  log_info "Using JMeter Args: ${args[*]}"
  [ $# -gt 0 ] && log_info "Using Additional Args: $*"

  exec jmeter "${args[@]}" "$@"
}

# Run JMeter Server
run_jmeter_server() {
  log_section "Starting JMeter Server"

  local args=(
    -Dlog4j2.formatMsgNoLookups=true
    -Dserver_port=1099
    -Dserver.rmi.localport=50000
    -Dserver.rmi.ssl.disable=true
  )

  log_info "Using JVM Args: $JVM_ARGS"
  log_info "Using JMeter Server Args: ${args[*]}"
  [ $# -gt 0 ] && log_info "Using Additional Args: $*"

  exec jmeter-server "${args[@]}" "$@"
}

# Run Mirror Server
run_mirror_server() {
  log_section "Starting Mirror Server"

  local args=(
    --port 8080
    --loglevel INFO
  )

  log_info "Using JVM Args: $JVM_ARGS"
  log_info "Using Mirror Server Args: ${args[*]}"
  [ $# -gt 0 ] && log_info "Using Additional Args: $*"

  exec mirror-server "${args[@]}" "$@"
}

# Run custom command
run_custom_command() {
  log_section "Run Custom Command"

  [ $# -eq 0 ] && { log_error "No command provided"; exit 1; }

  log_info "Executing: $*"
  exec "$@"
}

# Keep container alive
run_keepalive() {
  log_section "Keepalive mode"

  log_info "Container will remain running indefinitely"

  exec tail -f /dev/null
}

# Run Server Agent
run_server_agent() {
  log_section "Starting Server Agent"

  local agent_home=${SERVER_AGENT_HOME:-"/opt/ServerAgent"}
  local interval=${SA_INTERVAL:-5}
  local script="${agent_home}/startAgent.sh"

  if [ ! -f "$script" ]; then
    log_error "Server Agent script not found at $script"
    exit 1
  fi

  log_info "Starting Server Agent with interval ${interval}s"
  exec /bin/bash "$script" --udp-port 4444 --tcp-port 4444 --interval "$interval"
}

# Run VNC Server
run_vnc_server() {
  log_section "Starting VNC Server"

  # Set default username
  local username="${VNC_USERNAME:-jmeter}"

  # Use environment variable or generate random password
  if [[ -n "${VNC_PASSWORD:-}" ]]; then
    log_info "Using password from environment variable"
  else
    VNC_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
    log_info "Generated random password: $VNC_PASSWORD"
  fi

  # Check if user exists, if not create it
  if ! id $username >/dev/null 2>&1; then
    if ! groupadd --gid 1024 $username; then
      log_error "Failed to create $username group"
      exit 1
    fi
    if ! useradd --shell /bin/bash --uid 1024 --gid 1024 --groups sudo \
                 --password $(openssl passwd -6 "$VNC_PASSWORD") \
                 --create-home --home-dir /home/$username $username; then
      log_error "Failed to create $username user"
      exit 1
    fi
    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    visudo -c || {
      log_error "Invalid sudoers file after modification"
      exit 1
    }
  fi

  # Prepare VNC password file
  mkdir -p /home/$username/.vnc || {
    log_error "Failed to create /home/$username/.vnc directory"
    exit 1
  }

  echo "$VNC_PASSWORD" | vncpasswd -f > /home/$username/.vnc/passwd || {
    log_error "Failed to generate VNC password file"
    exit 1
  }
  chmod 600 /home/$username/.vnc/passwd || {
    log_error "Failed to set permissions on VNC password file"
    exit 1
  }

  # Generate self-signed certificate
  mkdir -p /opt/novnc/certs || {
    log_error "Failed to create SSL private directory"
    exit 1
  }

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 \
    -keyout /opt/novnc/certs/vnc.key -out /opt/novnc/certs/vnc.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost" || {
    log_error "Failed to generate self-signed certificate"
    exit 1
  }

  if ! /usr/bin/supervisord --nodaemon 2>&1; then
    log_error "Failed to start supervisord"
    exit 1
  fi
}

# Run RDP Server
run_rdp_server() {
  log_section "Starting RDP Server"

  # Check if user 'jmeter' exists, if not create it
  if ! id jmeter >/dev/null 2>&1; then
    if ! groupadd --gid 1024 jmeter; then
      log_error "Failed to create jmeter group"
      exit 1
    fi
    if ! useradd --shell /bin/bash --uid 1024 --gid 1024 --groups sudo \
                 --password $(openssl passwd -6 "jmeter") \
                 --create-home --home-dir /home/jmeter jmeter; then
      log_error "Failed to create jmeter user"
      exit 1
    fi
    echo "jmeter ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    visudo -c || {
      log_error "Invalid sudoers file after modification"
      exit 1
    }
  fi

  # Remove existing sesman/xrdp PID files to prevent rdp sessions hanging on container restart
  [ ! -f /var/run/xrdp/xrdp-sesman.pid ] || rm -f /var/run/xrdp/xrdp-sesman.pid
  [ ! -f /var/run/xrdp/xrdp.pid ] || rm -f /var/run/xrdp/xrdp.pid

  if ! service dbus start > /var/log/dbus-start.log 2>&1; then
    log_error "Failed to start dbus service"
    exit 1
  fi

  if ! /usr/sbin/xrdp-sesman 2>&1; then
    log_error "Failed to start xrdp-sesman service"
    exit 1
  fi

  if ! /usr/sbin/xrdp --nodaemon 2>&1; then
    log_error "Failed to start xrdp service"
    exit 1
  fi
}

# Run NoMachine Server
run_nomachine_server() {
  log_section "Starting NoMachine Server"

  # Set default username
  local username="${NOMACHINE_USERNAME:-jmeter}"

  # Use environment variable or generate random password
  if [[ -n "${NOMACHINE_PASSWORD:-}" ]]; then
    log_info "Using password from environment variable"
  else
    NOMACHINE_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
    log_info "Generated random password: $NOMACHINE_PASSWORD"
  fi

  # Check if user exists, if not create it
  if ! id $username >/dev/null 2>&1; then
    if ! groupadd --gid 1024 $username; then
      log_error "Failed to create $username group"
      exit 1
    fi
    if ! useradd --shell /bin/bash --uid 1024 --gid 1024 --groups sudo \
                 --password $(openssl passwd -6 "$NOMACHINE_PASSWORD") \
                 --create-home --home-dir /home/$username $username; then
      log_error "Failed to create $username user"
      exit 1
    fi
    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    visudo -c || {
      log_error "Invalid sudoers file after modification"
      exit 1
    }
  fi

  if ! /etc/init.d/dbus start 2>&1; then
    log_error "Failed to start dbus"
    exit 1
  fi

  if ! /etc/NX/nxserver --startup 2>&1; then
    log_error "Failed to start NoMachine server"
    exit 1
  fi

  exec tail -f /usr/NX/var/log/nxserver.log
}

# Show help
show_help() {
  cat <<EOF
Usage: $SCRIPT_NAME <mode> [options]

Available modes:
jmeter          Run JMeter in Console mode
jmeter-server   Run JMeter in Server mode
mirror-server   Run Mirror Server
customize       Run custom commands
keepalive       Just keep container alive
server-agent    Run Server Agent for monitoring
vnc             Start VNC/NoVNC server
rdp             Start RDP server
nomachine       Start NoMachine server

Environment Variables:
JMETER_HOME                  - Path to JMeter installation (required)
JMETER_CUSTOM_PLUGINS_FOLDER - Path to custom JMeter plugins
SERVER_AGENT_HOME            - Path to Server Agent installation
SA_INTERVAL                  - Server Agent polling interval (default: 5s)
VNC_PASSWORD                 - Password for VNC server (if not set, a random password will be generated)
EOF
}

# ------------ Main Script ------------
main() {
  create_lock

  log_section "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  log_info "Running as $(id)"

  calculate_jvm_memory
  copy_plugins

  log_info "Java   version: $(java -version 2>&1 | head -1)"
  log_info "JMeter version: $(jmeter -v 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)"
  log_info "JMeter HOME: $JMETER_HOME"
  log_info "JVM args: $JVM_ARGS"
  log_info "Log file: $LOG_FILE"

  if [ $# -eq 0 ]; then
    show_help
    exit 1
  fi

  local mode=$1
  shift

  case $mode in
    jmeter)         run_jmeter "$@" ;;
    jmeter-server)  run_jmeter_server "$@" ;;
    mirror-server)  run_mirror_server "$@" ;;
    customize)      run_custom_command "$@" ;;
    keepalive)      run_keepalive ;;
    server-agent)   run_server_agent ;;
    vnc)            run_vnc_server ;;
    rdp)            run_rdp_server ;;
    nomachine)      run_nomachine_server ;;
    help|--help|-h) show_help ;;
    *) 
      log_error "Unknown mode: $mode"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
