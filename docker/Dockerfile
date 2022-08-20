# 基础镜像
FROM alpine:3
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# JMeter 版本及下载源
ARG JMETER_VERSION="5.5"
ENV	JMETER_DOWNLOAD_URL https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz
# JMeter 常用目录
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_LIB	${JMETER_HOME}/lib
ENV	JMETER_EXT	${JMETER_HOME}/lib/ext
# JMeter 自定义插件目录
ENV JMETER_CUSTOM_PLUGINS_FOLDER /plugins

# 默认时区
ARG TIMEZONE="Asia/Shanghai"
ENV TZ ${TIMEZONE}

# 安装包
RUN    apk update \
	&& apk upgrade \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update openjdk8-jre tzdata bash curl vim tar unzip \
	&& apk add --no-cache nss \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} > /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz \
	&& mkdir -p /opt \
	&& tar -zxvf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	&& rm -rf /tmp/dependencies

# 将JMeter执行路径加入环境变量
ENV PATH ${PATH}:${JMETER_BIN}

# 默认的入口程序脚本
COPY docker/entrypoint.sh /

# 工作目录
WORKDIR	${JMETER_HOME}

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
