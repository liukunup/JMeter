# PowerShell
# Usage: .\pull_images.ps1 [-SHA <git_short_sha>]

param(
    [string]$SHA = ""  # 可选的 Git 短 SHA 值，用于拉取特定构建版本的镜像
)

$COMMON_PARAMS = @{
    Registry = "docker.io"         # 默认 Docker 注册表
    Jmeter = "5.6.3"               # JMeter 版本号
    ImageBase = "liukunup/jmeter"  # 基础镜像名称
    OS = @{                        # 支持的操作系统类型
        Alpine = "alpine-3"
        Ubuntu = "ubuntu-24.04"
    }
    JRE = @{                       # 支持的 Java 运行时环境版本
        JDK21 = "openjdk-21-jre"
        JDK17 = "openjdk-17-jre"
        JDK11 = "openjdk-11-jre"
        JDK8 = "openjdk-8-jre"
    }
}

$IMAGES = @(
    # Alpine 基础镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK21)"
    # Alpine 带插件镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Alpine)-$($COMMON_PARAMS.JRE.JDK21)-plugins"

    # Ubuntu 基础镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)"
    # Ubuntu 带插件镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-plugins"
    # Ubuntu 带 RDP 远程桌面镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-rdp"
    # Ubuntu 带 VNC 远程桌面镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-vnc"
    # Ubuntu 带 NoMachine 远程桌面镜像
    "$($COMMON_PARAMS.ImageBase):$($COMMON_PARAMS.Jmeter)-$($COMMON_PARAMS.OS.Ubuntu)-$($COMMON_PARAMS.JRE.JDK21)-nomachine"
)

foreach ($IMAGE in $IMAGES) {
    # 构建完整的镜像引用
    $imageRef = "$($COMMON_PARAMS.Registry)/$IMAGE"
    
    # 如果提供了 SHA 参数，添加到镜像标签中
    if (-not [string]::IsNullOrEmpty($SHA)) {
        $imageRef += "-$SHA"
    }

    Write-Host "正在拉取镜像: $imageRef" -ForegroundColor Green
    
    # 拉取镜像
    docker pull $imageRef
    
    # 如果不是默认的 Docker Hub 注册表，需要重新标记镜像
    if ($COMMON_PARAMS.Registry -ne "docker.io") {
        Write-Host "重新标记镜像: $imageRef -> docker.io/$IMAGE" -ForegroundColor Yellow
        docker tag $imageRef "docker.io/$IMAGE"
        docker rmi $imageRef
    }
}

Write-Host "所有镜像拉取完成!" -ForegroundColor Green