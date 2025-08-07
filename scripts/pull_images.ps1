# Power Shell

# Usage: .\pull_images.ps1

$REGISTRY = "docker.io"
$JMETER_VERSION = "5.6.3"

$IMAGES = @(
    # Alpine
    "liukunup/jmeter:$JMETER_VERSION-alpine-3-openjdk21-jre"
    "liukunup/jmeter:$JMETER_VERSION-alpine-3-openjdk21-jre-plugins"
    "liukunup/jmeter:$JMETER_VERSION-alpine-3-openjdk8-jre"
    "liukunup/jmeter:$JMETER_VERSION-alpine-3-openjdk8-jre-plugins"
    # Ubuntu
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre-plugins"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-8-jre"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-8-jre-plugins"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre-fullstack"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre-x11"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre-vnc-novnc"
    "liukunup/jmeter:$JMETER_VERSION-ubuntu-24.04-openjdk-21-jre-rdp"
)

foreach ($IMAGE in $IMAGES) {
    docker pull "$REGISTRY/$IMAGE-f42dd01"
    if ($REGISTRY -ne "docker.io") {
        docker tag "$REGISTRY/$IMAGE-f42dd01" "docker.io/$IMAGE-f42dd01"
        docker rmi "$REGISTRY/$IMAGE-f42dd01"
    }
}
