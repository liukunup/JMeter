# JMeter

![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)
![JMeter](https://img.shields.io/badge/jmeter-5.5-blue.svg)
![Java](https://img.shields.io/badge/java-openjdk15-blue.svg)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/jmeter)](https://artifacthub.io/packages/search?repo=jmeter)
[![Docker Hub](https://img.shields.io/badge/dockerhub-JMeter-brightgreen.svg)]({https://hub.docker.com/r/liukunup/jmeter})
![MIT License](https://img.shields.io/badge/wechat-我的代码温柔如风-brightgreen.svg)

***JMeter in Docker***

[JMeter 官方网站](https://jmeter.apache.org)

访问 [GitHub](https://github.com/liukunup/JMeter) 查看代码

访问 [Docker Hub](https://hub.docker.com/r/liukunup/jmeter) 选择`Docker Image`

访问 [Artifact Hub](https://artifacthub.io/packages/helm/jmeter/jmeter) 选择`Helm Chart`

喜欢本Repo可以`Star🌟`/`Fork🍴`/`Add to favorites🗂`，拜托啦～🫰


## OKR

**性能测试现状**

0. 绝大多数新入门的研发同学，并不十分了解性能测试；（缺乏经验）
1. 测试执行需要一定的经验和能力，容易出现能力不足导致测试结果不准；（新手 or 外包）
2. 总是在测试执行前，才发现脚本不好用，出现临阵磨枪；（练为战）
3. 测试脚本包含配置参数，一边改一边测，下次又不知道从哪里开始；（数据与脚本分离）
4. 测试指标or报告满天飞；（历史报告管理）
5. 各大厂内部`性能测试即服务`平台很好用，一旦离开人就傻了；（平台依赖）
6. 动不动就压挂线上服务；（毫无安全意识）
7. 各位小老板为了绩效拼命造轮子，平台换了一波又一波，导致业务同学反复迁移性能测试工程；（平台更迭）
8. 部分公司要求`把寒气传递给每个人`，想做性能测试但是缺乏机器资源；（缺乏资源）

**我们要达成的目标**

- `O-1` **降低测试门槛**
  - `KR-1-1` 完成**JMeter 1小时从入门到放弃**教程文档，帮助同学们快速掌握性能测试技能
  - `KR-1-2` 专家编写JMX文件，执行者仅需维护数据即可，实现数据与脚本分离
    - 参考`testcases`抽象方式
  - `KR-1-2` 团队制定压测准出方案，通过自动解析JTL文件，实现程序判定压测是否通过
- `O-2` **提高测试效率**
  - `KR-2-1` 一键部署，一键执行，无人值守
  - `KR-2-2` 自动梯度增压，达到收敛条件自动停止，实现自动性能探测
- `O-3` **有效保障质量**
  - `KR-3-1` 持续性能测试，将耗时延长、性能劣化扼杀在萌芽阶段
- `O-4` **极致工程化，拥抱云原生**
  - `KR-4-1` 代码开源、镜像就绪、应用发布，随时可用
    - [GitHub](https://github.com/liukunup/JMeter) 求个`Star🌟`
    - [Docker Hub](https://hub.docker.com/r/liukunup/jmeter) 求个`Star🌟`
    - [Artifact Hub](https://artifacthub.io/packages/helm/jmeter/jmeter) 求个`Star🌟`
  - `KR-4-2` 一套代码同时支持`JMeter`/`JMeter Server`/`Server Agent`三种模式
    - [Dockerfile](jmeter/Dockerfile)
    - [entrypoint.sh](jmeter/entrypoint.sh)
  - `KR-4-3` 支持Docker CLI/Docker Compose/Kubernetes/Helm等不同部署执行方式
    - `Docker CLI` 一键运行[JMeter](run_jmeter.sh)
    - `Docker CLI` 一键拉起[JMeter Server](run_jmeter_server.sh)
    - `Docker CLI` 一键拉起[Server Agent](run_server_agent.sh)
    - `Docker CLI` (推荐) 通过[Makefile](Makefile)完成上述动作，如`make run`可执行测试
    - `Docker Compose` (不推荐) 通过[Docker Compose](docker-compose.yaml)脚本一键拉起
    - `Kubernetes` [使用指南](all-in-one/README.md)以及[YAML](all-in-one/perf.yaml)
    - `Helm Chart` (推荐) 通过[Helm](helm-charts/README.md)安装JMeter的控制节点以及工作节点
  - `KR-4-4` 支持Jenkins流水线
  - `KR-4-5` 支持Grafana数据看板
- `O-5` **卷死在座的各位** 👻


## 快速上手

JMeter [Getting Started](https://jmeter.apache.org/usermanual/get-started.html)

## 支持标签

- `m.n` JMeter版本
- `m.n-x.y.z` JMeter版本-发布版本
- `business-x.y.z` 业务版本（将JMeter镜像作为基础镜像，带入了测试JMX以及数据）

## 使用指导

## 高级功能

## 参考资料

- [justb4/docker-jmeter](https://github.com/justb4/docker-jmeter)
- [JMeter InfluxDB v2.0 listener plugin](https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin)
