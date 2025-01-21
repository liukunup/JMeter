# 部署说明

TL;DR;

``` Shell
curl -sfL https://raw.githubusercontent.com/liukunup/JMeter/refs/heads/docs/deploy/grafana/grafana.sh | sh -
```

``` PowerShell
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/liukunup/JMeter/main/deploy/grafana/grafana.ps1'))
```

## 已支持的部署

- [x] Grafana
- [ ] InfluxDB 2
- [ ] Node Exporter
- [ ] Prometheus

## 保姆式指导教程

### 快速拉起`JMeter`容器

```shell
# 试试看吧
docker run --rm liukunup/jmeter:5.6.3 jmeter -v

# 拉起容器 & 进入工作目录 (最常用+最有用)
docker run -d -v .:/opt/workspace -w /opt/workspace --name=jmeter liukunup/jmeter:5.6.3 keepalive
docker exec -it jmeter /bin/bash

# 当然，复杂一点还可以设置JVM参数
docker run -d -v .:/opt/workspace -w /opt/workspace -e JVM_ARGS="-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m" --name=jmeter-limit liukunup/jmeter:5.6.3 keepalive

# 拉起 JMeter Server (分布式)
docker run -d -p 1099:1099 -p 50000:50000 --restart=unless-stopped --name=jmeter-slave docker.realme.icu/liukunup/jmeter:5.6.3 jmeter-server
docker run -d -p 1099:1099 --restart=unless-stopped --name=jmeter-master docker.realme.icu/liukunup/jmeter:5.6.3 jmeter-server -Dremote_hosts="127.0.0.1:1099"

# 拉起 Server Agent (PerfMon Server Agent)
docker run -d -p 4444:4444 -e SA_INTERVAL=10 --restart=unless-stopped --name=server-agent liukunup/jmeter:plugins-5.6.3 server-agent
```

### 通过`Docker Compose`部署本机工作环境

优势：便于在本地快速拉起性能测试的工作环境，对环境安装、外部依赖都很少。

1. 准备`.env`来配置环境变量；

> 🧑‍💻 在线密码工具 https://www.json.cm/password/

- 生成一个强密码作为管理员密码
- 生成一个长度为64的字符串作为管理员Token（仅用于InfluxDB2）

在准备运行脚本、拉起容器的目录新建一个`.env`文件，写入以下内容。

```plaintext
# 账号 & 密码
ADMIN_USERNAME=admin
ADMIN_PASSWORD=changeit
# 管理员Token
INFLUXDB_ADMIN_TOKEN=<token>
```

2. 准备`prometheus.yml`和`web-config.yml`配置文件，映射到`/etc/prometheus`目录；

> 🧑‍💻 在线密码工具 https://www.json.cm/htpasswd/ 选`Crypt (all Unix servers)`进行加密

```shell
# 也可以使用以下命令行，对密码进行加密，效果一样（直接敲到命令行，输入两次密码）
htpasswd -nBC 12 '' | tr -d ':\n'
```

👇👇👇web-config.yml👇👇👇

```yaml
basic_auth_users:
  admin: <encrypted password>
```

👇👇👇prometheus.yml👇👇👇

如果需要监控某个环境，比如已经部署了`Node Exporter`，直接在下面的配置里添加即可。

```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:

  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']
```

3. 修改`jmeter-workspace`的映射目录，建议直接映射到您的jmx存放路径，同时也是您的工作目录；

4. (可选) 修改`DOCKER_INFLUXDB_INIT_ORG`参数，改成自己的公司名或组织名称；

5. 当一切都拉起之后，可以在Grafana里面配置数据源、导入数据看板。

```shell
# 拉起
docker compose up -d -p perf
# 移除
docker compose down
```

📊 推荐数据看板

- `ID=13644` JMeter Load Test (org.md.jmeter.influxdb2.visualizer) - influxdb v2.0 (Flux)
- `ID=1860`
- `ID=8919`
