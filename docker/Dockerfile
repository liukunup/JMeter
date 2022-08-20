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

# JMeter Manager
ENV JMETER_PLUGINS_MANAGER_URL https://jmeter-plugins.org/get/
# jp@gc - Custom Thread Groups
ENV PLUGIN_JPGC_CASUTG_VERSION 2.10
ENV PLUGIN_JPGC_CASUTG_URL https://jmeter-plugins.org/files/packages/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip
# jp@gc - PerfMon
ENV PLUGIN_JPGC_PERFMON_VERSION 2.1
ENV PLUGIN_JPGC_PERFMON_URL https://jmeter-plugins.org/files/packages/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip

# Server Agent 版本及下载源
ARG SERVER_AGENT_VERSION="2.2.3"
ENV SERVER_AGENT_URL https://github.com/undera/perfmon-agent/releases/download/${SERVER_AGENT_VERSION}/ServerAgent-${SERVER_AGENT_VERSION}.zip
# Server Agent 目录
ENV SERVER_AGENT_HOME /opt/ServerAgent

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
    && curl -L --silent ${PLUGIN_JPGC_CASUTG_URL} > /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip \
    && curl -L --silent ${PLUGIN_JPGC_PERFMON_URL} > /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip \
	&& mkdir -p /opt \
	&& tar -zxvf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt \
    && unzip /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip -d ${JMETER_HOME} \
    && unzip /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip -d ${JMETER_HOME} \
    && rm ${JMETER_EXT}/jmeter-plugins-manager-*.jar \
    && curl -L --silent ${JMETER_PLUGINS_MANAGER_URL} > ${JMETER_EXT}/jmeter-plugins-manager-latest.jar \
	&& curl -L --silent ${SERVER_AGENT_URL} > /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip \
	&& mkdir -p ${SERVER_AGENT_HOME}  \
    && unzip /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip -d /tmp/dependencies/ \
    && mv /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}/* ${SERVER_AGENT_HOME}/ \
	&& chmod +x ${SERVER_AGENT_HOME}/*.sh \
	&& rm -rf /tmp/dependencies

# 将 JMeter / Server Agent 执行路径加入环境变量
ENV PATH ${PATH}:${JMETER_BIN}:${SERVER_AGENT_HOME}

# 默认的入口程序脚本
COPY docker/entrypoint.sh /

# 端口暴露
ENV SERVER_AGENT_PORT 4444
EXPOSE ${SERVER_AGENT_PORT}

# 工作目录
WORKDIR	${JMETER_HOME}

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
