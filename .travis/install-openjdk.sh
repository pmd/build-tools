#
# Original sources:
# Linux: https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/jdk-11.0.5%2B10/
#        https://github.com/AdoptOpenJDK/openjdk11-upstream-binaries/releases/download/jdk-11.0.5%2B10/OpenJDK11U-x64_linux_11.0.5_10.tar.gz
#


OPENJDK_ARCHIVE=OpenJDK11U-x64_linux_11.0.5_10.tar.gz
COMPONENTS_TO_STRIP=1 # e.g. openjdk-11.0.3+7/bin/java

DOWNLOAD_URL=https://pmd-code.org/openjdk/${OPENJDK_ARCHIVE}
LOCAL_DIR=${HOME}/.cache/openjdk
TARGET_DIR=${HOME}/openjdk11

mkdir -p ${LOCAL_DIR}
mkdir -p ${TARGET_DIR}
wget --quiet --directory-prefix ${LOCAL_DIR} --timestamping --continue ${DOWNLOAD_URL}
tar --extract --file ${LOCAL_DIR}/${OPENJDK_ARCHIVE} -C ${TARGET_DIR} --strip-components=${COMPONENTS_TO_STRIP}

export JAVA_HOME=${TARGET_DIR}
export PATH=${JAVA_HOME}/bin:$PATH

java -version
