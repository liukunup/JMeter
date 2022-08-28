# ################################################## 业务介绍 ##################################################

#
# 演示样例
#

# ################################################## 默认参数 ##################################################

# 默认测试路径 无需修改
TESTCASE_DIR    ?= $(PWD)/testcases

# 项目文件夹以及JMX文件
PROJECT ?= proj_example
JMX     ?= HelloWorld.jmx

# JMX配置参数
TARGET_THREADS  ?= 1
TARGET_PROTOCOL ?= https
TARGET_HOST     ?= example.com
TARGET_PORT     ?= 443
TARGET_PATH     ?= /api
TARGET_DATASET  ?= $(TESTCASE_DIR)/$(PROJECT)/dataset.txt
TARGET_TEMP_DIR ?= $(TESTCASE_DIR)/$(PROJECT)/temp

# ################################################## 无需修改 ##################################################

# JVM
JVM_ARGS ?= -Xmn256m -Xms512m -Xmx1g -XX:MaxMetaspaceSize=256m

# JMeter
JMX_DIR     = $(TESTCASE_DIR)/jmx
PROJECT_DIR = $(TESTCASE_DIR)/$(PROJECT)
REPORT_DIR  = $(PROJECT_DIR)/report

# Distribution JMeter Server Port
SERVER_PORT ?= 1099

# ################################################## Target ##################################################

# JMeter Server的Pod IP列表
REMOTE_HOSTS = $(shell getent ahostsv4 jmeter-server | cut -d ' ' -f 1 | sort -u \
                     | awk -v ORS=':$(SERVER_PORT),' '{print $1}' | sed 's/\(.*\),$\/\1/')

all: clean run report

clean:
	@rm -rf $(REPORT_DIR) $(TARGET_TEMP_DIR) $(PROJECT_DIR)/jmeter.jtl $(PROJECT_DIR)/jmeter.log

run:
	@mkdir -p $(REPORT_DIR) $(TARGET_TEMP_DIR)
	@echo "REMOTE HOSTS: $(REMOTE_HOSTS)"
	jmeter -Dlog4j2.formatMsgNoLookups=true -Dlog_level.jmeter=DEBUG -Dserver.rmi.ssl.disable=true \
	-GTARGET_THREADS=$(TARGET_THREADS) \
	-GTARGET_PROTOCOL=$(TARGET_PROTOCOL) -GTARGET_HOST=$(TARGET_HOST) -GTARGET_PORT=$(TARGET_PORT) \
	-GTARGET_PATH=$(TARGET_PATH) \
	-GTARGET_DATASET=$(TARGET_DATASET) -GTARGET_TEMP_DIR=$(TARGET_TEMP_DIR) \
	-n -t $(JMX_DIR)/$(JMX) -l $(PROJECT_DIR)/jmeter.jtl -j $(PROJECT_DIR)/jmeter.log \
	-e -o $(REPORT_DIR) \
	-R $(REMOTE_HOSTS)

report:
	@echo "==== jmeter.log ===="
	@tail -n 10 $(PROJECT_DIR)/jmeter.log
	@echo "==== Raw Test Report ===="
	@tail -n 10 $(PROJECT_DIR)/jmeter.jtl
	@echo "==== HTML Test Report ===="
	@echo "See HTML test report in $(REPORT_DIR)/index.html"
