# JMeter with Plugins

## Build

- Linux

```shell
#!/bin/bash

JMETER_VERSION="5.6.3"

docker build \
  --build-arg JMETER_VERSION=${JMETER_VERSION} \
  -f jmeter-with-plugins/Dockerfile \
  -t liukunup/jmeter:plugins-${JMETER_VERSION} .
```

- Windows

```powershell
# PowerShell

$JMETER_VERSION="5.6.3"

docker build `
  --build-arg JMETER_VERSION=$JMETER_VERSION `
  -f jmeter-with-plugins/Dockerfile `
  -t liukunup/jmeter:plugins-$JMETER_VERSION .
```