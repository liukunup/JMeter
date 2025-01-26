ARG JMETER_VERSION=5.6.3
FROM liukunup/jmeter:${JMETER_VERSION}

LABEL LIUKUN="liukunup@outlook.com"

# JMeter
ARG JMETER_HOME=/opt/apache-jmeter-${JMETER_VERSION}

# JMeter Manager
ARG JMETER_PLUGINS_MANAGER_URL=https://jmeter-plugins.org/get/
# jp@gc - Custom Thread Groups
ARG PLUGIN_JPGC_CASUTG_VERSION=2.10
ARG PLUGIN_JPGC_CASUTG_URL=https://jmeter-plugins.org/files/packages/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip
# jp@gc - PerfMon
ARG PLUGIN_JPGC_PERFMON_VERSION=2.1
ARG PLUGIN_JPGC_PERFMON_URL=https://jmeter-plugins.org/files/packages/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip
# InfluxDB v2.0 Listener
ARG PLUGIN_INFLUXDB2_LISTENER_VERSION=2.8
ARG PLUGIN_INFLUXDB2_LISTENER_URL=https://github.com/mderevyankoaqa/jmeter-influxdb2-listener-plugin/releases/download/v${PLUGIN_INFLUXDB2_LISTENER_VERSION}/jmeter-plugins-influxdb2-listener-${PLUGIN_INFLUXDB2_LISTENER_VERSION}.jar
# MySQL Connector-J
ARG DRIVER_MYSQL_CONNECTOR_J_VERSION=9.1.0
ARG DRIVER_MYSQL_CONNECTOR_J_URL=https://cdn.mysql.com/Downloads/Connector-J/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip
# WebSocket Samplers
ARG DRIVER_WEBSOCKET_VERSION=1.2.10
ARG DRIVER_WEBSOCKET_URL=https://jmeter-plugins.org/files/packages/websocket-samplers-${DRIVER_WEBSOCKET_VERSION}.zip

# Server Agent
ARG SERVER_AGENT_VERSION=2.2.3
ARG SERVER_AGENT_URL=https://github.com/undera/perfmon-agent/releases/download/${SERVER_AGENT_VERSION}/ServerAgent-${SERVER_AGENT_VERSION}.zip
ENV SERVER_AGENT_HOME=/opt/ServerAgent

# Entrypoint
COPY jmeter-with-plugins/entrypoint.sh /

# Install plugins and drivers
RUN    mkdir -p /tmp/dependencies \
    && curl -L --silent ${PLUGIN_JPGC_CASUTG_URL} > /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip \
    && unzip /tmp/dependencies/jpgc-casutg-${PLUGIN_JPGC_CASUTG_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${PLUGIN_JPGC_PERFMON_URL} > /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip \
    && unzip /tmp/dependencies/jpgc-perfmon-${PLUGIN_JPGC_PERFMON_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${PLUGIN_INFLUXDB2_LISTENER_URL} > ${JMETER_EXT}/jmeter-plugins-influxdb2-listener-${PLUGIN_INFLUXDB2_LISTENER_VERSION}.jar \
    && curl -L --silent ${DRIVER_MYSQL_CONNECTOR_J_URL} > /tmp/dependencies/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip \
    && unzip /tmp/dependencies/mysql-connector-j-${DRIVER_MYSQL_CONNECTOR_J_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${DRIVER_WEBSOCKET_URL} > /tmp/dependencies/websocket-samplers-${DRIVER_WEBSOCKET_VERSION}.zip \
    && unzip /tmp/dependencies/websocket-samplers-${DRIVER_WEBSOCKET_VERSION}.zip -d ${JMETER_HOME} \
    && curl -L --silent ${JMETER_PLUGINS_MANAGER_URL} > ${JMETER_EXT}/jmeter-plugins-manager-latest.jar \
    && curl -L --silent ${SERVER_AGENT_URL} > /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip \
    && mkdir -p ${SERVER_AGENT_HOME}  \
    && unzip /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}.zip -d /tmp/dependencies/ \
    && mv /tmp/dependencies/ServerAgent-${SERVER_AGENT_VERSION}/* ${SERVER_AGENT_HOME}/ \
    && chmod +x ${SERVER_AGENT_HOME}/*.sh \
    && chmod +x /entrypoint.sh \
    && rm -rf /tmp/dependencies

# Add `Server Agent` execution path to environment variables
ENV PATH=${PATH}:${SERVER_AGENT_HOME}

# Expose ports for `JMeter Server` & `Server Agent`
EXPOSE 1099 4444

ENTRYPOINT ["/entrypoint.sh"]
