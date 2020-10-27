#
# Load OpenJDK by AdoptOpenJDK from https://pmd-code.org/openjdk/latest/jdk-11-linux64.tar.gz
#
# Builds are originally from AdoptOpenJDK (https://adoptopenjdk.net/)
#

# OPENJDK_VERSION e.g. "11"
OPENJDK_VERSION=$1
BASE_URL=https://pmd-code.org/openjdk/latest/jdk-${OPENJDK_VERSION}

DOWNLOAD_URL=${BASE_URL}-linux64.tar.gz
COMPONENTS_TO_STRIP=1 # e.g. openjdk-11.0.3+7/bin/java

OPENJDK_ARCHIVE=$(basename $DOWNLOAD_URL)

LOCAL_DIR=${HOME}/.cache/openjdk
TARGET_DIR=${HOME}/openjdk${OPENJDK_VERSION}

mkdir -p ${LOCAL_DIR}
mkdir -p ${TARGET_DIR}
wget --directory-prefix ${LOCAL_DIR} --timestamping --continue ${DOWNLOAD_URL}
tar --extract --file ${LOCAL_DIR}/${OPENJDK_ARCHIVE} -C ${TARGET_DIR} --strip-components=${COMPONENTS_TO_STRIP}

export JAVA_HOME=${TARGET_DIR}
export PATH=${JAVA_HOME}/bin:$PATH

java -version
