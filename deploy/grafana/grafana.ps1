# 设置性能测试根目录
$PERF_HOME = $env:USERPROFILE
$GF_HOME = "$PERF_HOME\grafana"

# 配置数据源目录
$PERF_DATASOURCES = "$GF_HOME\provisioning\datasources"
if (-not (Test-Path -Path $PERF_DATASOURCES)) {
    New-Item -ItemType Directory -Path $PERF_DATASOURCES | Out-Null
}

# 配置看板目录
$PERF_DASHBOARDS = "$GF_HOME\provisioning\dashboards"
if (-not (Test-Path -Path $PERF_DASHBOARDS)) {
    New-Item -ItemType Directory -Path $PERF_DASHBOARDS | Out-Null
}

Write-Output "==================== Deploy Grafana ===================="

Write-Output "1. checking perf network..."

# 如果不存在则创建
if (-not (docker network ls --filter name=^perf$ --format "{{.Name}}")) {
    Write-Output "Network Id:"
    docker network create perf
    Write-Output ""
}

Write-Output "2. starting Grafana container..."

# 询问并设置账号和密码
$username = Read-Host "[Grafana] Please input the username (default: admin)"
if ([string]::IsNullOrEmpty($username)) {
    $username = "admin"
}
$password = Read-Host "[Grafana] Please input the password (default: perf@JMeter#1024)"
if ([string]::IsNullOrEmpty($password)) {
    $password = "perf@JMeter#1024"
}

# 询问镜像仓库
$repository = Read-Host "[Grafana] Please input the image repository (default: docker.io)"
if ([string]::IsNullOrEmpty($repository)) {
    $repository = "docker.io"
}

Write-Output ""
Write-Output "Container Id:"
# 拉起`Grafana`容器
docker run -d `
  -p 3000:3000 `
  -v perf-grafana-storage:/var/lib/grafana `
  -v ${PERF_DATASOURCES}:/etc/grafana/provisioning/datasources `
  -v ${PERF_DASHBOARDS}:/etc/grafana/provisioning/dashboards `
  -e GF_SECURITY_ADMIN_USER=$username `
  -e GF_SECURITY_ADMIN_PASSWORD=$password `
  --restart=unless-stopped `
  --hostname=grafana `
  --network=perf `
  --name=perf-grafana `
  "$repository/grafana/grafana:latest"

Write-Output ""
Write-Output "Grafana has been successfully deployed. You can access it via http://localhost:3000."
Write-Output ""

# 配置数据源
function Configure-Datasource-InfluxDB2 {
    $hostname = Read-Host "[InfluxDB2] Please input the hostname [default: influxdb]"
    if ([string]::IsNullOrEmpty($hostname)) {
        $hostname = "influxdb"
    }
    $port = Read-Host "[InfluxDB2] Please input the port [default: 8086]"
    if ([string]::IsNullOrEmpty($port)) {
        $port = "8086"
    }
    $organization = Read-Host "[InfluxDB2] Please input the organization [default: Org]"
    if ([string]::IsNullOrEmpty($organization)) {
        $organization = "Org"
    }
    $bucket = Read-Host "[InfluxDB2] Please input the bucket [default: JMeter]"
    if ([string]::IsNullOrEmpty($bucket)) {
        $bucket = "JMeter"
    }
    $token = Read-Host "[InfluxDB2] Please input the token"
    if ([string]::IsNullOrEmpty($token)) {
        $token = "Please input your token"
    }

    Write-Output "Configure datasource InfluxDB2 for Grafana..."

    $influxdb2Yaml = @"
apiVersion: 1

datasources:
  - name: InfluxDB2
    type: influxdb
    access: proxy
    url: http://${hostname}:${port}
    jsonData:
      version: Flux
      organization: $organization
      defaultBucket: $bucket
      tlsSkipVerify: true
    secureJsonData:
      token: $token
"@

    $influxdb2Yaml | Out-File -FilePath "$PERF_DATASOURCES\influxdb2.yaml" -Encoding utf8

    Write-Output ""
    Write-Output "[InfluxDB2] Datasource has been successfully configured. You can verify it by checking the file: $PERF_DATASOURCES\influxdb2.yaml"
    Write-Output ""
}

# 询问是否配置数据源
$answer = Read-Host "Do you want to configure datasource InfluxDB2 for Grafana? [Y/N]"
if ($answer -match "^[Yy]") {
    Configure-Datasource-InfluxDB2
} else {
    Write-Output "[InfluxDB2] datasource configuration skipped."
    exit 0
}
