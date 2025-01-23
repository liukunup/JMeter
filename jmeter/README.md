# JMeter

## Build

- Linux

```shell
#!/bin/bash

ALPINE_VERSION=latest
JRE_VERSION=openjdk21-jre
INSTALL_PYTHON_3=true
JMETER_VERSION=5.6.3
TIMEZONE=Asia/Shanghai

docker build \
  --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
  --build-arg JRE_VERSION=${JRE_VERSION} \
  --build-arg INSTALL_PYTHON_3=${INSTALL_PYTHON_3} \
  --build-arg JMETER_VERSION=${JMETER_VERSION} \
  --build-arg TIMEZONE=${TIMEZONE} \
  -f jmeter/Dockerfile \
  -t liukunup/jmeter:${JMETER_VERSION} .
```

- Windows

```powershell
# PowerShell

$ALPINE_VERSION=latest
$JRE_VERSION=openjdk21-jre
$INSTALL_PYTHON_3=true
$JMETER_VERSION=5.6.3
$TIMEZONE=Asia/Shanghai

docker build `
  --build-arg ALPINE_VERSION=$ALPINE_VERSION `
  --build-arg JRE_VERSION=$JRE_VERSION `
  --build-arg INSTALL_PYTHON_3=$INSTALL_PYTHON_3 `
  --build-arg JMETER_VERSION=$JMETER_VERSION `
  --build-arg TIMEZONE=$TIMEZONE `
  -f jmeter/Dockerfile `
  -t liukunup/jmeter:$JMETER_VERSION .
```
