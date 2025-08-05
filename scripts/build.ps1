<#
.SYNOPSIS
Builds a JMeter Docker image with customizable versions.

.DESCRIPTION
This script builds a Docker image for JMeter with options to specify versions of the base image, JMeter, and Java.

.PARAMETER Image
Base image version (default: latest)

.PARAMETER JMeter
JMeter version (default: 5.6.3)

.PARAMETER Java
Java version (default: openjdk-21-jre)

.EXAMPLE
.\build.ps1 -Image latest -JMeter 5.6.3 -Java openjdk-21-jre
#>

param (
    [string]$Image = "latest",
    [string]$JMeter = "5.6.3",
    [string]$Java = "openjdk-21-jre"
)

# Configuration
$TargetDockerfile = "jmeter/Dockerfile.Ubuntu"
$ImageTag = "jmeter:ubuntu"

# Build Docker image
docker build `
    --build-arg IMAGE_VERSION="$Image" `
    --build-arg JMETER_VERSION="$JMeter" `
    --build-arg JAVA_VERSION="$Java" `
    -t "$ImageTag" `
    -f "$TargetDockerfile" `
    .
