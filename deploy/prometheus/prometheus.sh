#!/bin/bash

# 设置性能测试的根目录
PERF_HOME=$HOME
PROM_HOME=$PERF_HOME/prometheus

# 如果不存在则创建
if [ ! -d $PROM_HOME ]; then
    mkdir -p $PROM_HOME
fi

echo ==================== Deploy Prometheus ====================

echo 1. checking perf network...

# 如果不存在则创建
if [ -z "$(docker network ls --filter name=^perf$ --format {{.Name}})" ]; then
    echo Network Id:
    docker network create perf
    echo
fi

echo 2. Starting Prometheus container...

# 询问并设置账号和密码
read -p "[Prometheus] Please input the username (default: admin): " username
username=${username:-admin}
read -p "[Prometheus] Please input the password (default: perf@JMeter#1024): " password
password=${password:-perf@JMeter#1024}
# 加密处理
encrypted_password=$(htpasswd -nBC 12 '' | tr -d ':\n')

# 询问`Node Exporter`的`IP:PORT`列表
read -p "[Prometheus] Please input the ip address and port list of node-exporter instances (example: ip1:9100,ip2:9100,ip3:9100): " node_exporter_list
formatted_list=$(echo "$node_exporter_list" | tr ',' '\n' | sed "s/^/'/;s/$/'/" | paste -sd, -)
# 询问`Node Exporter`的账号和密码
read -p "[Prometheus] Please input the username of node-exporter instances (default: admin): " node_exporter_username
node_exporter_username=${node_exporter_username:-admin}
read -p "[Prometheus] Please input the password of node-exporter instances (default: perf@JMeter#1024): " node_exporter_password
node_exporter_password=${node_exporter_password:-perf@JMeter#1024}

# 询问镜像仓库
read -p "[Prometheus] Please input the image repository (default: docker.io): " repository
repository=${repository:-docker.io}

# 创建配置文件
cat > $PROM_HOME/web-config.yml <<-EOF
basic_auth_users:
  $username: $encrypted_password
EOF

# 创建配置文件
cat > $PROM_HOME/prometheus.yml <<-EOF
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    basic_auth:
      username: $node_exporter_username
      password: $node_exporter_password
    static_configs:
    - targets: [$formatted_list]
EOF

echo
echo Container Id:
# 拉起`Node Exporter`容器
docker run -d \
  -p 9090:9090 \
  -v $PROM_HOME:/etc/prometheus:ro \
  -e TZ=Asia/Shanghai \
  --restart=unless-stopped \
  --hostname=prometheus \
  --network=perf \
  --name=perf-prometheus \
  $repository/prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.config.file=/etc/prometheus/web-config.yml

echo
echo Prometheus has been successfully deployed. You can access it via http://localhost:9090.
echo
