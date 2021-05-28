#!/usr/bin/env bash

MODULE="utils"
SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

function pmd_ci_utils_get_os() {
    case "$(uname)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "mac"
        ;;
        CYGWIN*|MINGW*|MSYS_NT*)
            echo "windows"
        ;;
        *)
            pmd_ci_log_error "Unknown OS: $(uname)"
            return 1
        ;;
    esac
}

#
# Determines common build parameters from
# available environment variables:
#
# * PMD_CI_REPO, e.g. pmd/pmd
#   The repo, on which this build is running
# * PMD_CI_JOB_URL, e.g. https://github.com/pmd/pmd/actions/runs/4711
#   The url to the build job log etc.
# * PMD_CI_PUSH_COMMIT_COMPARE, e.g. https://github.com/pmd/pmd/compare/1234567890123...1234567890123
#   only present for pushes
# * PMD_CI_TAG, e.g. pmd_releases/1.2.3
#   may only be present for pushes. If present, then PMD_CI_BRANCH is unset
# * PMD_CI_BRANCH, e.g. master
#   for pushes, that's the target branch. If present, then PMD_CI_TAG is unset
#   for pull requests, that's the base branch
# * PMD_CI_PULL_REQUEST_NUMBER
#   only present for pull requests
# * PMD_CI_IS_FORK=true/false
function pmd_ci_utils_determine_build_env() {
    local own_repo_name=$1
    if [ -z "${own_repo_name}" ]; then
        pmd_ci_log_error "own repo name required, e.g. pmd/pmd"
        return 1
    fi

    if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
        pmd_ci_log_debug "Github Actions detected"

        PMD_CI_REPO="${GITHUB_REPOSITORY}"
        PMD_CI_IS_FORK="true"
        [ "${PMD_CI_REPO}" == "${own_repo_name}" ] && PMD_CI_IS_FORK="false"
        PMD_CI_JOB_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
        GITHUB_BASE_URL="https://api.github.com/repos/${own_repo_name}"

        case "${GITHUB_EVENT_NAME}" in
            push | workflow_dispatch | schedule)
                if [[ "${GITHUB_REF}" == refs/heads/* ]]; then
                    PMD_CI_BRANCH=${GITHUB_REF##refs/heads/}
                    unset PMD_CI_TAG
                elif [[ "${GITHUB_REF}" == refs/tags/* ]]; then
                    PMD_CI_TAG=${GITHUB_REF##refs/tags/}
                    unset PMD_CI_BRANCH
                else
                    pmd_ci_log_error "Unknown branch/tag: GITHUB_REF=${GITHUB_REF}"
                    return 1
                fi
                PMD_CI_PUSH_COMMIT_COMPARE=$(jq -r ".compare" "${GITHUB_EVENT_PATH}")
                unset PMD_CI_PULL_REQUEST_NUMBER
                ;;
            pull_request)
                PMD_CI_PULL_REQUEST_NUMBER=$(jq -r ".number" "${GITHUB_EVENT_PATH}")
                PMD_CI_BRANCH=${GITHUB_BASE_REF}
                unset PMD_CI_TAG
                unset PMD_CI_PUSH_COMMIT_COMPARE
                ;;
            *)
                pmd_ci_log_error "Unsupported event: ${GITHUB_EVENT_NAME}"
                return 1
                ;;
        esac

    else
        pmd_ci_log_error "Could not determine CI type"
        return 1
    fi

    if [ -z "${PMD_CI_PULL_REQUEST_NUMBER}" ]; then
        pmd_ci_log_info "Push:"
    else
        pmd_ci_log_info "Pull Request:"
    fi
    pmd_ci_log_info "  GITHUB_EVENT_NAME=${GITHUB_EVENT_NAME}"
    pmd_ci_log_info "  PMD_CI_REPO=${PMD_CI_REPO}"
    pmd_ci_log_info "  PMD_CI_JOB_URL=${PMD_CI_JOB_URL}"
    pmd_ci_log_info "  PMD_CI_PUSH_COMMIT_COMPARE=${PMD_CI_PUSH_COMMIT_COMPARE}"
    pmd_ci_log_info "  PMD_CI_BRANCH=${PMD_CI_BRANCH}"
    pmd_ci_log_info "  PMD_CI_TAG=${PMD_CI_TAG}"
    pmd_ci_log_info "  PMD_CI_PULL_REQUEST_NUMBER=${PMD_CI_PULL_REQUEST_NUMBER}"
    pmd_ci_log_info "  PMD_CI_IS_FORK=${PMD_CI_IS_FORK}"
    pmd_ci_log_info "  GITHUB_BASE_URL=${GITHUB_BASE_URL}"

    # make sure, that these global vars are available for sub processes (like Danger)
    export PMD_CI_REPO
    export PMD_CI_JOB_URL
    export PMD_CI_PUSH_COMMIT_COMPARE
    export PMD_CI_BRANCH
    export PMD_CI_TAG
    export PMD_CI_PULL_REQUEST_NUMBER
    export PMD_CI_IS_FORK
    export GITHUB_BASE_URL
}

function pmd_ci_utils_is_fork_or_pull_request() {
    if [[ "${PMD_CI_IS_FORK}" = "false" && -z "${PMD_CI_PULL_REQUEST_NUMBER}" ]]; then
        return 1
    fi

    # default: true
    return 0
}

function pmd_ci_utils_fetch_ci_file() {
    local -r file="$1"
    local -r files_url="${PMD_CI_SCRIPTS_URL:-https://raw.githubusercontent.com/pmd/build-tools/master/scripts}/files"
    local files_dir
    files_dir="$(dirname "$0")/files"
    files_dir="$(realpath "$files_dir")"

    mkdir -p "${files_dir}"
    if [ ! -e "${files_dir}/${file}" ]; then
        pmd_ci_log_info "Fetching ${files_url}/${file} to ${files_dir}"
        curl -sSL "${files_url}/${file}" > "${files_dir}/${file}"
    else
        pmd_ci_log_info "Using existing ${files_dir}/${file}"
    fi

    RESULT="${files_dir}/${file}"
}
