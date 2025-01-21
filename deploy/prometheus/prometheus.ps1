# 设置性能测试的根目录
$PERF_HOME = $env:USERPROFILE
$PROM_HOME = "$PERF_HOME\prometheus"

# 如果不存在则创建
if (-Not (Test-Path -Path $PROM_HOME)) {
  New-Item -ItemType Directory -Path $PROM_HOME -Force
}

Write-Output "==================== Deploy Prometheus ===================="

Write-Output "1. checking perf network..."

# 如果不存在则创建
if (-Not (docker network ls --filter name=^perf$ --format '{{.Name}}')) {
  Write-Output "Network Id:"
  docker network create perf
  Write-Output ""
}

Write-Output "2. Starting Prometheus container..."

# 询问并设置账号和密码
$username = Read-Host "[Prometheus] Please input the username (default: admin)"
if ([string]::IsNullOrEmpty($username)) { $username = "admin" }

$password = Read-Host "[Prometheus] Please input the password (default: perf@JMeter#1024)"
if ([string]::IsNullOrEmpty($password)) { $password = "perf@JMeter#1024" }

# 加密处理
$encrypted_password = htpasswd -nBC 12 '' | Out-String | ForEach-Object { $_.Trim() -replace ':', '' }

# 询问`Node Exporter`的`IP:PORT`列表
$node_exporter_list = Read-Host "[Prometheus] Please input the ip address and port list of node-exporter instances (example: ip1:9100,ip2:9100,ip3:9100)"
$formatted_list = $node_exporter_list -split ',' | ForEach-Object { "'$_'" } -join ','

# 询问`Node Exporter`的账号和密码
$node_exporter_username = Read-Host "[Prometheus] Please input the username of node-exporter instances (default: admin)"
if ([string]::IsNullOrEmpty($node_exporter_username)) { $node_exporter_username = "admin" }

$node_exporter_password = Read-Host "[Prometheus] Please input the password of node-exporter instances (default: perf@JMeter#1024)"
if ([string]::IsNullOrEmpty($node_exporter_password)) { $node_exporter_password = "perf@JMeter#1024" }

# 询问镜像仓库
$repository = Read-Host "[Prometheus] Please input the image repository (default: docker.io)"
if ([string]::IsNullOrEmpty($repository)) { $repository = "docker.io" }

# 创建配置文件
@"
basic_auth_users:
  ${username}: ${encrypted_password}
"@ | Out-File -FilePath "$PROM_HOME\web-config.yml" -Encoding UTF8

# 创建配置文件
@"
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:

  - job_name: 'prometheus'
  static_configs:
  - targets: ['localhost:9090']

  - job_name: 'node_exporter'
  basic_auth:
    username: ${node_exporter_username}
    password: ${node_exporter_password}
  static_configs:
  - targets: [${formatted_list}]
"@ | Out-File -FilePath "$PROM_HOME\prometheus.yml" -Encoding UTF8

Write-Output ""
Write-Output "Container Id:"

# 拉起`Node Exporter`容器
docker run -d `
  -p 9090:9090 `
  -v ${PROM_HOME}:/etc/prometheus:ro `
  -e TZ=Asia/Shanghai `
  --restart=unless-stopped `
  --hostname=prometheus `
  --network=perf `
  --name=perf-prometheus `
  $repository/prom/prometheus:latest `
  --config.file=/etc/prometheus/prometheus.yml `
  --web.config.file=/etc/prometheus/web-config.yml

Write-Output ""
Write-Output "Prometheus has been successfully deployed. You can access it via http://localhost:9090."
Write-Output ""
