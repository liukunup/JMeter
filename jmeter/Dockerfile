# 基础镜像
ARG ALPINE_VERSION=3
FROM alpine:${ALPINE_VERSION}
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# 默认时区
ARG TIMEZONE=Asia/Shanghai
ENV TZ=${TIMEZONE}

# JMeter 版本及下载源
ARG JMETER_VERSION=5.0
ENV JMETER_DOWNLOAD_URL=https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz
# JMeter 应用程序目录
ENV JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}
ENV JMETER_BIN=${JMETER_HOME}/bin
ENV JMETER_LIB=${JMETER_HOME}/lib
ENV JMETER_EXT=${JMETER_HOME}/lib/ext
ENV JMETER_LIC=${JMETER_HOME}/licenses
# JMeter 自定义插件目录
ENV JMETER_CUSTOM_PLUGINS_FOLDER=/plugins
# JMeter 业务工作空间
ENV JMETER_WORKSPACE=/opt/workspace

# Java Runtime Environment
ARG JRE_PKG=openjdk21-jre

# 是否安装 Python 3
ARG INSTALL_PYTHON_3=false

# 包安装过程
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update bash vim tzdata ${JRE_PKG} curl tar unzip make net-tools maven \
	&& apk add --no-cache nss \
	&& if [ "$INSTALL_PYTHON_3" = "true" ]; then apk add --update --no-cache python3 py3-pip && ln -sf python3 /usr/bin/python; fi \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
	&& mkdir -p /opt \
	&& tar -zxf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	&& rm -rf /tmp/dependencies

# 配置环境变量
ENV PATH=${PATH}:${JMETER_BIN}

# 反漏洞安全补丁(更新存在漏洞的jar包)
COPY security /tmp/security/
RUN    chmod +x /tmp/security/patch.sh \
	&& cd /tmp/security \
	&& ./patch.sh \
	&& rm -rf /tmp/security

# 默认的入口程序脚本
COPY jmeter/entrypoint.sh /

# 暴露端口用于`JMeter Server`模式
EXPOSE 1099 50000

# 工作目录
WORKDIR ${JMETER_HOME}

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
