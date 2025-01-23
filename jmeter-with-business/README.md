# JMeter with Business

## Build

- Linux

```shell
#!/bin/bash

JMETER_VERSION="5.6.3"

docker build \
  --build-arg JMETER_VERSION=${JMETER_VERSION} \
  -f jmeter-with-business/Dockerfile \
  -t liukunup/jmeter:business-${JMETER_VERSION} .
```

- Windows

```powershell
# PowerShell

$JMETER_VERSION="5.6.3"

docker build `
  --build-arg JMETER_VERSION=$JMETER_VERSION `
  -f jmeter-with-business/Dockerfile `
  -t liukunup/jmeter:business-$JMETER_VERSION .
```
