# Choose the JMeter version
ARG JMETER_VERSION=5.6.3
FROM liukunup/jmeter:${JMETER_VERSION}
# Set the working directory (don't modify)
ENV JMETER_WORKSPACE=/opt/workspace
WORKDIR	${JMETER_WORKSPACE}

# Copy your testcases to the container
COPY testcases testcases
# Copy your makefiles to the container
COPY business/Makefile ./
