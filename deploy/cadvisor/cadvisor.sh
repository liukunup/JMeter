#!/bin/bash

# 设置性能测试的根目录
PERF_HOME=$HOME
CADVISOR_HOME=$PERF_HOME/cadvisor

# 如果不存在则创建
if [ ! -d $CADVISOR_HOME ]; then
    mkdir -p $CADVISOR_HOME
fi

echo ==================== Deploy cAdvisor ====================

echo 1. checking perf network...

# 如果不存在则创建
if [ -z "$(docker network ls --filter name=^perf$ --format {{.Name}})" ]; then
    echo Network Id:
    docker network create perf
    echo
fi

echo 2. Starting cAdvisor container...

# 询问并设置账号和密码
read -p "[cAdvisor] Please input the username (default: admin): " username
username=${username:-admin}
echo    "[cAdvisor] Please input the password"
encrypted_password=$(htpasswd -nBC 12 '' | tr -d ':\n')

# 保存账号和密码
cat > $CADVISOR_HOME/perf.htpasswd <<-EOF
$username: $encrypted_password
EOF

# 询问镜像仓库
read -p "[cAdvisor] Please input the image repository (default: gcr.io): " repository
repository=${repository:-gcr.io}

echo
echo Container Id:
# 拉起`cAdvisor`容器
docker run -d \
  -p 8080:8080 \
  --volume=$CADVISOR_HOME:/etc/cadvisor \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --restart=unless-stopped \
  --hostname=cadvisor \
  --network=perf \
  --name=perf-cadvisor \
  --privileged \
  --device=/dev/kmsg \
  $repository/cadvisor/cadvisor:latest \
  --http_auth_file /etc/cadvisor/perf.htpasswd \
  --http_auth_realm localhost

echo
echo cAdvisor has been successfully deployed. You can access it via http://localhost:8080/metrics.
echo
