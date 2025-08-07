#!/bin/bash

set -euo pipefail

TEST_LOG="test.log"

# 测试日志函数
log_test() {
  echo "[TEST] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $TEST_LOG
}

# 清理函数
cleanup() {
  docker rm -f test-jmeter >/dev/null 2>&1 || true
}

trap cleanup EXIT

# 测试JMeter控制台模式
test_console_mode() {
  log_test "测试控制台模式..."
  docker run --name test-jmeter your-jmeter-image jmeter --version > output.log 2>&1
  if grep -q "Apache JMeter" output.log; then
    log_test "控制台模式测试通过"
  else
    log_test "控制台模式测试失败"
    exit 1
  fi
}

# 测试JMeter服务器模式
test_server_mode() {
  log_test "测试服务器模式..."
  docker run -d --name test-jmeter -p 1099:1099 -p 50000:50000 your-jmeter-image jmeter-server > output.log 2>&1 &
  
  sleep 10 # 等待服务器启动
  
  if docker logs test-jmeter 2>&1 | grep -q "Server started"; then
    log_test "服务器模式测试通过"
  else
    log_test "服务器模式测试失败"
    exit 1
  fi
}

# 测试镜像服务器模式
test_mirror_mode() {
  log_test "测试镜像服务器模式..."
  docker run -d --name test-jmeter -p 8080:8080 your-jmeter-image mirror-server > output.log 2>&1 &
  
  sleep 5
  
  if curl -s http://localhost:8080 | grep -q "Mirror Server"; then
    log_test "镜像服务器模式测试通过"
  else
    log_test "镜像服务器模式测试失败"
    exit 1
  fi
}

# 测试保持活动模式
test_keepalive_mode() {
  log_test "测试保持活动模式..."
  docker run -d --name test-jmeter your-jmeter-image keepalive > output.log 2>&1 &
  
  sleep 2
  
  if docker ps --filter "name=test-jmeter" --format "{{.Status}}" | grep -q "Up"; then
    log_test "保持活动模式测试通过"
  else
    log_test "保持活动模式测试失败"
    exit 1
  fi
}

# 测试VNC服务器模式
test_vnc_mode() {
  log_test "测试VNC服务器模式..."
  docker run -d --name test-jmeter -p 5900:5900 -p 6080:6080 your-jmeter-image vnc > output.log 2>&1 &
  
  sleep 10 # VNC需要更长时间启动
  
  if docker logs test-jmeter 2>&1 | grep -q "NoVNC (Web) Connection"; then
    log_test "VNC服务器模式测试通过"
  else
    log_test "VNC服务器模式测试失败"
    exit 1
  fi
}

# 运行所有测试
test_console_mode
test_server_mode
test_mirror_mode
test_keepalive_mode
test_vnc_mode

log_test "所有测试通过!"
