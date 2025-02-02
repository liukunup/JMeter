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
docker run -d --network host --restart=unless-stopped --name=jmeter-worker liukunup/jmeter:5.6.3 jmeter-server
docker run -d -p 1099:1099 -p 50000:50000 --restart=unless-stopped --name=jmeter-worker liukunup/jmeter:5.6.3 jmeter-server
docker run -d -p 1099:1099 --restart=unless-stopped --name=jmeter-controller liukunup/jmeter:5.6.3 jmeter-server -Dremote_hosts="127.0.0.1:1099"

# 拉起 Server Agent (PerfMon Server Agent)
docker run -d -p 4444:4444 -e SA_INTERVAL=10 --restart=unless-stopped --name=server-agent liukunup/jmeter:plugins-5.6.3 server-agent
```
