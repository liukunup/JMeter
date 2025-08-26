#!/bin/bash

# set -x  # Uncomment for debugging

# Ensure script exits on error and unset variables
set -euo pipefail

# shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}") || exit 1

: "${JMETER_BIN:=/opt/jmeter/bin}"
: "${JMETER_LIB:=/opt/jmeter/lib}"

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

# Correct jar versions in the target script based on actual files in the lib directory
correct_jar_version() {
  local lib_dir="$1"
  local script_file="$2"
  local backup_file="${script_file}.bak"

  # Validate input parameters
  [[ -d "${lib_dir}" ]] || { error "Lib directory ${lib_dir} does not exist!"; return 1; }
  [[ -f "${script_file}" ]] || { error "Target script ${script_file} does not exist!"; return 1; }

  # Create backup of the original file
  cp "${script_file}" "${backup_file}" || { error "Failed to create backup file!"; return 1; }

  # List of jar file prefixes to process
  local jar_prefix_list=(
    "oro-"
    "slf4j-api-"
    "jcl-over-slf4j-"
    "log4j-slf4j-impl-"
    "log4j-api-"
    "log4j-core-"
    "log4j-1.2-api-"
    "commons-lang3-"
  )

  # Counters for statistics
  local replace_count=0
  local missing_count=0

  info "Starting jar version detection and replacement..."
  info "Lib directory: ${lib_dir}"
  info "Target file: ${script_file}"
  info "=========================================="

  for prefix in "${jar_prefix_list[@]}"; do
    # Find matching jar file in lib directory
    # shellcheck disable=SC2155
    local jar_file=$(find "${lib_dir}" -maxdepth 1 -name "${prefix}*.jar" | head -n 1)

    if [[ -n "${jar_file}" ]]; then
      # shellcheck disable=SC2155
      local filename=$(basename "${jar_file}")

      # Check if replacement is needed
      if grep -q "${prefix}[0-9.-]*\.jar" "${script_file}"; then
        # Escape special characters and perform replacement
        if sed -i -e "s/${prefix}[0-9.-]*\.jar/${filename}/g" "${script_file}"; then
          info "✓ Replaced: ${prefix}*.jar → ${filename}"
          ((replace_count++)) || true
        else
          error "✗ Replacement failed: ${prefix}"
        fi
      else
        info "➤ No replacement needed: ${prefix} (pattern not found)"
      fi
    else
      warn "⚠️ Not found: ${prefix}*.jar"
      ((missing_count++)) || true
    fi
  done

  info "=========================================="
  info "Summary: Successfully replaced ${replace_count} items, ${missing_count} jars not found"
  info "Backup file: ${backup_file}"

  # Show diff of changes if any replacements were made
  if command -v diff &>/dev/null && [[ ${replace_count} -gt 0 ]]; then
    info "=========================================="
    info "Changes made:"
    diff "${backup_file}" "${script_file}" || true
  fi

  return 0
}

# add commons-lang3-*.jar
sed -i '/^java -cp/ i\CP=${CP}:../lib/commons-lang3-3.14.0.jar' "${JMETER_BIN}/mirror-server.sh"
correct_jar_version "${JMETER_LIB}" "${JMETER_BIN}/mirror-server.sh"

# add commons-lang3-*.jar
sed -i '/^java -cp/ i\set CP=%CP%;..\\lib\\commons-lang3-3.14.0.jar' "${JMETER_BIN}/mirror-server.cmd"
correct_jar_version "${JMETER_LIB}" "${JMETER_BIN}/mirror-server.cmd"