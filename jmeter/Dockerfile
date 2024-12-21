# 基础镜像
FROM alpine:3.21
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# 默认时区
ARG TIMEZONE="Asia/Shanghai"
ENV TZ ${TIMEZONE}

# JMeter 版本及下载源
ARG JMETER_VERSION="5.6.3"
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
	&& tar -zxf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
	&& rm -rf /tmp/dependencies

# 配置环境变量
ENV PATH ${PATH}:${JMETER_BIN}

# 反漏洞安全补丁(适用于`JMeter-5.5`版本)
ENV	JMETER_LIC ${JMETER_HOME}/licenses
RUN    echo "add security patch" \
    && rm -f ${JMETER_LIB}/tika-core-1.28.3.jar \
    && rm -rf ${JMETER_LIC}/tika-core-1.28.3.jar \
    && curl -L --silent https://repo1.maven.org/maven2/org/apache/tika/tika-core/1.28.4/tika-core-1.28.4.jar > ${JMETER_LIB}/tika-core-1.28.4.jar \
    && mkdir -p ${JMETER_LIC}/tika-core-1.28.4.jar \
    && unzip ${JMETER_LIB}/tika-core-1.28.4.jar -d ${JMETER_LIC}/tika-core-1.28.4.jar \
    && rm -rf ${JMETER_LIC}/tika-core-1.28.4.jar/org \
    && rm -f ${JMETER_LIB}/tika-parsers-1.28.3.jar \
    && rm -rf ${JMETER_LIC}/tika-parsers-1.28.3.jar \
    && curl -L --silent https://repo1.maven.org/maven2/org/apache/tika/tika-parsers/1.28.4/tika-parsers-1.28.4.jar > ${JMETER_LIB}/tika-parsers-1.28.4.jar \
    && mkdir -p ${JMETER_LIC}/tika-parsers-1.28.4.jar \
    && unzip ${JMETER_LIB}/tika-parsers-1.28.4.jar -d ${JMETER_LIC}/tika-parsers-1.28.4.jar \
    && rm -rf ${JMETER_LIC}/tika-parsers-1.28.4.jar/org \
    && rm -rf ${JMETER_LIC}/tika-parsers-1.28.4.jar/com \
    && rm -f ${JMETER_LIB}/jsoup-1.15.1.jar \
    && rm -rf ${JMETER_LIC}/jsoup-1.15.1.jar \
    && curl -L --silent https://repo1.maven.org/maven2/org/jsoup/jsoup/1.15.3/jsoup-1.15.3.jar > ${JMETER_LIB}/jsoup-1.15.3.jar \
    && mkdir -p ${JMETER_LIC}/jsoup-1.15.3.jar \
    && unzip ${JMETER_LIB}/jsoup-1.15.3.jar -d ${JMETER_LIC}/jsoup-1.15.3.jar \
    && rm -rf ${JMETER_LIC}/jsoup-1.15.3.jar/org

# 默认的入口程序脚本
COPY jmeter/entrypoint.sh /

# 暴露端口用于`JMeter Server`模式
EXPOSE 1099 50000

# 工作目录
WORKDIR	${JMETER_HOME}

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
