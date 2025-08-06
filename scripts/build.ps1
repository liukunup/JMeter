<#
.SYNOPSIS
Docker Image Builder for JMeter

.DESCRIPTION
Builds a JMeter Docker image with customizable parameters.

.PARAMETER Dockerfile
Specify Dockerfile to build (default: jmeter/Dockerfile.Ubuntu)

.PARAMETER Prefix
Tag prefix for the built image (default: ubuntu)

.PARAMETER Base
Base image version (default: 24.04)

.PARAMETER JMeter
JMeter version (default: 5.6.3)

.PARAMETER JRE
Java Runtime Environment version (default: openjdk-21-jre)
#>

param (
    [string]$Dockerfile = "jmeter/Dockerfile.Ubuntu",
    [string]$Prefix = "ubuntu",
    [string]$Base = "24.04",
    [string]$JMeter = "5.6.3",
    [string]$JRE = "openjdk-21-jre"
)

# ------------------------- Image Building -------------------------
# Build docker image with specified parameters
docker build `
    --build-arg BASE_IMAGE_VERSION="$Base" `
    --build-arg JMETER_VERSION="$JMeter" `
    --build-arg JRE_VERSION="$JRE" `
    -t "jmeter:${Prefix}-${Base}" `
    -f "$Dockerfile" `
    .

# Show image list 
docker images
