# This Dockerfile sets up a JMeter environment for running testcases.

# 1. Choose the version of JMeter to use
ARG BASE_IMAGE_VERSION=plugins-5.6.3
FROM liukunup/jmeter:${BASE_IMAGE_VERSION}

# 2. Set the working directory inside the container (don't modify)
ENV JMETER_WORKSPACE=/opt/workspace
WORKDIR	${JMETER_WORKSPACE}

# 3. Copy your testcases to the container
COPY testcases testcases

# 4. Copy your makefiles to the container
COPY jmeter-with-business/Makefile ./
