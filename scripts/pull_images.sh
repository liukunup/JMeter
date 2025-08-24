#!/bin/bash

# Usage: ./pull_images.sh [-SHA <git_short_sha>]

SHA="${1:-}"  # 可选的 Git 短 SHA 值，用于拉取特定构建版本的镜像

REGISTRY="docker.io"
JMETER_VERSION="5.6.3"
IMAGE_BASE="liukunup/jmeter"

OS_ALPINE="alpine-3"
OS_UBUNTU="ubuntu-24.04"

JRE_JDK21="openjdk-21-jre"
# JRE_JDK17="openjdk-17-jre"
# JRE_JDK11="openjdk-11-jre"
# JRE_JDK8="openjdk-8-jre"

IMAGES=(
    # Alpine 基础镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_ALPINE}-${JRE_JDK21}"
    # Alpine 带插件镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_ALPINE}-${JRE_JDK21}-plugins"
    
    # Ubuntu 基础镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_UBUNTU}-${JRE_JDK21}"
    # Ubuntu 带插件镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_UBUNTU}-${JRE_JDK21}-plugins"
    # Ubuntu 带 RDP 远程桌面镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_UBUNTU}-${JRE_JDK21}-rdp"
    # Ubuntu 带 VNC 远程桌面镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_UBUNTU}-${JRE_JDK21}-vnc"
    # Ubuntu 带 NoMachine 远程桌面镜像
    "${IMAGE_BASE}:${JMETER_VERSION}-${OS_UBUNTU}-${JRE_JDK21}-nomachine"
)

for IMAGE in "${IMAGES[@]}"; do
    # 构建完整的镜像引用
    IMAGE_REF="${REGISTRY}/${IMAGE}"
    
    # 如果提供了 SHA 参数，添加到镜像标签中
    if [ -n "$SHA" ]; then
        IMAGE_REF="${IMAGE_REF}-${SHA}"
    fi

    echo -e "\033[32m正在拉取镜像: ${IMAGE_REF}\033[0m"
    
    # 拉取镜像
    docker pull "${IMAGE_REF}"
    
    # 检查拉取是否成功
    if [ $? -eq 0 ]; then
        echo -e "\033[32m镜像拉取成功: ${IMAGE_REF}\033[0m"
        
        # 如果不是默认的 Docker Hub 注册表，需要重新标记镜像
        if [ "$REGISTRY" != "docker.io" ]; then
            echo -e "\033[33m重新标记镜像: ${IMAGE_REF} -> docker.io/${IMAGE}\033[0m"
            docker tag "${IMAGE_REF}" "docker.io/${IMAGE}"
            docker rmi "${IMAGE_REF}"
        fi
    else
        echo -e "\033[31m镜像拉取失败: ${IMAGE_REF}\033[0m"
        exit 1
    fi
done

echo -e "\033[32m所有镜像拉取完成!\033[0m"