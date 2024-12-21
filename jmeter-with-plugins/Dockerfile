# 基础镜像版本
ARG JMETER_VERSION="5.6.3"
# 基础镜像
FROM liukunup/jmeter:${JMETER_VERSION}
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# JMeter 应用程序目录
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}

# JMeter Manager
ENV JMETER_PLUGINS_MANAGER_VERSION 1.10
ENV JMETER_PLUGINS_MANAGER_URL https://repo1.maven.org/maven2/kg/apc/jmeter-plugins-manager/${JMETER_PLUGINS_MANAGER_VERSION}/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar
# jp@gc - Custom Thread Groups
ENV PLUGIN_JPGC_CASUTG_VERSION 2.10
ENV PLUGIN_JPGC_CASUTG_URL https://jmeter-plugins.org/files/packages/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip
# jp@gc - PerfMon
ENV PLUGIN_JPGC_PERFMON_VERSION 2.1
ENV PLUGIN_JPGC_PERFMON_URL https://jmeter-plugins.org/files/packages/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip
# InfluxDB v2.0 Listener
ENV PLUGIN_INFLUXDB2_LISTENER_VERSION 2.8
ENV PLUGIN_INFLUXDB2_LISTENER_URL https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin/releases/download/v${PLUGIN_INFLUXDB2_LISTENER_VERSION}/jmeter-plugins-influxdb2-listener-${PLUGIN_INFLUXDB2_LISTENER_VERSION}.jar
# Driver MySQL Connector-J for JDBC
ENV DRIVER_MYSQL_CONNECTOR_J_VERSION 9.1.0
ENV DRIVER_MYSQL_CONNECTOR_J_URL https://cdn.mysql.com/Downloads/Connector-J/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip

# Server Agent 版本及下载源
ARG SERVER_AGENT_VERSION="2.2.3"
ENV SERVER_AGENT_URL https://github.com/undera/perfmon-agent/releases/download/${SERVER_AGENT_VERSION}/ServerAgent-${SERVER_AGENT_VERSION}.zip
# Server Agent 目录
ENV SERVER_AGENT_HOME /opt/ServerAgent

# 包安装过程
RUN    mkdir -p /tmp/dependencies \
    && curl -L --silent ${PLUGIN_JPGC_CASUTG_URL} > /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip \
    && unzip /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${PLUGIN_JPGC_PERFMON_URL} > /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip \
    && unzip /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${PLUGIN_INFLUXDB2_LISTENER_URL} > ${JMETER_EXT}/jmeter-plugins-influxdb2-listener-${PLUGIN_INFLUXDB2_LISTENER_VERSION}.jar \
    && curl -L --silent ${DRIVER_MYSQL_CONNECTOR_J_URL} > /tmp/dependencies/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip \
    && unzip /tmp/dependencies/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip -d ${JMETER_EXT} \
    && rm ${JMETER_EXT}/jmeter-plugins-manager-*.jar \
    && curl -L --silent ${JMETER_PLUGINS_MANAGER_URL} > ${JMETER_EXT}/jmeter-plugins-manager-${JMETER_PLUGINS_MANAGER_VERSION}.jar \
	&& curl -L --silent ${SERVER_AGENT_URL} > /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip \
	&& mkdir -p ${SERVER_AGENT_HOME}  \
    && unzip /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip -d /tmp/dependencies/ \
    && mv /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}/* ${SERVER_AGENT_HOME}/ \
	&& chmod +x ${SERVER_AGENT_HOME}/*.sh \
	&& rm -rf /tmp/dependencies

# 将`Server Agent`执行路径加入环境变量
ENV PATH ${PATH}:${SERVER_AGENT_HOME}

# 默认的入口程序脚本
COPY jmeter-with-plugins/entrypoint.sh /

# 端口暴露
EXPOSE 4444

# 默认入口程序
ENTRYPOINT ["/entrypoint.sh"]
