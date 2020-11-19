#!/usr/bin/env bash

source $(dirname $0)/inc/logger.bash || exit 1
source $(dirname $0)/inc/utils.bash || exit 1
source $(dirname $0)/inc/secrets.bash || exit 1
source $(dirname $0)/inc/openjdk.bash || exit 1
source $(dirname $0)/inc/maven.bash || exit 1

# Exit this script immediately if a command/function exits with a non-zero status.
set -e

function build() {
    log_group_start "Install OpenJDK"
        pmd_ci_openjdk_install_adoptopenjdk 11
        pmd_ci_openjdk_setdefault 11
    log_group_end

    log_group_start "Determine project name + version"
        pmd_ci_maven_get_project_name
        local name="${RESULT}"
        pmd_ci_maven_get_project_version
        local version="${RESULT}"
    log_group_end

    echo
    log_info "======================================================================="
    log_info "Building ${name} ${version}"
    log_info "======================================================================="
    pmd_ci_determine_build_env pmd/build-tools
    echo

    if pmd_ci_is_fork_or_pull_request; then
        log_group_start "Build with mvnw"
        ./mvnw clean verify -B -V -e
        log_group_end
        exit 0
    fi

    # only builds on pmd/build-tools continue here
    log_group_start "Setup environment"
        pmd_ci_secrets_load_private_env
        pmd_ci_secrets_setup_gpg_key
        pmd_ci_maven_setup_settings
    log_group_end


    # snapshot or release - it only depends on the version (SNAPSHOT or no SNAPSHOT)
    # the build command is the same
    log_group_start "Build with mvnw"
    pmd_ci_maven_verify_version ${version}
    ./mvnw clean deploy -Psign -B -V -e
    log_group_end
}

build

exit 0
