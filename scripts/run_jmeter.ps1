# PowerShell

$JMETER_VERSION="5.6.3"
$CONTAINER_NAME="jmeter"
$CONTAINER_IMAGE="liukunup/jmeter:$JMETER_VERSION"

# example: .\run_jmeter.ps1 jmeter -v
docker run --rm --name=$CONTAINER_NAME -i -v "${PWD}:${PWD}" -w "${PWD}" `
  -e JVM_ARGS="-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m" `
  $CONTAINER_IMAGE $args
