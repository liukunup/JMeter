#!/bin/bash

# 设置性能测试的根目录
PERF_HOME=${HOME}
NODE_EXPORTER_HOME=${PERF_HOME}/node-exporter

# 如果不存在则创建
if [[ ! -d "${NODE_EXPORTER_HOME}" ]]; then
  mkdir -p "${NODE_EXPORTER_HOME}"
fi

echo ==================== Deploy Node Exporter ====================

echo 1. checking perf network...

# 如果不存在则创建
# shellcheck disable=SC2312
if [[ -z "$(docker network ls --filter name=^perf$ --format "{{.Name}}")" ]]; then
    echo Network Id:
    docker network create perf
    echo
fi

echo 2. Starting Node-Exporter container...

# 询问并设置账号和密码
read -rp "[Node Exporter] Please input the username (default: admin): " username
username=${username:-admin}
read -rp "[Node Exporter] Please input the password (default: perf@JMeter#1024): " password
password=${password:-perf@JMeter#1024}

# 询问镜像仓库
read -rp "[Node Exporter] Please input the image repository (default: docker.io): " repository
repository=${repository:-docker.io}

# 加密处理
# shellcheck disable=SC2312
if ! encrypted_password=$(htpasswd -nBC 12 '' | tr -d ':\n'); then
  echo "Warning: htpasswd command failed" >&2
  exit 1
fi

cat > "${NODE_EXPORTER_HOME}/web-config.yml" <<-EOF
basic_auth_users:
  ${username}: ${encrypted_password}
EOF

echo
echo Container Id:
# 拉起`Node Exporter`容器
docker run -d \
  -p 9100:9100 \
  -v "${NODE_EXPORTER_HOME}":/etc/node-exporter \
  -v "/:/host:ro,rslave" \
  --net=host \
  --pid=host \
  --restart=unless-stopped \
  --hostname=node-exporter \
  --network=perf \
  --name=perf-node-exporter \
  "${repository}/prom/node-exporter:latest" \
  --path.rootfs=/host \
  --web.config.file=/etc/node-exporter/web-config.yml

echo
echo Node-Exporter has been successfully deployed. You can access it via http://localhost:9100/metrics.
echo
