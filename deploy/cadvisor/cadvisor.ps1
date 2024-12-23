# 设置性能测试的根目录
$PERF_HOME = $env:USERPROFILE
$CADVISOR_HOME = "$PERF_HOME\cadvisor"

# 如果不存在则创建
if (-Not (Test-Path -Path $CADVISOR_HOME)) {
    New-Item -ItemType Directory -Path $CADVISOR_HOME -Force
}

Write-Output "==================== Deploy cAdvisor ===================="

Write-Output "1. checking perf network..."

# 如果不存在则创建
if (-Not (docker network ls --filter name=^perf$ --format '{{.Name}}')) {
    Write-Output "Network Id:"
    docker network create perf
    Write-Output ""
}

Write-Output "2. Starting cAdvisor container..."

# 询问并设置账号和密码
$username = Read-Host "[cAdvisor] Please input the username (default: admin)"
if ([string]::IsNullOrEmpty($username)) {
    $username = "admin"
}
$password = Read-Host "[cAdvisor] Please input the password" -AsSecureString
$encrypted_password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# 保存账号和密码
$htpasswdContent = "${username}: ${encrypted_password}"
$htpasswdPath = "$CADVISOR_HOME\perf.htpasswd"
$htpasswdContent | Out-File -FilePath $htpasswdPath -Force

# 询问镜像仓库
$repository = Read-Host "[cAdvisor] Please input the image repository (default: gcr.io)"
if ([string]::IsNullOrEmpty($repository)) {
    $repository = "gcr.io"
}

Write-Output ""
Write-Output "Container Id:"
# 拉起`cAdvisor`容器
docker run -d `
  -p 8080:8080 `
  --volume="${CADVISOR_HOME}:/etc/cadvisor" `
  --volume="/:/rootfs:ro" `
  --volume="/var/run:/var/run:ro" `
  --volume="/sys:/sys:ro" `
  --volume="/var/lib/docker/:/var/lib/docker:ro" `
  --volume="/dev/disk/:/dev/disk:ro" `
  --restart=unless-stopped `
  --hostname=cadvisor `
  --network=perf `
  --name=perf-cadvisor `
  --privileged `
  --device="/dev/kmsg" `
  "$repository/cadvisor/cadvisor:latest" `
  --http_auth_file /etc/cadvisor/perf.htpasswd `
  --http_auth_realm localhost

Write-Output ""
Write-Output "cAdvisor has been successfully deployed. You can access it via http://localhost:8080/metrics."
Write-Output ""
