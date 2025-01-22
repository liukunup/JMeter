ARG ALPINE_VERSION=latest
FROM alpine:${ALPINE_VERSION}

LABEL LIUKUN="liukunup@outlook.com"

# JMeter
ARG JMETER_VERSION=5.6.3
ARG JMETER_DOWNLOAD_URL=https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN=${JMETER_HOME}/bin
ENV JMETER_LIB=${JMETER_HOME}/lib
ENV JMETER_EXT=${JMETER_HOME}/lib/ext
ENV JMETER_LIC=${JMETER_HOME}/licenses
ENV JMETER_WORKSPACE=/opt/workspace

# Custom Plugins
ENV JMETER_CUSTOM_PLUGINS_FOLDER=/plugins

# Java Runtime Environment
ARG JRE_VERSION=openjdk21-jre

# Install Python 3 (default: true)
ARG INSTALL_PYTHON_3=true

# Timezone (default: Asia/Shanghai)
ARG TIMEZONE=Asia/Shanghai
ENV TZ=${TIMEZONE}

# Install packages
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update ${JRE_VERSION} tzdata curl bash vim tar unzip make net-tools \
	&& apk add --no-cache nss \
	&& if [ "$INSTALL_PYTHON_3" = "true" ]; then apk add --update --no-cache python3 py3-pip && ln -sf python3 /usr/bin/python; fi \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
	&& mkdir -p /opt \
	&& tar -zxf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	&& rm -rf /tmp/dependencies

# Install security patch (update vulnerable jar packages)
COPY security /tmp/security/
RUN    chmod +x /tmp/security/patch.sh \
	&& cd /tmp/security \
	&& ./patch.sh \
	&& rm -rf /tmp/security

ENV PATH=${PATH}:${JMETER_BIN}

COPY jmeter/entrypoint.sh /

# Expose ports for `JMeter Server` mode
EXPOSE 1099 50000

WORKDIR ${JMETER_HOME}

ENTRYPOINT ["/entrypoint.sh"]
