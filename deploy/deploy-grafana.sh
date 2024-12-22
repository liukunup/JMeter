#!/bin/bash

# 设置性能测试根目录
PERF_HOME=$PWD
GF_HOME=$PERF_HOME/grafana

# 配置数据源目录
PERF_DATASOURCES=$GF_HOME/provisioning/datasources
if [ ! -d $PERF_DATASOURCES ]; then
    mkdir -p $PERF_DATASOURCES
fi

# 配置看板目录
PERF_DASHBOARDS=$GF_HOME/provisioning/dashboards
if [ ! -d $PERF_DASHBOARDS ]; then
    mkdir -p $PERF_DASHBOARDS
fi

echo ==================== Deploy Grafana ====================

echo 1. checking perf network...

# 如果网络不存在则创建
if [ -z "$(docker network ls --filter name=^perf$ --format {{.Name}})" ]; then
    echo Network Id:
    docker network create perf
    echo
fi

echo 2. starting Grafana container...

# 询问并设置账号和密码
read -p "[Grafana] Please input the username (default: admin): " username
username=${username:-admin}
read -p "[Grafana] Please input the password (default: perf@JMeter#1024): " password
password=${password:-perf@JMeter#1024}

# 询问镜像仓库
read -p "[Grafana] Please input the image repository (default: docker.io): " repository
repository=${repository:-docker.io}

echo
echo Container Id:
# 拉起`Grafana`容器
docker run -d \
  -p 3000:3000 \
  -v perf-grafana-storage:/var/lib/grafana \
  -v $PERF_DATASOURCES:/etc/grafana/provisioning/datasources \
  -v $PERF_DASHBOARDS:/etc/grafana/provisioning/dashboards \
  -e GF_SECURITY_ADMIN_USER=$username \
  -e GF_SECURITY_ADMIN_PASSWORD=$password \
  --restart=unless-stopped \
  --hostname=grafana \
  --network=perf \
  --name=perf-grafana \
  $repository/grafana/grafana:latest

echo
echo Grafana has been successfully deployed. You can access it via http://localhost:3000.
echo

# 配置数据源
configure_datasource_influxdb2() {
  read -p "[InfluxDB2] Please input the hostname [default: influxdb]: " hostname
  hostname=${hostname:-influxdb}
  read -p "[InfluxDB2] Please input the port [default: 8086]: " port
  port=${port:-8086}
  read -p "[InfluxDB2] Please input the organization [default: Org]: " organization
  organization=${organization:-Org}
  read -p "[InfluxDB2] Please input the bucket [default: JMeter]: " bucket
  bucket=${bucket:-JMeter}
  read -p "[InfluxDB2] Please input the token: " token
  token=${token:-Please input your token}

  echo Configure datasource InfluxDB2 for Grafana...

cat > $PERF_DATASOURCES/influxdb2.yaml <<-EOF
apiVersion: 1

datasources:
  - name: InfluxDB2
  type: influxdb
  access: proxy
  url: http://$hostname:$port
  jsonData:
    version: Flux
    organization: $organization
    defaultBucket: $bucket
    tlsSkipVerify: true
  secureJsonData:
    token: $token
EOF

  echo
  echo "[InfluxDB2] Datasource has been successfully configured. You can verify it by checking the file: $PERF_DATASOURCES/influxdb2.yaml"
  echo
}

# 询问是否配置数据源
read -p "Do you want to configure datasource InfluxDB2 for Grafana? [Y/N]: " answer
if [[ "$answer" =~ ^[Yy] ]]; then
  configure_datasource_influxdb2
else
  echo "[InfluxDB2] datasource configuration skipped."
  exit 0
fi
