#!/bin/bash

# 设定生成Token的长度
TOKEN_LENGTH=64
# 用于生成Token的字符集
TOKEN_CHAR_SET="a-zA-Z0-9!@#$%^&*-_=+"

echo ==================== Deploy InfluxDB 2 ====================

echo 1. Generating Token for InfluxDB2...

# 生成随机Token的方法
generate_token() {
    local length=$1
    local charset=$2
    tr -dc "$charset" < /dev/urandom | head -c $length
}

# 生成Token
TOKEN=$(generate_token $TOKEN_LENGTH $TOKEN_CHAR_SET)

echo 2. Starting InfluxDB2 container...

echo
echo Container Id:
# 拉起`InfluxDB 2`容器
docker run -d \
  -p 8086:8086 \
  -v influxdb-data:/var/lib/influxdb2 \
  -v influxdb-config:/etc/influxdb2 \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=admin \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=perf@JMeter#1024 \
  -e DOCKER_INFLUXDB_INIT_ORG=Org \
  -e DOCKER_INFLUXDB_INIT_BUCKET=JMeter \
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$TOKEN \
  --restart=unless-stopped \
  --hostname=influxdb \
  --name=perf-influxdb \
  influxdb:2

# 提示保存
echo
echo Please save the following Token securely, it is your credential to access InfluxDB2.
echo
echo token: $TOKEN
echo
