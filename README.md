# JMeter in Docker

[![JMeter](https://img.shields.io/badge/JMeter-5.6.3-blue.svg)](https://jmeter.apache.org)
![Java](https://img.shields.io/badge/Java-OpenJDK%208-yellow.svg)
![Java](https://img.shields.io/badge/Java-OpenJDK%2021-blue.svg)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/jmeter)](https://artifacthub.io/packages/search?repo=jmeter)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-JMeter-brightgreen.svg)](https://hub.docker.com/r/liukunup/jmeter)
[![GHCR](https://img.shields.io/badge/GHCR-JMeter-brightgreen.svg)](https://github.com/liukunup/JMeter/pkgs/container/jmeter)
![ACR](https://img.shields.io/badge/ACR-JMeter-brightgreen.svg)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![WeChat](https://img.shields.io/badge/WeChat-我的代码温柔如风-brightgreen.svg)

**业界领先的云原生性能测试解决方案** | [English](README_EN.md)

> 欢迎`Star🌟`/`Fork🍴`/`Add to favorites🗂` 🫰 🫰 🫰

## 支持的标签和架构

拉取镜像 `docker pull liukunup/jmeter:<version>`

> docker pull liukunup/jmeter:5.6.3

**标签**

- [`5.6.2`](https://hub.docker.com/r/liukunup/jmeter), [`5.6.3`](https://hub.docker.com/r/liukunup/jmeter)
- [`5.5`](https://hub.docker.com/r/liukunup/jmeter)

**架构**

- OpenJDK 21 `linux/amd64`, `linux/arm64`, `linux/ppc64le`, `linux/riscv64`, `linux/s390x`
- OpenJDK 8 `linux/amd64`, `linux/arm/v6`, `linux/arm/v7`, `linux/arm64/v8`, `linux/ppc64le`, `linux/s390x`

**仓库**

- docker.io/liukunup/jmeter:5.6.3
- ghcr.io/liukunup/jmeter:5.6.3
- registry.cn-hangzhou.aliyuncs.com/liukunup/jmeter:5.6.3

### 版本说明

**正式版本**

| 格式             | 描述                                                           | 示例             |
|------------------|--------------------------------------------------------------|------------------|
| `x.y.z`          | 仅包含JMeter[核心组件](jmeter/Dockerfile)                       | `5.6.3`          |
| `plugins-x.y.z`  | 包含核心组件+[常用插件](jmeter-with-plugins/Dockerfile)          | `plugins-5.6.3`  |
| `business-x.y.z` | 包含核心组件+常用插件+[业务样例](jmeter-with-business/Dockerfile) | `business-5.6.3` |
| `openjdk8-x.y.z` | 使用`OpenJDK 8`的版本                                          | `openjdk8-5.6.3` |

***预发版本***

包含`beta`标识，用于功能预览，例如：`beta-5.6.3`。

***开发版本***

包含`dev`标识，禁止在生产环境使用，例如：`dev-3b84d21`。

## 仓库特色

- 🔐【安全可靠】尽可能地消减了已发现的安全风险
- 📦【开箱即用】尽可能地贴近了实际使用场景，减少了环境安装成本
- 🔌【插件生态】既预置了常用插件，又支持自定义插件引入
- 🎛️【架构覆盖】覆盖了多版本、多架构，尽可能全面地适配

## 最佳实践

- [宿主机启动`JMeter Controller`作为控制节点 + `Docker Desktop`部署`JMeter Server`容器作为从节点](docs/最佳实践.md#宿主机启动jmeter-controller作为控制节点--docker-desktop部署jmeter-server容器作为从节点)

## 🚀 快捷访问

访问 [GitHub](https://github.com/liukunup/JMeter) 查看源代码

访问 [Docker Hub](https://hub.docker.com/r/liukunup/jmeter) 选择`Docker Image`

访问 [Artifact Hub](https://artifacthub.io/packages/helm/jmeter/jmeter) 选择`Helm Chart`

## 🚀 快速上手

- 快速启动`JMeter Server`(即从节点、Slave、服务端)

```shell
docker run -d \
  -p 1099:1099 \
  -p 50000:50000 \
  --restart=unless-stopped \
  --name=jmeter-server \
  liukunup/jmeter:<版本号> \
  jmeter-server \
  -Djava.rmi.server.hostname=<宿主机IP>
```

本地连接时，修改配置文件`安装路径/bin/jmeter.properties`

```text
remote_hosts=localhost:1099
```

```text
server.rmi.ssl.disable=true
```

- 在集群中快速部署性能测试工具

```shell
# 新增仓库并更新
helm repo add jmeter https://liukunup.github.io/helm-charts
helm repo update
# 部署
helm install my-jmeter jmeter/jmeter
# 卸载
helm uninstall my-jmeter
```

## 参考资料

- [JMeter Getting Started](https://jmeter.apache.org/usermanual/get-started.html)
- [JMeter Distributed Testing](https://jmeter.apache.org/usermanual/jmeter_distributed_testing_step_by_step.html)
- [justb4/docker-jmeter](https://github.com/justb4/docker-jmeter)
- [alpine-docker/jmeter](https://github.com/alpine-docker/jmeter)
- [JMeter InfluxDB v2.0 listener plugin](https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin)
