# 基础镜像
FROM alpine:3.16
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# 默认时区
ARG TIMEZONE="Asia/Shanghai"
ENV TZ ${TIMEZONE}

# JMeter 版本及下载源
ARG JMETER_VERSION="5.5"
ENV	JMETER_DOWNLOAD_URL https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz
# JMeter 应用程序目录
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_LIB	${JMETER_HOME}/lib
ENV	JMETER_EXT	${JMETER_HOME}/lib/ext
# JMeter 自定义插件目录
ENV JMETER_CUSTOM_PLUGINS_FOLDER /plugins

# 包安装过程
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update bash vim tzdata openjdk15-jre curl tar unzip make net-tools \
	&& apk add --no-cache nss \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
	&& mkdir -p /opt \
	&& tar -zxvf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	&& rm -rf /tmp/dependencies

# 将`JMeter`执行路径加入环境变量
ENV PATH ${PATH}:${JMETER_BIN}

# 默认的入口程序脚本
COPY jmeter/entrypoint.sh /

# 暴露端口用于`JMeter Server`模式
EXPOSE 1099 50000

# 工作目录
WORKDIR	${JMETER_HOME}

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
