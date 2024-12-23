# 设定生成Token的长度
$TOKEN_LENGTH = 64
# 用于生成Token的字符集
$TOKEN_CHAR_SET = "a-zA-Z0-9-_="

Write-Output "==================== Deploy InfluxDB 2 ===================="

Write-Output "1. checking perf network..."

# 如果网络不存在则创建
$networkExists = docker network ls --filter name=^perf$ --format "{{.Name}}"
if (-not $networkExists) {
  Write-Output "Network Id:"
  docker network create perf
  Write-Output ""
}

Write-Output "2. Generating admin Token for InfluxDB2..."

# 生成随机Token的方法
function Generate-Token {
  param (
    [int]$length,
    [string]$charset
  )
  -join ((65..90) + (97..122) + (48..57) + (33..47) + (58..64) + (91..96) + (123..126) | Get-Random -Count $length | ForEach-Object {[char]$_})
}

# 生成Token
$TOKEN = Generate-Token -length $TOKEN_LENGTH -charset $TOKEN_CHAR_SET

Write-Output "3. Starting InfluxDB2 container..."

# 询问并设置账号和密码
$username = Read-Host "[InfluxDB2] Please input the username (default: admin)"
if (-not $username) { $username = "admin" }
$password = Read-Host "[InfluxDB2] Please input the password (default: perf@JMeter#1024)"
if (-not $password) { $password = "perf@JMeter#1024" }
# 询问并设置组织和桶
$organization = Read-Host "[InfluxDB2] Please input the organization (default: Org)"
if (-not $organization) { $organization = "Org" }
$bucket = Read-Host "[InfluxDB2] Please input the bucket (default: JMeter)"
if (-not $bucket) { $bucket = "JMeter" }

# 询问镜像仓库
$repository = Read-Host "[InfluxDB2] Please input the image repository (default: docker.io)"
if (-not $repository) { $repository = "docker.io" }

Write-Output ""
Write-Output "Container Id:"
# 拉起`InfluxDB 2`容器
docker run -d `
  -p 8086:8086 `
  -v influxdb-data:/var/lib/influxdb2 `
  -v influxdb-config:/etc/influxdb2 `
  -e DOCKER_INFLUXDB_INIT_MODE=setup `
  -e DOCKER_INFLUXDB_INIT_USERNAME=$username `
  -e DOCKER_INFLUXDB_INIT_PASSWORD=$password `
  -e DOCKER_INFLUXDB_INIT_ORG=$organization `
  -e DOCKER_INFLUXDB_INIT_BUCKET=$bucket `
  -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$TOKEN `
  --restart=unless-stopped `
  --hostname=influxdb `
  --network=perf `
  --name=perf-influxdb `
  $repository/influxdb:2

# 提示保存
Write-Output ""
Write-Output "Grafana has been successfully deployed. You can access it via http://localhost:8086."
Write-Output ""
Write-Output "Please save the following Token securely, it is your credential to access InfluxDB2."
Write-Output ""
Write-Output "token: $TOKEN"
Write-Output ""
