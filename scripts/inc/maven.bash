#!/usr/bin/env bash

MODULE="maven"
SCRIPT_INCLUDES="log.bash utils.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

#
# Configures maven.
# Needed for deploy to central (both snapshots and releases)
# and for signing the artifacts.
#
function pmd_ci_maven_setup_settings() {
    pmd_ci_log_info "Setting up maven at ${HOME}/.m2/settings.xml..."
    pmd_ci_utils_fetch_ci_file "maven-settings.xml"
    local -r fullpath="$RESULT"

    mkdir -p "${HOME}/.m2"
    cp "${fullpath}" "${HOME}/.m2/settings.xml"
}

function pmd_ci_maven_display_info_banner() {
    pmd_ci_log_info "Determining build info..."
    pmd_ci_maven_get_project_name
    local name="${RESULT}"
    pmd_ci_maven_get_project_version
    local version="${RESULT}"
    pmd_ci_log_info "======================================================================="
    pmd_ci_log_info "Building ${name} ${version}"
    pmd_ci_log_info "======================================================================="
}

function pmd_ci_maven_get_project_version() {
    if [ -n "${PMD_CI_MAVEN_PROJECT_VERSION}" ]; then
        RESULT="${PMD_CI_MAVEN_PROJECT_VERSION}"
        return 0
    fi

    RESULT=$(./mvnw --batch-mode --no-transfer-progress \
        org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate \
        -Dexpression=project.version -q -DforceStdout || echo "pmd_ci_maven_get_project_version_failed")

    if [[ "$RESULT" == *pmd_ci_maven_get_project_version_failed ]]; then
        pmd_ci_log_error "$RESULT"
        return 1
    fi

    export PMD_CI_MAVEN_PROJECT_VERSION="${RESULT}"
}

function pmd_ci_maven_get_project_name() {
    RESULT=$(./mvnw --batch-mode --no-transfer-progress \
        org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate \
        -Dexpression=project.name -q -DforceStdout || echo "pmd_ci_maven_get_project_name_failed")

    if [[ "$RESULT" == *pmd_ci_maven_get_project_name_failed ]]; then
        pmd_ci_log_error "$RESULT"
        return 1
    fi
}

function pmd_ci_maven_verify_version() {
    pmd_ci_maven_get_project_version

    pmd_ci_log_debug "version=${PMD_CI_MAVEN_PROJECT_VERSION} PMD_CI_BRANCH=${PMD_CI_BRANCH} PMD_CI_TAG=${PMD_CI_TAG}"

    if [[ "${PMD_CI_MAVEN_PROJECT_VERSION}" == *-SNAPSHOT && -z "$PMD_CI_BRANCH" ]]; then
        pmd_ci_log_error "Invalid combination: snapshot version ${PMD_CI_MAVEN_PROJECT_VERSION} but no branch"
        return 1
    fi

    if [[ "${PMD_CI_MAVEN_PROJECT_VERSION}" != *-SNAPSHOT && -z "$PMD_CI_TAG" ]]; then
        pmd_ci_log_error "Invalid combination: non-snapshot version ${PMD_CI_MAVEN_PROJECT_VERSION} but no tag"
        return 1
    fi
}

function pmd_ci_maven_isSnapshotBuild() {
    pmd_ci_maven_get_project_version

    if [[ "${PMD_CI_MAVEN_PROJECT_VERSION}" == *-SNAPSHOT && "${PMD_CI_BRANCH}" != "" ]]; then
        return 0
    fi

    return 1
}

function pmd_ci_maven_isReleaseBuild() {
    pmd_ci_maven_get_project_version

    if [[ "${PMD_CI_MAVEN_PROJECT_VERSION}" != *-SNAPSHOT && "${PMD_CI_TAG}" != "" ]]; then
        return 0
    fi

    return 1
}