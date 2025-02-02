# ################################################## Task Overview ########################################################

#
# This Makefile is used to demonstrate JMeter test in standalone mode.
#

# ################################################## Default Parameters ###################################################

TESTCASE_DIR    ?= $(PWD)/testcases

PROJECT ?= proj_example
JMX     ?= HelloWorld.jmx

TARGET_THREADS  ?= 1
TARGET_PROTOCOL ?= https
TARGET_HOST     ?= example.com
TARGET_PORT     ?= 443
TARGET_PATH     ?= /api
TARGET_DATASET  ?= $(TESTCASE_DIR)/$(PROJECT)/dataset.txt

# Only needed when saving files is configured
TARGET_TEMP_DIR ?= $(TESTCASE_DIR)/$(PROJECT)/temp

# ################################################## No changes required ##################################################

# Images
IMG_JMETER         = liukunup/jmeter:$(JMETER_VERSION)
IMG_JMETER_PLUGINS = liukunup/jmeter:plugins-$(JMETER_VERSION)

# JMeter
JMETER_VERSION ?= 5.6.3
CONTAINER_NAME ?= jmeter

# JMeter Server
JS_PORT           ?= 1099
JS_RMI_LOCALPORT  ?= 50000
JS_CONTAINER_NAME ?= jmeter-server

# Mirror Server
MS_PORT           ?= 8080
MS_CONTAINER_NAME ?= mirror-server

# Server Agent
SA_PORT           ?= 4444
SA_INTERVAL       ?= 10
SA_CONTAINER_NAME ?= server-agent

# JVM
JVM_ARGS ?= "-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m"

# Testcases
JMX_DIR       = $(TESTCASE_DIR)/jmx
PROJECT_DIR   = $(TESTCASE_DIR)/$(PROJECT)
REPORT_DIR    = $(PROJECT_DIR)/report

# ################################################## Target ###############################################################

all: clean run report

clean:
	@rm -rf $(REPORT_DIR) $(TARGET_TEMP_DIR) $(PROJECT_DIR)/jmeter.jtl $(PROJECT_DIR)/jmeter.log

run:
	@mkdir -p $(REPORT_DIR) $(TARGET_TEMP_DIR)
	docker run --rm --name $(CONTAINER_NAME) -i -v $(PWD):/opt/workspace -w /opt/workspace \
      -e JVM_ARGS=$(JVM_ARGS) $(IMG_JMETER_PLUGINS) jmeter \
      -Dlog_level.jmeter=DEBUG \
      -JTARGET_THREADS=$(TARGET_THREADS) \
      -JTARGET_PROTOCOL=$(TARGET_PROTOCOL) -JTARGET_HOST=$(TARGET_HOST) -JTARGET_PORT=$(TARGET_PORT) \
      -JTARGET_PATH=$(TARGET_PATH) \
      -JTARGET_DATASET=$(TARGET_DATASET) -JTARGET_TEMP_DIR=$(TARGET_TEMP_DIR) \
      -n -t $(JMX_DIR)/$(JMX) -l $(PROJECT_DIR)/jmeter.jtl -j $(PROJECT_DIR)/jmeter.log \
      -e -o $(REPORT_DIR)

report:
	@echo "==== jmeter.log ===="
	@tail -n 10 $(PROJECT_DIR)/jmeter.log
	@echo "==== Raw Test Report ===="
	@tail -n 10 $(PROJECT_DIR)/jmeter.jtl
	@echo "==== HTML Test Report ===="
	@echo "See HTML test report in $(REPORT_DIR)/index.html"

server:
	docker run -d \
      -p $(JS_PORT):$(JS_PORT) \
      -p $(JS_RMI_LOCALPORT):$(JS_RMI_LOCALPORT) \
      --restart=unless-stopped \
      --name=$(JS_CONTAINER_NAME) \
      $(IMG_JMETER) jmeter-server \
      -Djava.rmi.server.hostname=$(shell hostname -I | awk '{print $$1}')

mirror:
	docker run -d \
      -p $(MS_PORT):$(MS_PORT) \
      --restart=unless-stopped \
      --name=$(MS_CONTAINER_NAME) \
      $(IMG_JMETER) mirror-server

customize:
	docker run -d \
      --restart=unless-stopped \
      --name=$(CONTAINER_NAME) \
      $(IMG_JMETER) customize jmeter -v

keepalive:
	docker run -d \
      -v $(PWD):/opt/workspace \
      -w /opt/workspace \
      -e SERVER_PORT=$(JS_PORT) \
      --restart=unless-stopped \
      --name=$(CONTAINER_NAME) \
      $(IMG_JMETER) keepalive

agent:
	docker run -d \
      -p $(SA_PORT):4444 \
      -e SA_INTERVAL=$(SA_INTERVAL) \
      --restart=unless-stopped \
      --name=$(SA_CONTAINER_NAME) \
      $(CONTAINER_IMAGE) server-agent
