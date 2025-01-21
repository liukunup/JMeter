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
echo    "[Prometheus] Please input the password"
encrypted_password=$(htpasswd -nBC 12 '' | tr -d ':\n')

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
  $repository/prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --web.config.file=/etc/prometheus/web-config.yml

echo
echo Prometheus has been successfully deployed. You can access it via http://localhost:9090.
echo
