# Power Shell

# Usage: .\pull_images.ps1

$REGISTRY = "docker.io"
$JMETER_VERSION = "5.6.3"

$IMAGES = @(
    # OpenJDK 21
    "liukunup/jmeter:$JMETER_VERSION"
    "liukunup/jmeter:plugins-$JMETER_VERSION"
    "liukunup/jmeter:business-$JMETER_VERSION"
    # OpenJDK 8
    "liukunup/jmeter:openjdk8-$JMETER_VERSION"
    "liukunup/jmeter:openjdk8-plugins-$JMETER_VERSION"
)

foreach ($IMAGE in $IMAGES) {
    docker pull "$REGISTRY/$IMAGE"
    if ($REGISTRY -ne "docker.io") {
        docker tag "$REGISTRY/$IMAGE" "docker.io/$IMAGE"
        docker rmi "$REGISTRY/$IMAGE"
    }
}
