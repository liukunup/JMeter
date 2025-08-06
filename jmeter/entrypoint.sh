#!/bin/bash

# =============================================
# Entry Point Script for JMeter Docker Container
# 
# This script sets up and runs JMeter in various modes including:
# - GUI mode
# - Server mode
# - Mirror Server mode
# - Custom commands
# - Server agent for monitoring
# - VNC/NoVNC Server
# - RDP Server
# =============================================

# ------------ Constants (Do not modify) ------------
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"

# ------------ Initialization ------------
# Ensure script exits on error and unset variables
set -o errexit
set -o nounset
set -o pipefail

# ------------ Function Definitions ------------
log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  local log_entry="[$level] $timestamp - ${message}"

  # Always write to log file (no color codes)
  echo "$log_entry" >> "$LOG_FILE"

  # Write to stderr (with color for terminal)
  if [ -t 2 ]; then
      case $level in
          ERROR)   echo -e "\033[1;31m${log_entry}\033[0m" >&2 ;;
          WARNING) echo -e "\033[1;33m${log_entry}\033[0m" >&2 ;;
          SUCCESS) echo -e "\033[1;32m${log_entry}\033[0m" >&2 ;;
          INFO)    echo -e "\033[1;34m${log_entry}\033[0m" >&2 ;;
          *)       echo "$log_entry" >&2 ;;
      esac
  else
      echo "$log_entry" >&2
  fi
}

# Specific log level functions
log_info()    { log "INFO" "$1"; }
log_warning() { log "WARNING" "$1"; }
log_error()   { log "ERROR" "$1"; }
log_success() { log "SUCCESS" "$1"; }

# Section headers
log_section() {
    log_info "========================================"
    log_info "$1"
    log_info "========================================"
}

# Copy custom plugins to JMeter ext folder if the custom plugins folder exists
if [[ -d $JMETER_CUSTOM_PLUGINS_FOLDER ]]
then
  for plugin in "${JMETER_CUSTOM_PLUGINS_FOLDER}"/*.jar; do
    cp "$plugin" "${JMETER_EXT}"
  done;
fi

# Set JVM parameters
set -e
freeMem=$(awk '/MemAvailable/ { print int($2/1024) }' /proc/meminfo)
# Assign default values if variables are empty
[[ -z ${JVM_XMN} ]] && JVM_XMN=$((freeMem * 2 / 10))
[[ -z ${JVM_XMS} ]] && JVM_XMS=$((freeMem * 8 / 10))
[[ -z ${JVM_XMX} ]] && JVM_XMX=$((freeMem * 8 / 10))
# Assemble JVM parameters
[[ -z ${JVM_ARGS} ]] && JVM_ARGS="-Xmn${JVM_XMN}m -Xms${JVM_XMS}m -Xmx${JVM_XMX}m"
# Export JVM parameters as environment variable
export JVM_ARGS=${JVM_ARGS}

# Run JMeter
function run_jmeter() {
  log_section "Starting JMeter in Console mode"

  local args=("$@")
  [ ${#args[@]} -eq 0 ] && log_warning "No arguments provided to JMeter"

  log_info "JVM args: $JVM_ARGS"
  log_info "JMeter args: ${args[*]}"

  jmeter -Dlog4j2.formatMsgNoLookups=true "${args[@]}"
}

# Run JMeter Server
function run_jmeter_server() {
  log_section "Starting JMeter Server"

  local args=("$@")
  local server_args=(
    -Dlog4j2.formatMsgNoLookups=true
    -Dserver_port=1099
    -Dserver.rmi.localport=50000
    -Dserver.rmi.ssl.disable=true
  )

  log_info "JVM args: $JVM_ARGS"
  log_info "Server args: ${server_args[*]}"
  log_info "Additional args: ${args[*]}"

  jmeter-server "${server_args[@]}" "${args[@]}"
}

# Run Mirror server
function run_mirror_server() {
  log_section "Starting Mirror Server"

  local args=("$@")
  local mirror_args=(
      -Dlog4j2.formatMsgNoLookups=true
      --port 8080
  )

  log_info "JVM args: $JVM_ARGS"
  log_info "Mirror Server args: ${mirror_args[*]}"
  log_info "Additional args: ${args[*]}"

  mirror-server "${mirror_args[@]}" "${args[@]}"
}

# Run custom command
function run_custom_command() {
  log_section "Running Custom Command"
  
  if [ $# -eq 0 ]; then
      log_error "No command specified"
      return 1
  fi

  log_info "Executing: $*"
  eval "$@"
}

# Keep container alive
function func_keepalive() {
  log_section "Keepalive Mode"
  log_info "Container will remain running indefinitely"
  tail -f /dev/null
}

# Run Server Agent
function run_server_agent() {
  log_section "Starting Server Agent"

  local agent_home=${SERVER_AGENT_HOME:-"/opt/server-agent"}
  local interval=${SA_INTERVAL:-5}
  local script="${agent_home}/startAgent.sh"

  if [ ! -f "$script" ]; then
      log_error "Server Agent script not found at $script"
      return 1
  fi

  log_info "Starting Server Agent with interval ${interval}s"
  /bin/bash "$script" --udp-port 4444 --tcp-port 4444 --interval "$interval"
}

# Run VNC/NoVNC Server
function run_vnc_server() {
  log_section "start VNC/NoVNC Server"

  local LOG_DIR="/var/log/vnc"
  local XVFB_DISPLAY=":1"
  local VNC_PORT=5900
  local NOVNC_PORT=6080
  local SCREEN_RESOLUTION="1280x800x16"

  log_info "Display: $XVFB_DISPLAY | VNC Port: $VNC_PORT | NoVNC Port: $NOVNC_PORT"
  
  # 创建日志目录
  mkdir -p "$LOG_DIR" || {
    log_error "Failed to create log directory: $LOG_DIR"
    return 1
  }

  # 优先使用环境变量设置值，否则生成随机密码
  if [[ -n "${VNC_PASSWORD}" ]]; then
    log_info "Using VNC password from environment variable VNC_PASSWORD"
    local PASSWORD_SOURCE="Environment variable"
  else
    # 生成随机密码 (12个字符，包含大小写字母和数字)
    VNC_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
    local PASSWORD_SOURCE="Automatically generated"
    log_info "Generated random VNC password: $VNC_PASSWORD"
  fi

  # 将密码保存到临时文件以便后续使用
  local PASSWD_FILE=$(mktemp)
  echo "$VNC_PASSWORD" > "$PASSWD_FILE"

  # 准备VNC目录和密码文件
  mkdir -p ~/.vnc || {
    log_error "Failed to create ~/.vnc directory"
    rm -f "$PASSWD_FILE"
    return 1
  }

  if ! echo "$VNC_PASSWORD" | vncpasswd -f > ~/.vnc/passwd; then
    log_error "Failed to generate VNC password file"
    rm -f "$PASSWD_FILE"
    return 1
  fi
  chmod 600 ~/.vnc/passwd || {
    log_error "Failed to set permissions on VNC password file"
    rm -f "$PASSWD_FILE"
    return 1
  }

  # 启动Xvfb虚拟显示器
  log_info "Starting Xvfb on display $XVFB_DISPLAY"
  Xvfb "$XVFB_DISPLAY" -screen 0 "$SCREEN_RESOLUTION" -ac -nolisten tcp \
    > "$LOG_DIR/Xvfb.log" 2>&1 &
  local XVFB_PID=$!
  
  # 等待Xvfb启动
  sleep 2
  if ! kill -0 "$XVFB_PID" >/dev/null 2>&1; then
    log_error "Xvfb failed to start. Check $LOG_DIR/Xvfb.log for details"
    rm -f "$PASSWD_FILE"
    return 1
  fi
  export DISPLAY="$XVFB_DISPLAY"

  # 启动x11vnc服务器
  log_info "Starting x11vnc on port $VNC_PORT"
  x11vnc -forever -usepw -display "$XVFB_DISPLAY" -rfbport "$VNC_PORT" \
    -bg -o "$LOG_DIR/x11vnc.log" -noxdamage \
    -passwdfile "$PASSWD_FILE" || {
    log_error "Failed to start x11vnc"
    rm -f "$PASSWD_FILE"
    return 1
  }

  # 启动NoVNC
  log_info "Starting NoVNC on port $NOVNC_PORT"
  websockify --web /usr/share/novnc "$NOVNC_PORT" "localhost:$VNC_PORT" \
    > "$LOG_DIR/novnc.log" 2>&1 &
  local NOVNC_PID=$!

  # 验证服务是否运行
  sleep 1
  if ! kill -0 "$NOVNC_PID" >/dev/null 2>&1; then
    log_error "NoVNC failed to start. Check $LOG_DIR/novnc.log for details"
    rm -f "$PASSWD_FILE"
    return 1
  fi

  # 清理临时密码文件
  rm -f "$PASSWD_FILE"

  # 输出连接信息
  echo "VNC/NoVNC Server started successfully"
  echo "================================================"
  echo "VNC Connection:"
  echo "  Address: localhost:$VNC_PORT"
  echo "  Password: $VNC_PASSWORD (${PASSWORD_SOURCE})"
  echo ""
  echo "NoVNC (Web) Connection:"
  echo "  URL: http://localhost:$NOVNC_PORT/vnc.html"
  echo "  Password: $VNC_PASSWORD (${PASSWORD_SOURCE})"
  echo "================================================"

  # Keep the script running to maintain the RDP server
  wait
}

# Run RDP Server
function run_rdp_server() {
  log_section "Starting RDP Server"

  # Prepare X session
  echo "xfce4-session" > ~/.xsession || {
    log_error "Failed to create ~/.xsession file"
    return 1
  }

  # Start xrdp service
  if ! service xrdp start > /var/log/xrdp-start.log 2>&1; then
    log_error "Failed to start xrdp service"
    return 1
  fi
  log_info "RDP Server started successfully"
  log_info "RDP Server is running on port 3389"

  tail -f /var/log/xrdp.log /var/log/xrdp-sesman.log &

  # Keep the script running to maintain the RDP server
  wait
}

# Show help
show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME <mode> [options]

Available modes:
  jmeter          Run JMeter in GUI mode
  jmeter-server   Run JMeter in server mode
  mirror-server   Run mirror server
  customize       Run custom command
  keepalive       Keep container alive
  server-agent    Run Server Agent for monitoring
  vnc             Start VNC/NoVNC server
  rdp             Start RDP server

Environment Variables:
  JMETER_HOME               - Path to JMeter installation (required)
  JMETER_CUSTOM_PLUGINS_FOLDER - Path to custom JMeter plugins
  JVM_XMS, JVM_XMX, JVM_XMN - JVM memory settings
  VNC_PASSWORD              - Password for VNC server
EOF
}

# ------------ Main Script ------------

main() {
  create_lock
  validate_env
  calculate_jvm_memory
  copy_plugins

  log_section "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
  log_info "Running as: $(id)"
  log_info "Log file: $LOG_FILE"
  
  if [ $# -eq 0 ]; then
      show_help
      exit 1
  fi
  
  local mode=$1
  shift
  
  case $mode in
      jmeter)        run_jmeter "$@" ;;
      jmeter-server) run_jmeter_server "$@" ;;
      mirror-server) run_mirror_server "$@" ;;
      customize)     run_custom_command "$@" ;;
      keepalive)     run_keepalive ;;
      server-agent)  run_server_agent ;;
      vnc)           run_vnc_server ;;
      rdp)           run_rdp_server ;;
      help|--help|-h) show_help ;;
      *) 
          log_error "Unknown mode: $mode"
          show_help
          exit 1
          ;;
  esac
  
  log_success "Operation completed successfully"
}

main "$@"
