#!/bin/bash

# 打印已经配置好的环境变量
echo "JMeter library directory: $JMETER_LIB"
echo "JMeter license directory: $JMETER_LIC"

# 待解决CVE漏洞的JAR包列表
JAR_LIST="libraries.csv"

# Maven下载地址的URL前缀
MAVEN_URL_PREFIX="https://repo1.maven.org/maven2"

# 检查列表文件是否存在
if [ ! -f $JAR_LIST ]; then
  echo "The jar list file '$JAR_LIST' not found!"
  exit 1
fi

# 遍历列表文件中的每一行
while IFS= read -r line; do

  # 跳过注释行（以#开头的行）
  if [[ $line =~ ^# ]]; then
    continue
  fi

  # 使用IFS分隔符来分割每行的内容
  IFS=',' read -r -a fields <<< $line

  # 检查是否读取了正确数量的字段
  if [ "${#fields[@]}" -ne 4 ]; then
    echo "Invalid CSV line: '$line'"
    continue
  fi

  # 提取库名称、当前版本、期望版本和CVE编号
  LIB_GROUP="${fields[0]}"
  LIB_ARTIFACT="${fields[0]#*/}"
  CURRENT_VERSION="${fields[1]}"
  DESIRED_VERSION="${fields[2]}"
  CVE_ID="${fields[3]% *}" # 如果CVE编号后有额外信息，则只取到空格前的部分

  # 打印出要更新的库和版本信息
  echo "Updating library: $LIB_GROUP:$LIB_ARTIFACT from version $CURRENT_VERSION to $DESIRED_VERSION (CVE: $CVE_ID)"

  # 下载并更新
  rm -f ${JMETER_LIB}/${LIB_ARTIFACT}-${CURRENT_VERSION}.jar
  rm -rf ${JMETER_LIC}/${LIB_ARTIFACT}-${CURRENT_VERSION}.jar
  curl -L --silent ${URL_PREFIX}/${LIB_GROUP//.//}/${LIB_ARTIFACT}/${DESIRED_VERSION}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar > ${JMETER_LIB}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar
  mkdir -p ${JMETER_LIC}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar
  unzip ${JMETER_LIB}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar -d ${JMETER_LIC}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar
  rm -rf ${JMETER_LIC}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar/$(echo $LIB_GROUP | cut -d'.' -f1)

done < $JAR_LIST

echo "Library update script completed."
