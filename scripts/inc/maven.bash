#!/usr/bin/env bash

MODULE="maven"
SCRIPT_INCLUDES="log.bash utils.bash"

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

function pmd_ci_maven_get_project_version() {
    RESULT=$(./mvnw --batch-mode --no-transfer-progress \
        org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate \
        -Dexpression=project.version -q -DforceStdout || echo "pmd_ci_maven_get_project_version_failed")

    if [[ "$RESULT" == *pmd_ci_maven_get_project_version_failed ]]; then
        pmd_ci_log_error "$RESULT"
        return 1
    fi
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
    local -r version="$1"
    if [ -z "${version}" ]; then
        pmd_ci_log_error "version required"
        return 1
    fi

    pmd_ci_log_debug "version=${version} PMD_CI_BRANCH=${PMD_CI_BRANCH} PMD_CI_TAG=${PMD_CI_TAG}"

    if [[ "${version}" == *-SNAPSHOT && -z "$PMD_CI_BRANCH" ]]; then
        pmd_ci_log_error "Invalid combination: snapshot version ${version} but no branch"
        return 1
    fi

    if [[ "${version}" != *-SNAPSHOT && -z "$PMD_CI_TAG" ]]; then
        pmd_ci_log_error "Invalid combination: non-snapshot version ${version} but no tag"
        return 1
    fi
}

function fetch_ci_scripts() {
    local inc_dir
    local inc_url
    inc_dir="$(dirname "$0")/inc"
    inc_url="${PMD_CI_SCRIPTS_URL:-https://raw.githubusercontent.com/pmd/build-tools/master/scripts}/inc"

    mkdir -p "${inc_dir}"

    for f in ${SCRIPT_INCLUDES}; do
        if [ ! -e "${inc_dir}/$f" ]; then
            curl -sSL "${inc_url}/$f" > "${inc_dir}/$f"
        fi
        [ "$PMD_CI_DEBUG" = "true" ] && echo "loading ${inc_dir}/$f in ${MODULE}"
        # shellcheck source=/dev/null
        source "${inc_dir}/$f" || exit 1
    done
}

fetch_ci_scripts
