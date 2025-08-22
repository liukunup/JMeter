#!/bin/bash

# set -x  # Uncomment for debugging

# Ensure script exits on error and unset variables
set -euo pipefail

# =================================================
# Entry Point Script for JMeter Docker Container
#
# This script sets up and runs JMeter in various modes including:
# - Console
# - Server
# - Mirror Server
# - Custom commands
# - Server Agent for monitoring
# - VNC and NoVNC
# - RDP
# - NoMachine
# =================================================

# ------------ Constants (Do not modify) ----------
readonly SCRIPT_VERSION="1.0.0"
# shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}") || exit 1
readonly LOCK_FILE="/tmp/${SCRIPT_NAME%.*}.lock"

# ------------ Environment Variables --------------
# JMeter home directory
: "${JMETER_HOME:=/opt/jmeter}"
# Display settings
: "${DISPLAY:=:0}"
: "${RESOLUTION:=1280x720}"
: "${DEPTH:=24}"
# Default user is 'jmeter' if not set
: "${DEFAULT_USER:=jmeter}"
# Username and Password for various services
: "${VNC_USERNAME:=}"
: "${VNC_PASSWORD:=}"
: "${RDP_USERNAME:=}"
: "${RDP_PASSWORD:=}"
: "${NM_USERNAME:=}"
: "${NM_PASSWORD:=}"

# ------------ Toolkit ------------

# Load logger if available, else define basic logging functions
LOGGER_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/logger.sh"
if [[ -f "${LOGGER_SCRIPT}" && -r "${LOGGER_SCRIPT}" ]]; then
  # shellcheck disable=SC1090
  source "${LOGGER_SCRIPT}"
  export LOG_LEVEL="DEBUG"
  export LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"
else
  debug()    { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[DEBUG] ${timestamp} - $*"; }
  info()     { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[INFO] ${timestamp} - $*"; }
  warn()     { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[WARN] ${timestamp} - $*"; }
  error()    { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[ERROR] ${timestamp} - $*"; }
  critical() { local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S') || return 1; echo "[CRITICAL] ${timestamp} - $*"; }
fi

# Create lock file to prevent multiple instances
create_lock() {
  if [[ -f "${LOCK_FILE}" ]]; then
    error "Lock file exists: ${LOCK_FILE}. Another instance may be running."
    exit 1
  fi
  touch "${LOCK_FILE}"
  trap 'rm -f "$LOCK_FILE"' EXIT
}

# Get container memory limit in MB
get_container_memory_limit() {
  local mem_limit
  local max_sane_memory=$(( 128 * 1024 * 1024 * 1024 )) # 128GB in bytes (防止极端值)

  # 1. 优先检查 cgroup v2 (Alpine 3.x+/Ubuntu 22.04+ 默认)
  if [[ -f "/sys/fs/cgroup/memory.max" ]]; then
    mem_limit=$(cat /sys/fs/cgroup/memory.max)
    [[ "${mem_limit}" = "max" ]] && mem_limit=$(awk '/MemTotal/ { print int($2 * 1024) }' /proc/meminfo)

  # 2. 检查 cgroup v1 (旧版 Docker/Kubernetes)
  elif [[ -f "/sys/fs/cgroup/memory/memory.limit_in_bytes" ]]; then
    mem_limit=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

  # 3. 非容器环境或 systemd 容器 (Ubuntu 24.04 可能用 systemd)
  elif [[ -f "/proc/self/cgroup" ]] && grep -q "memory:" /proc/self/cgroup; then
    local cgroup_path
    cgroup_path=$(grep "memory:" /proc/self/cgroup | cut -d: -f3)
    if [[ -f "/sys/fs/cgroup/memory${cgroup_path}/memory.limit_in_bytes" ]]; then
      mem_limit=$(cat "/sys/fs/cgroup/memory${cgroup_path}/memory.limit_in_bytes")
    else
      mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
    fi

  # 4. 兜底方案 (非容器环境)
  else
    mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
  fi

  # 5. 处理超大的内存限制 (如 Kubernetes 未设限时可能返回 2^64)
  if [[ "${mem_limit}" -gt "${max_sane_memory}" ]]; then
    mem_limit=$(awk '/MemTotal/ { print int($2 * 1024 * 0.8) }' /proc/meminfo)
  fi

  # 6. 转换为 MB (并确保最小值为 256MB)
  mem_limit=$(( mem_limit / 1024 / 1024 ))
  [[ "${mem_limit}" -lt 256 ]] && mem_limit=256

  echo "${mem_limit}"
}

# Get Java version
get_java_version() {
  local java_version
  if command -v java > /dev/null 2>&1; then
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "${java_version}"
  else
    error "ERROR: Java not found in PATH!"
    exit 1
  fi
}

# Calculate and set JVM memory parameters
calculate_jvm_memory() {
  local container_mem
  local java_version
  local jvm_opts=""

  container_mem=$(get_container_memory_limit)
  java_version=$(get_java_version)

  info "Container memory limit: ${container_mem} MB"

  # Extract major version (e.g., "1.8.0_312" → 8, "11.0.14" → 11)
  local major_version
  if [[ "${java_version}" =~ ^1\.8 ]]; then
    major_version=8
  else
    major_version=$(echo "${java_version}" | cut -d '.' -f 1)
  fi

  # Java 8u131+ needs explicit container support
  if [[ "${major_version}" -eq 8 ]]; then
    jvm_opts="-XX:+UseContainerSupport"
    # Use 70% of container memory for heap
    local heap_size=$(( container_mem * 70 / 100 ))
    jvm_opts="${jvm_opts} -Xms${heap_size}m -Xmx${heap_size}m"
  # Java 10+ supports dynamic memory allocation
  elif [[ "${major_version}" -ge 10 ]]; then
    jvm_opts="-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"
  else
    # Fallback for other versions
    local heap_size=$(( container_mem * 70 / 100 ))
    jvm_opts="-Xms${heap_size}m -Xmx${heap_size}m"
  fi

  # Common JVM optimizations
  jvm_opts="${jvm_opts} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp/heapdump.hprof"

  export JVM_ARGS=${jvm_opts}
}

# Copy custom plugins to JMeter
copy_plugins() {
  if [[ -d "${JMETER_CUSTOM_PLUGINS_DIR:-}" ]]; then
    info "=========================================="
    info "Copying custom JMeter plugins"
    info "=========================================="
    local plugin_count=0

    for plugin in "${JMETER_CUSTOM_PLUGINS_DIR}"/*.jar; do
      if [[ -f "${plugin}" ]]; then
        cp -v "${plugin}" "${JMETER_HOME}/lib/ext/" >> "${LOG_FILE}" 2>&1
        ((plugin_count++))
      fi
    done

    info "Copied ${plugin_count} plugin(s) to JMeter"
  fi
}

run_jmeter() {
  info "=========================================="
  info "Starting JMeter in Console"
  info "=========================================="

  local args=(
    -Dlog4j2.formatMsgNoLookups=true
  )

  [[ $# -eq 0 ]] && { error "No test file or arguments provided (usage: jmeter <test.jmx> [options])"; exit 1; }

  info "Using JVM Args: ${JVM_ARGS}"
  info "Using JMeter Args: ${args[*]}"
  [[ $# -gt 0 ]] && info "Using Additional Args: $*"

  exec jmeter "${args[@]}" "$@"
}

run_jmeter_server() {
  info "=========================================="
  info "Starting JMeter Server"
  info "=========================================="

  local args=(
    -Dlog4j2.formatMsgNoLookups=true
    -Dserver_port=1099
    -Dserver.rmi.localport=50000
    -Dserver.rmi.ssl.disable=true
  )

  info "Using JVM Args: ${JVM_ARGS}"
  info "Using JMeter Server Args: ${args[*]}"
  [[ $# -gt 0 ]] && info "Using Additional Args: $*"

  exec jmeter-server "${args[@]}" "$@"
}

run_mirror_server() {
  info "=========================================="
  info "Starting Mirror Server"
  info "=========================================="

  local args=(
    --port 8080
    --loglevel INFO
  )

  info "Using JVM Args: ${JVM_ARGS}"
  info "Using Mirror Server Args: ${args[*]}"
  [[ $# -gt 0 ]] && info "Using Additional Args: $*"

  exec mirror-server "${args[@]}" "$@"
}

run_custom_command() {
  info "=========================================="
  info "Run Custom Command"
  info "=========================================="

  [[ $# -eq 0 ]] && { error "No command provided"; exit 1; }

  info "Executing: $*"
  exec "$@"
}

run_keepalive() {
  info "=========================================="
  info "Keepalive mode"
  info "=========================================="

  info "Container will remain running indefinitely"

  exec tail -f /dev/null
}

run_server_agent() {
  info "=========================================="
  info "Starting Server Agent"
  info "=========================================="

  local agent_home=${SERVER_AGENT_HOME:-"/opt/ServerAgent"}
  local interval=${SA_INTERVAL:-5}
  local script="${agent_home}/startAgent.sh"

  if [[ ! -f "${script}" ]]; then
    error "Server Agent script not found at ${script}"
    exit 1
  fi

  info "Starting Server Agent with interval ${interval}s"
  exec /bin/bash "${script}" --udp-port 4444 --tcp-port 4444 --interval "${interval}"
}

# Create user with sudo privileges
create_user() {
  local username="${1:-${DEFAULT_USER}}"
  local password="$2"

  # Check if user exists, if not create it
  if id "${username}" >/dev/null 2>&1; then
    warn "User '${username}' already exists"
    export USERNAME="${username}"

    # If password is provided, update it
    if [[ -n "${password}" ]]; then
      info "Updating password for user '${username}'"

      if ! passwd --stdin "${username}" <<< "${password}" &>/dev/null; then
        error "Failed to update password for user '${username}'"
        return 1
      fi

      info "Password for user '${username}' updated successfully"
      export PASSWORD="${password}"
    else
      export PASSWORD=""
    fi

    return 0
  fi

  # Generate a random password if not provided
  if [[ -z "${password}" ]]; then
    password=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | head -c 12) 2>/dev/null || {
      error "Failed to generate random password"
      return 1
    }
    info "No password provided, generated random password for user '${username}'"
  fi

  # shellcheck disable=SC2155
  local uid=$(shuf -i 2000-60000 -n 1)
  local gid=${uid}

  info "Creating user '${username}' with UID:GID ${uid}:${gid}"

  # Create group
  if ! groupadd --gid "${gid}" "${username}"; then
    error "Failed to create group '${username}' (GID: ${gid})"
    return 1
  fi

  salt=$(openssl rand -base64 12) || {
      error "ERROR: Failed to generate salt"
      return 1
  }

  encrypted_passwd=$(openssl passwd -6 -salt "${salt}" "${password}") || {
      error "ERROR: Password encryption failed"
      return 1
  }

  # Create user with sudo privileges
  if ! useradd --shell /bin/bash \
                --uid "${uid}" \
                --gid "${gid}" \
                --groups sudo \
                --password "${encrypted_passwd}" \
                --create-home \
                --home-dir "/home/${username}" \
                "${username}"; then
    error "Failed to create user '${username}' (UID: ${uid})"
    return 1
  fi

  # Add sudo rule safely
  temp_sudoers=$(mktemp)
  {
      echo "# Temporary sudoers addition for ${username}"
      echo "${username} ALL=(ALL) NOPASSWD: ALL"
  } > "${temp_sudoers}"
  # Validate temporary file
  if ! visudo -cf "${temp_sudoers}" >/dev/null 2>&1; then
      error "Invalid sudoers file"
      rm -f "${temp_sudoers}"
      return 1
  fi
  # Append to /etc/sudoers
  if ! cat "${temp_sudoers}" >> /etc/sudoers; then
      error "Failed to update /etc/sudoers"
      rm -f "${temp_sudoers}"
      return 1
  fi

  # Clean up temporary file
  rm -f "${temp_sudoers}"

  warn "User '${username}' created with password: ${password} (Remember it! You will see it only once)"

  export USERNAME="${username}"
  export PASSWORD="${password}"
}

create_desktop_shortcut() {
  local username="${1:-${DEFAULT_USER}}"
  local user_home="/home/${username}"
  local desktop_shortcut_file="jmeter.desktop"

  # Check if jmeter.desktop already exists
  if [[ -f "${user_home}/Desktop/${desktop_shortcut_file}" ]] || [[ -f "${user_home}/.local/share/applications/${desktop_shortcut_file}" ]]; then
    warn "Desktop shortcut already exists for user '${username}'"
    return 0
  fi

  # Ensure user exists
  if ! id -u "${username}" >/dev/null; then
    error "User '${username}' does not exist"
    return 1
  fi

  info "Creating desktop shortcut file ${desktop_shortcut_file}"
  if ! cat > "${desktop_shortcut_file}" <<'EOL'
[Desktop Entry]
Version=1.0
Type=Application
Name=JMeter
Comment=Load Testing
Exec=%JMETER_HOME%/bin/jmeter.sh
Icon=utilities-terminal
Terminal=false
StartupNotify=true
Categories=Development;
EOL
  then
    error "Failed to create desktop shortcut file"
    return 1
  fi
  sed -i "s|%JMETER_HOME%|${JMETER_HOME}|g" "${desktop_shortcut_file}";

  # Set permissions
  if ! chmod +x "${desktop_shortcut_file}"; then
    error "Failed to make shortcut file executable"
    return 1
  fi

  # Set ownership
  if ! chown "${username}:${username}" "${desktop_shortcut_file}"; then
    error "Failed to set ownership for shortcut file"
    return 1
  fi

  # ----- copy to ~/Desktop -----
  if [[ ! -d "${user_home}/Desktop" ]]; then
    mkdir -p "${user_home}/Desktop" || {
      error "Failed to create directory ${user_home}/Desktop"
      return 1
    }
    chown "${username}:${username}" "${user_home}/Desktop" || {
      error "Failed to set ownership for Desktop directory"
      return 1
    }
  fi

  # Check if shortcut already exists
  if [[ ! -f "${user_home}/Desktop/${desktop_shortcut_file}" ]]; then
    cp "${desktop_shortcut_file}" "${user_home}/Desktop/" || {
      error "Failed to copy desktop shortcut file to ${user_home}/Desktop/"
      return 1
    }
    chown "${username}:${username}" "${user_home}/Desktop/${desktop_shortcut_file}" || {
      error "Failed to set ownership for desktop shortcut file"
      return 1
    }
  fi

  # ----- copy to ~/.local/share/applications/ -----
  if [[ ! -d "${user_home}/.local/share/applications" ]]; then
    mkdir -p "${user_home}/.local/share/applications" || {
      error "Failed to create directory ${user_home}/.local/share/applications"
      return 1
    }
    chown "${username}:${username}" "${user_home}/.local/share/applications" || {
      error "Failed to set ownership for applications directory"
      return 1
    }
  fi

  if [[ ! -f "${user_home}/.local/share/applications/${desktop_shortcut_file}" ]]; then
    cp "${desktop_shortcut_file}" "${user_home}/.local/share/applications/" || {
      error "Failed to copy desktop shortcut file to ${user_home}/.local/share/applications/"
      return 1
    }
    chown "${username}:${username}" "${user_home}/.local/share/applications/${desktop_shortcut_file}" || {
      error "Failed to set ownership for desktop shortcut file"
      return 1
    }
  fi

  sudo -u "${username}" update-desktop-database "${user_home}/.local/share/applications/" || {
    error "Failed to update desktop database for ${user_home}/.local/share/applications"
    return 1
  }

  rm -f "${desktop_shortcut_file}"
}

use_default_self_signed_ssl_cert() {
  local cert_dir="$1"
  local cert_name="${2:-selfsigned}"

  if [[ ! -f "${cert_dir}/${cert_name}.pem" || ! -f "${cert_dir}/${cert_name}.key" ]]; then
    # PEM
    if [[ -f "/etc/ssl/certs/ssl-cert-snakeoil.pem" ]]; then
      [[ -f "${cert_dir}/${cert_name}.pem" ]] || rm "${cert_dir}/${cert_name}.pem"
      ln -s "/etc/ssl/certs/ssl-cert-snakeoil.pem" "${cert_dir}/${cert_name}.pem"
    else
      error "Default self-signed SSL certificate not found at /etc/ssl/certs/ssl-cert-snakeoil.pem"
      return 1
    fi
    # Private key
    if [[ -f "/etc/ssl/private/ssl-cert-snakeoil.key" ]]; then
      [[ -f "${cert_dir}/${cert_name}.key" ]] || rm "${cert_dir}/${cert_name}.key"
      ln -s "/etc/ssl/private/ssl-cert-snakeoil.key" "${cert_dir}/${cert_name}.key"
    else
      error "Default self-signed SSL private key not found at /etc/ssl/private/ssl-cert-snakeoil.key"
      return 1
    fi
  else
    info "Using existing self-signed SSL certificate"
    return 0
  fi

  info "Using default self-signed SSL certificate"
  debug "  Certificate: ${cert_dir}/${cert_name}.pem"
  debug "  Private key: ${cert_dir}/${cert_name}.key"

  return 0
}

run_vnc_server() {
  info "=========================================="
  info "Starting VNC and NoVNC"
  info "=========================================="

  # Create user and desktop shortcut
  create_user "${VNC_USERNAME}" "${VNC_PASSWORD}"  # export USERNAME and PASSWORD
  create_desktop_shortcut "${USERNAME}"            # jmeter.desktop will be created in user's Desktop

  # First time startup or password has been changed
  if [[ -n "${PASSWORD}" ]]; then
    # Generate VNC password file
    local passwd_dir="/home/${USERNAME}/.vnc"
    local passwd_file="${passwd_dir}/passwd"
    mkdir -p "${passwd_dir}" || {
      error "Failed to create required directories: ${passwd_dir}"
      exit 1
    }
    /usr/bin/x11vnc -storepasswd "${PASSWORD}" "${passwd_file}" >/dev/null 2>&1 || {
      error "Failed to generate VNC password file"
      exit 1
    }
    chmod 600 "${passwd_file}" || {
      error "Failed to set permissions on VNC password file"
      exit 1
    }
    chown "${USERNAME}:${USERNAME}" "${passwd_file}" || {
      error "Failed to set ownership for user home directory"
      exit 1
    }
  fi

  use_default_self_signed_ssl_cert "/opt/certs" "novnc"
  cert_status=$?
  if [[ "${cert_status}" -ne 0 ]]; then
    error "ERROR: SSL certificate configuration failed"
    exit 1
  fi

  # Show connection information
  info "=========================================================================="
  info "VNC/NoVNC Server is configured with the following details:"
  info "• VNC: localhost:5900"
  info "• Web: https://localhost:6080/vnc.html"
  info "• Username: ${USERNAME}"
  if [[ -n "${PASSWORD}" ]]; then
    info "• Password: ${PASSWORD}"
  else
    info "• Password: (only for first time setup, see logs for generated password)"
  fi
  info "=========================================================================="

  info "Starting supervisord with VNC services"
  exec /usr/bin/supervisord --nodaemon --configuration=/etc/supervisord.conf | \
    while read -r line; do
      info "supervisord: ${line}"
    done

  # This point should theoretically never be reached due to exec
  error "Supervisord unexpectedly exited"
  exit 1
}

run_rdp_server() {
  info "=========================================="
  info "Starting RDP"
  info "=========================================="

  create_user "${RDP_USERNAME}" "${RDP_PASSWORD}"  # export USERNAME and PASSWORD
  create_desktop_shortcut "${USERNAME}"            # jmeter.desktop will be created in user's Desktop

  local cert_dir="/home/${USERNAME}/.certs"
  local cert_name="rdp"
  # Configure SSL certificate
  use_default_self_signed_ssl_cert "${cert_dir}" "${cert_name}"
  cert_status=$?
  if [[ "${cert_status}" -ne 0 ]]; then
    error "ERROR: SSL certificate configuration failed"
    exit 1
  fi
  # Ensure user is in ssl-cert group
  if ! id -nG "${USERNAME}" | grep -qw "ssl-cert"; then
    usermod -aG ssl-cert "${USERNAME}" || {
      error "Failed to add user ${USERNAME} to ssl-cert group"
      exit 1
    }
  fi
  # Configure xrdp to use the self-signed certificate
  sed -i "s|^certificate=.*|certificate=${cert_dir}/${cert_name}.pem|" /etc/xrdp/xrdp.ini
  sed -i "s|^key_file=.*|key_file=${cert_dir}/${cert_name}.key|" /etc/xrdp/xrdp.ini

  # Remove existing sesman/xrdp PID files to prevent rdp sessions hanging on container restart
  [[ ! -f /var/run/xrdp/xrdp-sesman.pid ]] || rm -f /var/run/xrdp/xrdp-sesman.pid
  [[ ! -f /var/run/xrdp/xrdp.pid ]] || rm -f /var/run/xrdp/xrdp.pid

  info "Starting D-Bus"
  if ! service dbus start >/dev/null 2>&1; then
    error "Failed to start dbus service"
    exit 1
  fi

  info "Starting xrdp-sesman"
  if ! /usr/sbin/xrdp-sesman >/dev/null 2>&1; then
    error "Failed to start xrdp-sesman"
    exit 1
  fi

  info "=========================================================================="
  info "RDP Server is configured with the following details:"
  info "• RDP: localhost:3390"
  info "• Username: ${USERNAME}"
  if [[ -n "${PASSWORD}" ]]; then
    info "• Password: ${PASSWORD}"
  else
    info "• Password: (only for first time setup, see logs for generated password)"
  fi
  info "=========================================================================="

  info "Starting xrdp"
  if ! /usr/sbin/xrdp --nodaemon >/dev/null 2>&1; then
    error "Failed to start xrdp"
    exit 1
  fi
}

# Run NoMachine Server
run_nomachine_server() {
  info "=========================================="
  info "Starting NoMachine"
  info "=========================================="

  create_user "${NM_USERNAME}" "${NM_PASSWORD}"  # export USERNAME and PASSWORD
  create_desktop_shortcut "${USERNAME}"          # jmeter.desktop will be created in user's Desktop

  # Remove existing D-Bus PID files to prevent hanging on container restart
  [[ ! -f /run/dbus/pid ]] || rm -f /run/dbus/pid || error "Failed to remove existing D-Bus PID file"

  info "Start nxserver"
  if ! /etc/NX/nxserver --startup >/dev/null 2>&1; then
    error "Failed to start nxserver"
    exit 1
  fi

  info "=========================================================================="
  info "NoMachine Server is configured with the following details:"
  info "• NoMachine: localhost:4000"
  info "• Username: ${USERNAME}"
  if [[ -n "${PASSWORD}" ]]; then
    info "• Password: ${PASSWORD}"
  else
    info "• Password: (only for first time setup, see logs for generated password)"
  fi
  info "=========================================================================="

  info "Start supervisord with logging"
  exec /usr/bin/supervisord --nodaemon --configuration=/etc/supervisord.conf | \
    while read -r line; do
      info "supervisord: ${line}"
    done

  # This point should theoretically never be reached due to exec
  error "Supervisord unexpectedly exited"
  exit 1
}

# Show help
show_help() {
  cat <<EOF
Usage: ${SCRIPT_NAME} <mode> [options]

Available modes:
jmeter          Run JMeter in Console
jmeter-server   Run JMeter in Server
mirror-server   Run Mirror Server
customize       Run custom commands
keepalive       Just keep container alive
server-agent    Run Server Agent for monitoring
vnc             Start VNC and NoVNC
rdp             Start RDP
nomachine       Start NoMachine

Environment Variables:
JMETER_HOME                  - Path to JMeter installation (required)
JMETER_CUSTOM_PLUGINS_DIR    - Path to custom JMeter plugins
SERVER_AGENT_HOME            - Path to Server Agent installation
SA_INTERVAL                  - Server Agent polling interval (default: 5s)
VNC_PASSWORD                 - Password for VNC server (if not set, a random password will be generated)
EOF
}

# ------------ Main Script ------------
main() {
  create_lock

  info "=========================================="
  info "Starting ${SCRIPT_NAME} v${SCRIPT_VERSION}"
  info "=========================================="

  current_user=$(id) || current_user="unknown"
  info "Running as ${current_user}"

  calculate_jvm_memory
  copy_plugins

  java_version=$(java -version 2>&1 | head -1 || true)
  jmeter_version=$(jmeter -v 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)

  info "Java   version: ${java_version:-Unknown}"
  info "JMeter version: ${jmeter_version:-Unknown}"
  info "JMeter home: ${JMETER_HOME}"
  info "JVM args: ${JVM_ARGS}"
  info "Log file: ${LOG_FILE}"

  if [[ $# -eq 0 ]]; then
    show_help
    exit 1
  fi

  local mode=$1
  shift

  case ${mode} in
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
      error "Unknown mode: ${mode}"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
