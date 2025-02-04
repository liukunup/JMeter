# JMeter in Docker

[![JMeter](https://img.shields.io/badge/JMeter-5.6.3-blue.svg)](https://jmeter.apache.org)
![Java](https://img.shields.io/badge/Java-OpenJDK%208-yellow.svg)
![Java](https://img.shields.io/badge/Java-OpenJDK%2021-blue.svg)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/jmeter)](https://artifacthub.io/packages/helm/jmeter/jmeter)
[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-jmeter-brightgreen.svg)](https://hub.docker.com/r/liukunup/jmeter)
[![GHCR](https://img.shields.io/badge/GHCR-jmeter-brightgreen.svg)](https://github.com/liukunup/JMeter/pkgs/container/jmeter)
![ACR](https://img.shields.io/badge/ACR-jmeter-brightgreen.svg)
![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![WeChat](https://img.shields.io/badge/WeChat-我的代码温柔如风-brightgreen.svg)

**Industry-leading cloud-native performance testing solution** | [中文](README.md)

## Supported Tags/Architectures/Repositories

**Tags**

- [`5.6.2`](https://hub.docker.com/r/liukunup/jmeter), [`5.6.3`](https://hub.docker.com/r/liukunup/jmeter)
- [`5.5`](https://hub.docker.com/r/liukunup/jmeter)

**Architectures**

- OpenJDK 21 `linux/amd64`, `linux/arm64`, `linux/ppc64le`, `linux/riscv64`, `linux/s390x`
- OpenJDK 8  `linux/amd64`, `linux/arm/v6`, `linux/arm/v7`, `linux/arm64/v8`, `linux/ppc64le`, `linux/s390x`

**Repositories**

- `docker.io`/liukunup/jmeter
- `ghcr.io`/liukunup/jmeter
- `registry.cn-hangzhou.aliyuncs.com`/liukunup/jmeter

### Version Description

**Stable Versions**

| Format             | Description                                                                                           | Example           |
|--------------------|-------------------------------------------------------------------------------------------------------|-------------------|
| `x.y.z`            | Only JMeter [core components](jmeter/Dockerfile), corresponding to the official JMeter version        | `5.6.3`           |
| `plugins-x.y.z`    | Core components + pre-installed [common plugins](jmeter-with-plugins/Dockerfile)                      | `plugins-5.6.3`   |
| `business-x.y.z`   | Core components + pre-installed common plugins + [business examples](jmeter-with-business/Dockerfile) | `business-5.6.3`  |
| `openjdk8-x.y.z`   | Using `OpenJDK 8` (retained for architecture compatibility)                                           | `openjdk8-5.6.3`  |

> Note: Business images are for demonstration purposes only and are not typically provided.

**Pre-installed List**

| Plugin or Jar                  | Version |
|--------------------------------|---------|
| jp@gc - Custom Thread Groups   | 2.10    |
| jp@gc - PerfMon                | 2.1     |
| InfluxDB v2.8 Listener         | 2.8     |
| MySQL Connector-J              | 9.1.0   |
| WebSocket Samplers             | 1.2.10  |
| Server Agent                   | 2.2.3   |

***Pre-release Versions***

> Usually not provided.

Contains the `beta` identifier for feature previews, e.g. `beta-5.6.3`.

***Development Versions***

Contains the `dev` identifier, not for production use, e.g. `dev-3b84d21`.

## 🌟 Repository Features

- 🔐【Secure and Reliable】Minimized known security risks
- 📦【Ready to Use】Close to real usage scenarios, reducing environment setup costs
- 🔌【Plugin Ecosystem】Pre-installed common plugins and supports custom plugin introduction
- 🎛️【Architecture Coverage】Supports multiple versions and architectures for comprehensive adaptation

## 🧑‍💻 Best Practices

- [Host starts `JMeter Controller` as control node + `Docker Desktop` deploys `JMeter Server` container as slave node](docs/BestPractices.md#host-starts-jmeter-controller-as-control-node--docker-desktop-deploys-jmeter-server-container-as-slave-node)
- [Host starts `JMeter Controller` as control node + `Kubernetes` deploys `JMeter Server` container as slave node](docs/BestPractices.md#host-starts-jmeter-controller-as-control-node--kubernetes-deploys-jmeter-server-container-as-slave-node)
- [`Docker Desktop` deploys `JMeter` control node + slave node](docs/BestPractices.md#docker-desktop-deploys-jmeter-control-node-slave-node)
- [`Kubernetes` deploys `JMeter` control node + slave node](docs/BestPractices.md#kubernetes-deploys-jmeter-control-node-slave-node)
- [Full stack `JMeter` + `InfluxDB` + `Grafana`](docs/BestPractices.md#full-stack-jmeter--influxdb--grafana)
- [Full stack `JMeter` + `Kafka` + `ClickHouse` + `Grafana`](docs/BestPractices.md#full-stack-jmeter--kafka--clickhouse--grafana)

## 🚀 Quick Start

- Pull the image `docker pull liukunup/jmeter:<version>`

```shell
docker pull liukunup/jmeter:5.6.3
```

- Quickly start `JMeter Server` (i.e., slave node, service node)

```shell
docker run -d \
    -p 1099:1099 \
    -p 50000:50000 \
    --restart=unless-stopped \
    --name=jmeter-server \
    liukunup/jmeter:<version> \
    jmeter-server \
    -Djava.rmi.server.hostname=<Docker Host IP>
```

When connecting locally to JMeter Server, find and modify the following fields in the configuration file located at `~/apache-jmeter-<version>/bin/jmeter.properties`

```text
remote_hosts=localhost:1099
```

```text
server.rmi.ssl.disable=true
```

- Quickly deploy performance testing tools in a cluster

```shell
# Add and update repository
helm repo add jmeter https://liukunup.github.io/helm-charts
helm repo update
# Deploy
helm install my-jmeter jmeter/jmeter
# Uninstall
helm uninstall my-jmeter
```

## ✈️ Quick Access

Visit [GitHub](https://github.com/liukunup/JMeter) to view the source code

Visit [Docker Hub](https://hub.docker.com/r/liukunup/jmeter) to choose `Docker Image`

Visit [Artifact Hub](https://artifacthub.io/packages/helm/jmeter/jmeter) to choose `Helm Chart`

## 📄 References

- [JMeter Getting Started](https://jmeter.apache.org/usermanual/get-started.html)
- [JMeter Distributed Testing](https://jmeter.apache.org/usermanual/jmeter_distributed_testing_step_by_step.html)
- [justb4/docker-jmeter](https://github.com/justb4/docker-jmeter)
- [alpine-docker/jmeter](https://github.com/alpine-docker/jmeter)
- [JMeter InfluxDB v2.0 listener plugin](https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin)
