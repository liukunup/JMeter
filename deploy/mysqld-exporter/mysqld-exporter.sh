#!/bin/bash

# 设置性能测试的根目录
PERF_HOME=${HOME}
MYSQLD_EXPORTER_HOME=${PERF_HOME}/mysqld-exporter

# 如果不存在则创建
if [[ ! -d "${MYSQLD_EXPORTER_HOME}" ]]; then
  mkdir -p "${MYSQLD_EXPORTER_HOME}"
fi

echo ==================== Deploy MySQL Server Exporter ====================

echo 1. checking perf network...

# 如果不存在则创建
# shellcheck disable=SC2312
if [[ -z "$(docker network ls --filter name=^perf$ --format "{{.Name}}")" ]]; then
  echo Network Id:
  docker network create perf
  echo
fi

echo 2. Starting MySQL Server Exporter container...

# 询问并设置账号和密码
read -rp "[MySQL Server Exporter] Please input the username (default: admin): " username
username=${username:-admin}
echo    "[MySQL Server Exporter] Please input the password"
# shellcheck disable=SC2312
if ! encrypted_password=$(htpasswd -nBC 12 '' | tr -d ':\n'); then
  echo "Warning: htpasswd command failed" >&2
  exit 1
fi

# 保存账号和密码
cat > "${MYSQLD_EXPORTER_HOME}/perf.htpasswd" <<-EOF
${username}: ${encrypted_password}
EOF

# 询问镜像仓库
read -rp "[MySQL Server Exporter] Please input the image repository (default: docker.io): " repository
repository=${repository:-docker.io}

echo
echo Container Id:
# 拉起`MySQL Server Exporter`容器
docker run -d \
  -p 9104:9104 \
  -v "${MYSQLD_EXPORTER_HOME}":/etc/mysqld-exporter \
  -v /home/user/user_my.cnf:/.my.cnf \
  --restart=unless-stopped \
  --hostname=mysqld-exporter \
  --network=perf \
  --name=perf-mysqld-exporter \
  "${repository}/prom/mysqld-exporter:latest" \
  --web.config.file=/etc/mysqld-exporter/web-config.yml

echo
echo cAdvisor has been successfully deployed. You can access it via http://localhost:9104/metrics.
echo
