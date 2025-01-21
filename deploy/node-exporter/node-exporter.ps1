# 设置性能测试的根目录
$PERF_HOME = (Get-Location).Path
$NODE_EXPORTER_HOME = "$PERF_HOME\node-exporter"

# 如果不存在则创建
if (-Not (Test-Path -Path $NODE_EXPORTER_HOME)) {
    New-Item -ItemType Directory -Path $NODE_EXPORTER_HOME
}

Write-Output "==================== Deploy Node Exporter ===================="

Write-Output "1. checking perf network..."

# 如果不存在则创建
if (-Not (docker network ls --filter name=^perf$ --format "{{.Name}}")) {
    Write-Output "Network Id:"
    docker network create perf
    Write-Output ""
}

Write-Output "2. Starting Node-Exporter container..."

# 询问并设置账号和密码
$username = Read-Host "[Node Exporter] Please input the username (default: admin)"
if ([string]::IsNullOrEmpty($username)) {
    $username = "admin"
}

$password = Read-Host "[Node Exporter] Please input the password (default: perf@JMeter#1024)"
if ([string]::IsNullOrEmpty($password)) {
    $password = "perf@JMeter#1024"
}

# 询问镜像仓库
$repository = Read-Host "[Node Exporter] Please input the image repository (default: docker.io)"
if ([string]::IsNullOrEmpty($repository)) {
    $repository = "docker.io"
}

# 加密处理
$encrypted_password = & htpasswd -nBC 12 '' | Out-String
$encrypted_password = $encrypted_password -replace ':\n', ''

$webConfigContent = @"
basic_auth_users:
  $username: $encrypted_password
"@

$webConfigPath = "$NODE_EXPORTER_HOME\web-config.yml"
$webConfigContent | Out-File -FilePath $webConfigPath -Encoding utf8

Write-Output ""
Write-Output "Container Id:"

# 拉起`Node Exporter`容器
docker run -d `
  -p 9100:9100 `
  -v "$NODE_EXPORTER_HOME:/etc/node-exporter" `
  -v "/:/host:ro,rslave" `
  --net=host `
  --pid=host `
  --restart=unless-stopped `
  --hostname=node-exporter `
  --network=perf `
  --name=perf-node-exporter `
  "$repository/prom/node-exporter:latest" `
  --path.rootfs=/host `
  --web.config.file=/etc/node-exporter/web-config.yml

Write-Output ""
Write-Output "Node-Exporter has been successfully deployed. You can access it via http://localhost:9100/metrics."
Write-Output ""
