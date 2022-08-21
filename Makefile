# ################################################## 业务介绍 ##################################################

#
# 演示样例
#

# ################################################## 默认参数 ##################################################

PROJECT ?= "proj_example"
JMX ?= "standard_fixed.jmx"

TARGET_THREADS  ?= "1"
TARGET_PROTOCOL ?= "https"
TARGET_HOST     ?= "example.com"
TARGET_PORT     ?= "443"
TARGET_PATH     ?= "/api"
TARGET_DATASET  ?= "testcases/${PROJECT}/dataset.txt"
TARGET_TEMP_DIR ?= "temp"

# ################################################## 无需修改 ##################################################

# Container
JMETER_VERSION ?= "5.5"
CONTAINER_NAME ?= "jmeter"
CONTAINER_IMAGE = "liukunup/jmeter:$(JMETER_VERSION)"

# JMeter Server
JS_PORT           ?= "1234"
JS_CONTAINER_NAME ?= "jmeter-server"

# Server Agent
SA_PORT           ?= "8888"
SA_INTERVAL       ?= "10"
SA_CONTAINER_NAME ?= "server-agent"

# JVM
JVM_ARGS ?= "-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m"

# Testcases
TESTCASE_DIR ?= testcases
JMX_DIR       = $(TESTCASE_DIR)/jmx
PROJECT_DIR   = $(TESTCASE_DIR)/$(PROJECT)
REPORT_DIR    = $(PROJECT_DIR)/report

# ################################################## Target ##################################################

all: clean run report

clean:
	@rm -rf $(REPORT_DIR) $(PROJECT_DIR)/jmeter.jtl $(PROJECT_DIR)/jmeter.log

run:
	@mkdir -p $(REPORT_DIR)
	docker run --rm --name $(CONTAINER_NAME) -i -v $(PWD):$(PWD) -w $(PWD) \
    -e JVM_ARGS=$(JVM_ARGS) $(CONTAINER_IMAGE) jmeter \
	-Dlog_level.jmeter=DEBUG \
	-JTARGET_THREADS=$(TARGET_THREADS) \
	-JTARGET_PROTOCOL=$(TARGET_PROTOCOL) -JTARGET_HOST=$(TARGET_HOST) -JTARGET_PORT=$(TARGET_PORT) \
	-JTARGET_PATH=$(TARGET_PATH) \
	-JTARGET_DATASET=$(TARGET_DATASET) -JTARGET_TEMP_DIR=$(TARGET_TEMP_DIR) \
	-n -t $(JMX_DIR)/$(JMX) -l $(PROJECT_DIR)/jmeter.jtl -j $(PROJECT_DIR)/jmeter.log \
	-e -o $(REPORT_DIR)

report:
	echo "==== jmeter.log ===="
	cat $(PROJECT_DIR)/jmeter.log
	echo "==== Raw Test Report ===="
	cat $(PROJECT_DIR)/jmeter.jtl
	echo "==== HTML Test Report ===="
	echo "See HTML test report in $(REPORT_DIR)/index.html"

server:
	docker run -d \
      -p $(JS_PORT):$(JS_PORT) \
      -e SERVER_PORT=$(JS_PORT) \
      --restart=unless-stopped \
      --name=$(JS_CONTAINER_NAME) \
      $(CONTAINER_IMAGE) jmeter-server

agent:
	docker run -d \
      -p $(SA_PORT):4444 \
      -e SA_INTERVAL=$(SA_INTERVAL) \
      --restart=unless-stopped \
      --name=$(SA_CONTAINER_NAME) \
      $(CONTAINER_IMAGE) server-agent
