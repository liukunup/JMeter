#!/bin/bash

# install custom plugins
if [[ -d $JMETER_CUSTOM_PLUGINS_FOLDER ]]
then
  for plugin in "${JMETER_CUSTOM_PLUGINS_FOLDER}"/*.jar; do
    cp "$plugin" "${JMETER_EXT}"
  done;
fi

# set JVM parameters
set -e
freeMem=$(awk '/MemAvailable/ { print int($2/1024) }' /proc/meminfo)
# assign value if empty
[[ -z ${JVM_XMN} ]] && JVM_XMN=$((freeMem * 2 / 10))
[[ -z ${JVM_XMS} ]] && JVM_XMS=$((freeMem * 8 / 10))
[[ -z ${JVM_XMX} ]] && JVM_XMX=$((freeMem * 8 / 10))
# assemble JVM parameters
[[ -z ${JVM_ARGS} ]] && JVM_ARGS="-Xmn${JVM_XMN}m -Xms${JVM_XMS}m -Xmx${JVM_XMX}m"
# setup environment variable
export JVM_ARGS=${JVM_ARGS}

# ##################################### Operating Mode #####################################

function func_jmeter() {
  echo "FUNC IN  - JMeter"

  echo "===== JVM_ARGS ====="
  echo "${JVM_ARGS}"

  echo "===== JMETER ARGS ====="
  echo "${@:2}"

  echo "===== JMETER EXTRA ARGS ====="
  EXTRA_ARGS=-Dlog4j2.formatMsgNoLookups=true
  echo ${EXTRA_ARGS}

  echo "===== JMETER ALL ARGS ====="
  echo ${EXTRA_ARGS} "${@:2}"

  # Run JMeter
  jmeter ${EXTRA_ARGS} "${@:2}"

  echo "FUNC OUT - JMeter"
}

function func_jmeter_server() {
  echo "FUNC IN  - JMeter Server"

  echo "===== JVM_ARGS ====="
  echo "${JVM_ARGS}"

  echo "===== JMETER SERVER ARGS ====="
  # Usually no need to configure parameters
  echo "${@:2}"

  echo "===== JMETER SERVER EXTRA ARGS ====="
  # In most cases, `server.rmi.ssl.disable=true` is set by default, so write it directly here
  EXTRA_ARGS=(-Dlog4j2.formatMsgNoLookups=true -Dserver_port=1099 -Dserver.rmi.localport=50000 -Dserver.rmi.ssl.disable=true)
  echo ${EXTRA_ARGS[*]}

  echo "===== JMETER SERVER ALL ARGS ====="
  echo ${EXTRA_ARGS[*]} "${@:2}"

  # Start JMeter Server
  jmeter-server ${EXTRA_ARGS[*]} "${@:2}"

  echo "FUNC OUT - JMeter Server"
}

function func_keepalive() {
  echo "FUNC IN  - Keepalive"

  # keepalive
  tail -f /dev/null

  echo "FUNC OUT - Keepalive"
}

echo "=============== START Running at $(date) ==============="

# Operating mode:
# 1. jmeter
# 2. jmeter server
# 3. keepalive
mode=$1

case $mode in
    jmeter)        echo "Process ID: $$, Run mode JMeter"
    func_jmeter "$@"
    ;;
    jmeter-server) echo "Process ID: $$, Run mode JMeter-Server"
    func_jmeter_server "$@"
    ;;
    keepalive)     echo "Process ID: $$, Run mode Keepalive"
    func_keepalive "$@"
    ;;
esac

echo "=============== FINISH Running on $(date) ==============="
