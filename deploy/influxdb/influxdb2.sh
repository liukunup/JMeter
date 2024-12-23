#!/bin/bash

# 设定生成Token的长度
TOKEN_LENGTH=64
# 用于生成Token的字符集
TOKEN_CHAR_SET="a-zA-Z0-9-_="

echo ==================== Deploy InfluxDB 2 ====================

echo 1. checking perf network...

# 如果网络不存在则创建
if [ -z "$(docker network ls --filter name=^perf$ --format {{.Name}})" ]; then
    echo Network Id:
    docker network create perf
    echo
fi

echo 2. Generating admin Token for InfluxDB2...

# 生成随机Token的方法
generate_token() {
    local length=$1
    local charset=$2
    tr -dc "$charset" < /dev/urandom | head -c $length
}

# 生成Token
TOKEN=$(generate_token $TOKEN_LENGTH $TOKEN_CHAR_SET)

echo 3. Starting InfluxDB2 container...

# 询问并设置账号和密码
read -p "[InfluxDB2] Please input the username (default: admin): " username
username=${username:-admin}
read -p "[InfluxDB2] Please input the password (default: perf@JMeter#1024): " password
password=${password:-perf@JMeter#1024}
# 询问并设置组织和桶
read -p "[InfluxDB2] Please input the organization (default: Org): " organization
organization=${organization:-Org}
read -p "[InfluxDB2] Please input the bucket (default: JMeter): " bucket
bucket=${bucket:-Org}

# 询问镜像仓库
read -p "[InfluxDB2] Please input the image repository (default: docker.io): " repository
repository=${repository:-docker.io}

echo
echo Container Id:
# 拉起`InfluxDB 2`容器
docker run -d \
  -p 8086:8086 \
  -v influxdb-data:/var/lib/influxdb2 \
  -v influxdb-config:/etc/influxdb2 \
  -e DOCKER_INFLUXDB_INIT_MODE=setup \
  -e DOCKER_INFLUXDB_INIT_USERNAME=$username \
  -e DOCKER_INFLUXDB_INIT_PASSWORD=$password \
  -e DOCKER_INFLUXDB_INIT_ORG=$organization \
  -e DOCKER_INFLUXDB_INIT_BUCKET=$bucket \
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$TOKEN \
  --restart=unless-stopped \
  --hostname=influxdb \
  --network=perf \
  --name=perf-influxdb \
  $repository/influxdb:2

# 提示保存
echo
echo Grafana has been successfully deployed. You can access it via http://localhost:8086.
echo
echo Please save the following Token securely, it is your credential to access InfluxDB2.
echo
echo token: $TOKEN
echo
