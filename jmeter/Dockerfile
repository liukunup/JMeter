# Use the official Alpine Linux image as the base image
ARG BASE_IMAGE_VERSION=latest
FROM alpine:${BASE_IMAGE_VERSION}

# Maintainer
LABEL maintainer="LiuKun<liukunup@outlook.com>"

# JMeter version & download URL
ARG JMETER_VERSION=5.6.3
ARG JMETER_DOWNLOAD_URL=https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

# Set environment variables for JMeter
ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN=${JMETER_HOME}/bin
ENV JMETER_LIB=${JMETER_HOME}/lib
ENV JMETER_EXT=${JMETER_HOME}/lib/ext
ENV JMETER_LIC=${JMETER_HOME}/licenses
ENV JMETER_WORKSPACE=/opt/workspace

# The folder where custom plugins are stored
ENV JMETER_CUSTOM_PLUGINS_FOLDER=/plugins

# Java Runtime Environment
ARG JAVA_VERSION=openjdk21-jre

# Install Python 3 (default: true)
ARG INSTALL_PYTHON_3=true

# Timezone (default: Asia/Shanghai)
ARG TIMEZONE=Asia/Shanghai
ENV TZ=${TIMEZONE}

# Copy the entrypoint script to the root directory
COPY jmeter/entrypoint.sh /

# Install necessary packages
RUN    apk update \
	&& apk upgrade \
	# Add CA certificates and update
	&& apk add ca-certificates \
	&& update-ca-certificates \
	# Install Java, timezone data, curl, bash, vim, tar, unzip, make, net-tools, and nss
	&& apk add --update ${JAVA_VERSION} tzdata curl bash vim tar unzip make net-tools \
	&& apk add --no-cache nss \
	# Optionally install Python 3 if INSTALL_PYTHON_3 is true
	&& if [ "$INSTALL_PYTHON_3" = "true" ]; then apk add --update --no-cache python3 py3-pip && ln -sf python3 /usr/bin/python; fi \
	# Clean up APK cache
	&& rm -rf /var/cache/apk/* \
	# Create a temporary directory for dependencies
	&& mkdir -p /tmp/dependencies \
	# Download & Extract JMeter
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
	&& mkdir -p /opt \
	&& tar -zxf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	# Make the entrypoint script executable
	&& chmod +x /entrypoint.sh \
	# Clean up temporary dependencies directory
	&& rm -rf /tmp/dependencies

# Install security patch (update vulnerable jar packages)
COPY security /tmp/security/
RUN    chmod +x /tmp/security/patch.sh \
	&& cd /tmp/security \
	&& ./patch.sh \
	&& rm -rf /tmp/security

# Add JMeter bin directory to PATH
ENV PATH=${PATH}:${JMETER_BIN}

# Expose ports for JMeter Server and Mirror Server
EXPOSE 1099 50000 8080

# Set the working directory
WORKDIR ${JMETER_HOME}

# Set the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
