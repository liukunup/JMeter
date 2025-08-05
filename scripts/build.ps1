# Power Shell

# Usage: .\scripts\build.ps1

docker build `
    --build-arg IMAGE_VERSION="latest" `
    --build-arg JMETER_VERSION="5.6.3" `
    --build-arg JAVA_VERSION="openjdk-21-jre" `
    -t "jmeter:ubuntux" `
    -f .\jmeter-with-remote-gui\Dockerfile.Ubuntu `
    .
