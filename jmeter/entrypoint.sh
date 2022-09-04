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
  # 通常不再需要配置参数
  echo "${@:2}"

  echo "===== JMETER SERVER EXTRA ARGS ====="
  # 多数情况下会默认设置`server.rmi.ssl.disable=true`,因此直接写到内部来
  EXTRA_ARGS=(-Dlog4j2.formatMsgNoLookups=true -Dserver_port=1099 -Dserver.rmi.localport=50000 -Dserver.rmi.ssl.disable=true)
  echo ${EXTRA_ARGS[*]}

  echo "===== JMETER SERVER ALL ARGS ====="
  echo ${EXTRA_ARGS[*]} "${@:2}"

  # Run JMeter Server
  jmeter-server ${EXTRA_ARGS[*]} "${@:2}"

  echo "FUNC OUT - JMeter Server"
}

function func_keepalive() {
  echo "FUNC IN  - Keepalive"

  # keepalive
  tail -f /dev/null

  echo "FUNC OUT - Keepalive"
}

# 打印开始时间
echo "=============== START Running at $(date) ==============="

# 容器运行模式
# 1. jmeter
# 2. jmeter server
# 3. keepalive
mode=$1

# 按模式选择函数
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

# 打印结束时间
echo "=============== FINISH Running on $(date) ==============="
