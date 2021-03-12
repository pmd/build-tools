#!/usr/bin/env bash

MODULE="openjdk"
SCRIPT_INCLUDES="log.bash utils.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

#
# Downloads openjdk from AdoptOpenJDK by accessing the API.
# The API is documented at https://api.adoptopenjdk.net/swagger-ui/
#
function pmd_ci_openjdk_install_adoptopenjdk() {
    local openjdk_version=$1
    local -r jdk_os=$(pmd_ci_utils_get_os)

    if [ -z "${openjdk_version}" ]; then
        pmd_ci_log_error "OpenJDK Version is missing!"
        return 1;
    fi


    local release_type="ga"
    if [[ "${openjdk_version}" == *-ea ]]; then
        release_type="ea"
        openjdk_version=${openjdk_version%-ea}
    fi

    pmd_ci_log_info "Installing Adopt OpenJDK Version ${openjdk_version}-${release_type} (${jdk_os})"

    local components_to_strip
    case "${jdk_os}" in
        linux)
            components_to_strip=1 # e.g. jdk-11.0.9.1+1/bin/java
            ;;
        mac)
            components_to_strip=3 # e.g. jdk-11.0.9.1+1/Contents/Home/bin/java
        ;;
        windows)
            components_to_strip=1 # e.g. jdk-11.0.9.1+1/bin/java.exe
        ;;
        *)
            pmd_ci_log_error "Unknown OS: ${jdk_os}"
            return 1
        ;;
    esac

    local -r api_url="https://api.adoptopenjdk.net/v3/assets/feature_releases/${openjdk_version}/${release_type}?architecture=x64&heap_size=normal&image_type=jdk&jvm_impl=hotspot&os=${jdk_os}&page=0&page_size=1&project=jdk&sort_method=DEFAULT&sort_order=DESC&vendor=adoptopenjdk"
    pmd_ci_log_debug "api: ${api_url}"
    local -r download_url=$(curl --silent -X GET "${api_url}" \
        -H "accept: application/json" \
        | jq -r ".[0].binaries[0].package.link")
    if [[ -z "${download_url}" || "${download_url}" == "null" ]]; then
        pmd_ci_log_error "No jdk found for download: ${api_url}"
        return 1
    fi

    local -r openjdk_archive=$(basename "${download_url}")
    pmd_ci_log_debug "Archive name: ${openjdk_archive}"

    local -r cache_dir=${HOME}/.cache/openjdk
    local -r target_dir=${HOME}/openjdk${openjdk_version}

    mkdir -p "${cache_dir}"
    mkdir -p "${target_dir}"

    if [ ! -e "${cache_dir}/${openjdk_archive}" ]; then
        pmd_ci_log_info "Downloading from ${download_url} to ${cache_dir}"
        curl --location --output "${cache_dir}/${openjdk_archive}" "${download_url}"
    else
        pmd_ci_log_info "Skipped download, file ${cache_dir}/${openjdk_archive} already exists"
    fi

    pmd_ci_log_info "Extracting to ${target_dir}"

    case "${openjdk_archive}" in
        *.zip)
            7z x "${cache_dir}/${openjdk_archive}" -o"${target_dir}"
            # equivalent for components_to_strip=1
            mv "${target_dir}/"*/* "${target_dir}/"
            ;;
        *.tar.gz)
            tar --extract --file "${cache_dir}/${openjdk_archive}" -C "${target_dir}" --strip-components=${components_to_strip}
            ;;
        *)
            pmd_ci_log_error "Unknown filetype: ${openjdk_archive}"
            return 1
            ;;
    esac
}

#
# See https://www.azul.com/downloads/zulu-community/
# and https://www.azul.com/downloads/zulu-community/api/
# Supports also a free build of java7
#
function pmd_ci_openjdk_install_zuluopenjdk() {
    local -r openjdk_version=$1
    local -r jdk_os=$(pmd_ci_utils_get_os)

    if [ -z "${openjdk_version}" ]; then
        pmd_ci_log_error "OpenJDK Version is missing!"
        return 1;
    fi

    pmd_ci_log_info "Installing Zulu OpenJDK Version ${openjdk_version} (${jdk_os})"

    local zulu_os
    local components_to_strip=0
    local ext
    case "${jdk_os}" in
        linux)
            zulu_os=linux
            ext=tar.gz
            components_to_strip=1 # e.g. zulu7.42.0.51-ca-jdk7.0.285-linux_x64/bin/java
            ;;
        mac)
            zulu_os=macos
            ext=tar.gz
            components_to_strip=4 # e.g. zulu7.42.0.51-ca-jdk7.0.285-macosx_x64/zulu-7.jdk/Contents/Home/bin/java
        ;;
        windows)
            zulu_os=windows
            ext=zip
            components_to_strip=1 # zulu7.42.0.51-ca-jdk7.0.285-win_x64/bin/java.exe
        ;;
        *)
            log_error "Unknown OS: ${jdk_os}"
            return 1
        ;;
    esac

    local -r zulu_api_url="https://api.azul.com/zulu/download/community/v1.0/bundles/latest/?jdk_version=${openjdk_version}&os=${zulu_os}&arch=x86&hw_bitness=64&bundle_type=jdk&release_status=ga&ext=${ext}"
    pmd_ci_log_debug "zulu api: ${zulu_api_url}"
    local -r download_url=$(curl --silent -X GET "${zulu_api_url}" \
        -H "accept: application/json" \
        | jq -r ".url")
    if [[ -z "${download_url}" || "${download_url}" == "null" ]]; then
        pmd_ci_log_error "No jdk found for download: ${zulu_api_url}"
        return 1
    fi

    local -r openjdk_archive=$(basename "${download_url}")
    pmd_ci_log_debug "Archive name: ${openjdk_archive}"

    local -r cache_dir=${HOME}/.cache/openjdk
    local -r target_dir=${HOME}/openjdk${openjdk_version}

    mkdir -p "${cache_dir}"
    mkdir -p "${target_dir}"

    if [ ! -e "${cache_dir}/${openjdk_archive}" ]; then
        pmd_ci_log_info "Downloading from ${download_url} to ${cache_dir}"
        curl --location --output "${cache_dir}/${openjdk_archive}" "${download_url}"
    else
        pmd_ci_log_info "Skipped download, file ${cache_dir}/${openjdk_archive} already exists"
    fi

    pmd_ci_log_info "Extracting to ${target_dir}"

    case "${openjdk_archive}" in
        *.zip)
            7z x "${cache_dir}/${openjdk_archive}" -o"${target_dir}"
            # equivalent for components_to_strip=1
            mv "${target_dir}/"*/* "${target_dir}/"
            ;;
        *.tar.gz)
            tar --extract --file "${cache_dir}/${openjdk_archive}" -C "${target_dir}" --strip-components=${components_to_strip}
            ;;
        *)
            pmd_ci_log_error "Unknown filetype: ${openjdk_archive}"
            exit 1
            ;;
    esac
}

#
# Configures both JAVA_HOME and PATH
#
function pmd_ci_openjdk_setdefault() {
    local openjdk_version=$1

    if [ -z "${openjdk_version}" ]; then
        pmd_ci_log_error "OpenJDK Version is missing!"
        return 1;
    fi

    if [[ "${openjdk_version}" == *-ea ]]; then
        openjdk_version=${openjdk_version%-ea}
    fi

    local -r target_dir=${HOME}/openjdk${openjdk_version}

    pmd_ci_log_info "Using OpenJDK ${openjdk_version} in ${target_dir} as default"

    if [ ! -e "${target_dir}/bin/java" ]; then
        pmd_ci_log_error "Java executable ${target_dir}/bin/java not found!"
        return 1
    fi

    export JAVA_HOME="${target_dir}"
    export PATH="${target_dir}/bin:${PATH}"

    java -version
}
