# ################################################## 业务介绍 ##################################################

#
# 演示样例
#

# ################################################## 默认参数 ##################################################

PROJECT ?= "proj_example"
JMX ?= "HelloWorld.jmx"

TARGET_THREADS  ?= "1"
TARGET_PROTOCOL ?= "https"
TARGET_HOST     ?= "example.com"
TARGET_PORT     ?= "443"
TARGET_PATH     ?= "/api"
TARGET_DATASET  ?= "testcases/${PROJECT}/dataset.txt"
TARGET_TEMP_DIR ?= "temp"

# ################################################## 无需修改 ##################################################

# JVM
JVM_ARGS ?= "-Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m"

# Testcases
TESTCASE_DIR ?= testcases
JMX_DIR       = $(TESTCASE_DIR)/jmx
PROJECT_DIR   = $(TESTCASE_DIR)/$(PROJECT)
REPORT_DIR    = $(PROJECT_DIR)/report

# ################################################## Target ##################################################

REMOTE_HOSTS = $(shell getent ahostsv4 jmeter-server | cut -d ' ' -f 1 | sort -u | awk -v ORS=:1099, '{print $1}' | sed 's/,$\//')

all: clean run report

clean:
	@rm -rf $(REPORT_DIR) $(PROJECT_DIR)/jmeter.jtl $(PROJECT_DIR)/jmeter.log

run:
	@mkdir -p $(REPORT_DIR)
	@echo "Remote Hosts: " $(REMOTE_HOSTS)
	jmeter -Dlog4j2.formatMsgNoLookups=true -Dlog_level.jmeter=DEBUG -Dserver.rmi.ssl.disable=true \
	-JTARGET_THREADS=$(TARGET_THREADS) \
	-JTARGET_PROTOCOL=$(TARGET_PROTOCOL) -JTARGET_HOST=$(TARGET_HOST) -JTARGET_PORT=$(TARGET_PORT) \
	-JTARGET_PATH=$(TARGET_PATH) \
	-JTARGET_DATASET=$(TARGET_DATASET) -JTARGET_TEMP_DIR=$(TARGET_TEMP_DIR) \
	-n -t $(JMX_DIR)/$(JMX) -l $(PROJECT_DIR)/jmeter.jtl -j $(PROJECT_DIR)/jmeter.log \
	-e -o $(REPORT_DIR) \
	-R $(REMOTE_HOSTS)

report:
	echo "==== jmeter.log ===="
	cat $(PROJECT_DIR)/jmeter.log
	echo "==== Raw Test Report ===="
	cat $(PROJECT_DIR)/jmeter.jtl
	echo "==== HTML Test Report ===="
	echo "See HTML test report in $(REPORT_DIR)/index.html"
