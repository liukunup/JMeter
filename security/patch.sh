#!/bin/bash

# Enhance robustness
set -ue
set -o pipefail

# Print configured environment variables
echo "JMeter library directory: $JMETER_LIB"
echo "JMeter license directory: $JMETER_LIC"

# List of JAR packages with CVE vulnerabilities to be resolved
JAR_LIST="libraries.csv"

# URL prefix for Maven download
URL_PREFIX="https://repo1.maven.org/maven2"

# Check if the list file exists
if [ ! -f $JAR_LIST ]; then
  echo "The jar list file '$JAR_LIST' not found!"
  exit 1
fi

# Iterate through each line in the list file
while IFS= read -r line; do

  # Skip comment lines (lines starting with #)
  if [[ $line =~ ^# ]]; then
    continue
  fi

  # Use IFS delimiter to split the content of each line
  IFS=',' read -r -a fields <<< $line

  # Check if the correct number of fields were read
  if [ "${#fields[@]}" -ne 4 ]; then
    echo "Invalid CSV line: '$line'"
    continue
  fi

  # Extract library name, current version, desired version, and CVE ID
  LIB_GROUP="${fields[0]%/*}"
  LIB_ARTIFACT="${fields[0]#*/}"
  CURRENT_VERSION="${fields[1]}"
  DESIRED_VERSION="${fields[2]}"
  CVE_ID="${fields[3]% *}" # If there is extra information after the CVE ID, only take the part before the space

  # Print the library and version information to be updated
  echo "Updating library: $LIB_GROUP:$LIB_ARTIFACT from version $CURRENT_VERSION to $DESIRED_VERSION ($CVE_ID)"

  # Skip non-existent JAR packages
  if [ ! -f ${JMETER_LIB}/${LIB_ARTIFACT}-${CURRENT_VERSION}.jar ]; then
    echo "Skip ${JMETER_LIB}/${LIB_ARTIFACT}-${CURRENT_VERSION}.jar"
    continue
  fi

  # Download and update
  set -x
  rm -f ${JMETER_LIB}/${LIB_ARTIFACT}-${CURRENT_VERSION}.jar
  rm -rf ${JMETER_LIC}/${LIB_GROUP}/${LIB_ARTIFACT}-${CURRENT_VERSION}
  curl -L --silent ${URL_PREFIX}/${LIB_GROUP//.//}/${LIB_ARTIFACT}/${DESIRED_VERSION}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar > ${JMETER_LIB}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar
  mkdir -p ${JMETER_LIC}/${LIB_GROUP}/${LIB_ARTIFACT}-${DESIRED_VERSION}
  unzip ${JMETER_LIB}/${LIB_ARTIFACT}-${DESIRED_VERSION}.jar -d ${JMETER_LIC}/${LIB_GROUP}/${LIB_ARTIFACT}-${DESIRED_VERSION}
  rm -rf ${JMETER_LIC}/${LIB_ARTIFACT}-${DESIRED_VERSION}/$(echo $LIB_GROUP | cut -d'.' -f1)
  set +x

done < $JAR_LIST

echo "Library update script completed."
