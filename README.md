# JMeter

***JMeter in Docker***

[JMeter 官方网站](https://jmeter.apache.org)

如果喜欢请`Star🌟`/`Fork🍴`/`Add to favorites🗂`,拜托啦～🫰


## OKR

性能测试现状

1. 测试执行需要一定的经验和能力，容易出现能力不足导致测试结果不准；（新手 or 外包）
2. 总是在测试执行前，才发现脚本不好用，出现临阵磨枪；（练为战）
3. 测试脚本包含配置参数，一边改一边测，下次又不知道从哪里开始；（数据与脚本分离）
4. 测试指标or报告满天飞；（历史报告管理）
5. 各大厂内部`性能测试即服务`平台很好用，一旦离开人就傻了；（平台依赖）
6. 动不动就压挂线上服务；（毫无安全意识）

- `O-1` **降低测试门槛**
  - `KR-1-1` 专家编写JMX文件，执行者仅需维护数据即可，实现数据与脚本分离
  - `KR-1-2` 团队制定压测准出方案，通过自动解析JTL文件，实现程序判定压测是否通过
- `O-2` **提高测试效率**
  - `KR-2-1` 一键执行，无人值守
  - `KR-2-2` 自动梯度增压，达到收敛条件自动停止，实现自动性能探测
- `O-3` **有效保障质量**
  - `KR-3-1` 持续性能测试，将耗时延长、性能劣化扼杀在萌芽阶段
- `O-4` **极致工程化，拥抱云原生**
  - `KR-4-1` 代码开源、镜像开源
  - `KR-4-2` 一套代码/镜像支持JMeter/JMeter Server/Server Agent三种不同模式
  - `KR-4-3` 支持Docker CLI/Docker Compose/Kubernetes/Helm等不同部署执行方式
  - `KR-4-4` 支持Jenkins流水线
  - `KR-4-5` 支持Grafana数据看板
- `O-5` **卷死在座的各位** 👻


## 快速上手

## 支持的标签及镜像链接

## 使用指导

## 高级功能

## 参考资料

- [justb4/docker-jmeter](https://github.com/justb4/docker-jmeter)
- [JMeter InfluxDB v2.0 listener plugin](https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin)
