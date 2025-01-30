#!/bin/bash

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

# ##################################### Operating Mode #####################################

# Function to run JMeter
function func_jmeter() {
  echo "FUNC IN - JMeter"

  echo "===== JVM ARGS ====="
  echo "${JVM_ARGS}"
  echo

  echo "===== JMETER ARGS ====="
  echo "${@:2}"
  echo

  echo "===== JMETER EXTRA ARGS ====="
  EXTRA_ARGS=(-Dlog4j2.formatMsgNoLookups=true)
  echo "${EXTRA_ARGS[*]}"
  echo

  echo "===== JMETER ALL ARGS ====="
  echo "${EXTRA_ARGS[*]}" "${@:2}"
  echo

  # Run JMeter
  jmeter ${EXTRA_ARGS[*]} ${@:2}

  echo "FUNC OUT - JMeter"
}

# Function to run JMeter Server
function func_jmeter_server() {
  echo "FUNC IN - JMeter Server"

  echo "===== JVM ARGS ====="
  echo "${JVM_ARGS}"
  echo

  echo "===== JMETER SERVER ARGS ====="
  echo "${@:2}"
  echo

  echo "===== JMETER SERVER EXTRA ARGS ====="
  # The `server.rmi.ssl.disable=true` property is typically set by default, so it is included directly here.
  EXTRA_ARGS=(-Dlog4j2.formatMsgNoLookups=true -Dserver_port=1099 -Dserver.rmi.localport=50000 -Dserver.rmi.ssl.disable=true)
  echo "${EXTRA_ARGS[*]}"
  echo

  echo "===== JMETER SERVER ALL ARGS ====="
  echo "${EXTRA_ARGS[*]}" "${@:2}"
  echo

  # Start JMeter Server
  jmeter-server ${EXTRA_ARGS[*]} ${@:2}

  echo "FUNC OUT - JMeter Server"
}

# Function to run Mirror Server
function func_mirror_server() {
  echo "FUNC IN - Mirror Server"

  echo "===== JVM_ARGS ====="
  echo "${JVM_ARGS}"
  echo

  echo "===== MIRROR SERVER ARGS ====="
  echo "${@:2}"
  echo

  echo "===== MIRROR SERVER EXTRA ARGS ====="
  EXTRA_ARGS=(-Dlog4j2.formatMsgNoLookups=true --port 8080)
  echo "${EXTRA_ARGS[*]}"
  echo

  echo "===== MIRROR SERVER ALL ARGS ====="
  echo "${EXTRA_ARGS[*]}" "${@:2}"
  echo

  # Start Mirror Server
  mirror-server ${EXTRA_ARGS[*]} ${@:2}

  echo "FUNC OUT - Mirror Server"
}

# Function to run customized command
function func_customize() {
  echo "FUNC IN - Customize"

  echo "===== JVM_ARGS ====="
  echo "${JVM_ARGS}"
  echo

  echo "===== CUSTOMIZE ARGS ====="
  echo "${@:2}"
  echo

  # Run customized command
  ${@:2}

  echo "FUNC OUT - Customize"
}

# Function to keep the container alive
function func_keepalive() {
  echo "FUNC IN - Keepalive"

  # Keep the container alive
  tail -f /dev/null

  echo "FUNC OUT - Keepalive"
}

echo "=============== START Running at $(date) ==============="

# Operating mode:
# 1. jmeter
# 2. jmeter server
# 3. mirror server
# 4. customize
# 5. keepalive
mode=$1

# Execute the appropriate function based on the mode
case $mode in
    jmeter)        echo "Mode ID: $$, Name: JMeter"
    echo
    func_jmeter "$@"
    ;;
    jmeter-server) echo "Mode ID: $$, Name: JMeter-Server"
    echo
    func_jmeter_server "$@"
    ;;
    mirror-server) echo "Mode ID: $$, Name: Mirror-Server"
    echo
    func_mirror_server "$@"
    ;;
    customize)     echo "Mode ID: $$, Name: Customize"
    echo
    func_customize "$@"
    ;;
    keepalive)     echo "Mode ID: $$, Name: Keepalive"
    echo
    func_keepalive "$@"
    ;;
esac

echo "=============== FINISH Running on $(date) ==============="
