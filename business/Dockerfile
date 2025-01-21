# 基础镜像版本
ARG JMETER_VERSION=5.6.3
# 基础镜像
FROM liukunup/jmeter:${JMETER_VERSION}
# 作者信息
LABEL LIUKUN="liukunup@outlook.com"

# 工作空间
ENV	JMETER_WORKSPACE=/opt/workspace

# 工作目录
WORKDIR	${JMETER_WORKSPACE}

# 拷贝JMX以及待测数据
COPY testcases testcases

# 拷贝Makefile脚本
COPY business/Makefile ./
