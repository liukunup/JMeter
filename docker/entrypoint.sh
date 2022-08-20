#!/bin/bash

# 安装自定义的插件
if [[ -d $JMETER_CUSTOM_PLUGINS_FOLDER ]]
then
  for plugin in "${JMETER_CUSTOM_PLUGINS_FOLDER}"/*.jar; do
    cp "$plugin" "${JMETER_EXT}"
  done;
fi

# 设置JVM参数
set -e
freeMem=$(awk '/MemAvailable/ { print int($2/1024) }' /proc/meminfo)
# 若空则赋值
[[ -z ${JVM_XMN} ]] && JVM_XMN=$((freeMem * 2 / 10))
[[ -z ${JVM_XMS} ]] && JVM_XMS=$((freeMem * 8 / 10))
[[ -z ${JVM_XMX} ]] && JVM_XMX=$((freeMem * 8 / 10))
# 拼凑JVM参数
[[ -z ${JVM_ARGS} ]] && JVM_ARGS="-Xmn${JVM_XMN}m -Xms${JVM_XMS}m -Xmx${JVM_XMX}m"
# 设置环境变量以备使用
export JVM_ARGS=${JVM_ARGS}

# ##################################### 模式 #####################################

function func_jmeter() {
  echo "FUNC IN  - JMeter"

  echo "===== JVM_ARGS ====="
  echo "${JVM_ARGS}"

  echo "===== JMETER ARGS ====="
  echo "${@:1}"

  echo "===== JMETER EXTRA ARGS ====="
  EXTRA_ARGS=-Dlog4j2.formatMsgNoLookups=true
  echo ${EXTRA_ARGS}

  echo "===== JMETER ALL ARGS ====="
  echo ${EXTRA_ARGS} "${@:1}"

  # Run JMeter
  jmeter ${EXTRA_ARGS} "${@:1}"

  echo "FUNC OUT - JMeter"
}

function func_jmeter_server() {
  echo "FUNC IN  - JMeter Server"

  echo "FUNC OUT - JMeter Server"
}

function func_server_agent() {
  echo "FUNC IN  - Server Agent"
  "${SERVER_AGENT_HOME}"/startAgent.sh --udp-port 0 --tcp-port 4444 --interval 5
  echo "FUNC OUT - Server Agent"
}

function func_debug() {
  echo "FUNC IN  - Debug"

  # cli
  /bin/bash

  echo "FUNC OUT - Debug"
}

# 打印开始时间
echo "=============== START Running at $(date) ==============="

# 容器运行模式
# 1. jmeter
# 2. jmeter server
# 3. server agent (PerfMon)
mode=$1

# 打印脚本进程ID
echo "Process ID: $$"

# 按模式选择函数
case $mode in
    jmeter)        echo "Run mode JMeter"
    func_jmeter "$@"
    ;;
    jmeter-server) echo "Run mode JMeter-Server"
    func_jmeter_server "$@"
    ;;
    server-agent)  echo "Run mode Server-Agent"
    func_server_agent "$@"
    ;;
    debug)         echo "Run mode DEBUG"
    func_debug "$@"
    ;;
esac

# 打印结束时间
echo "=============== FINISH Running on $(date) ==============="
