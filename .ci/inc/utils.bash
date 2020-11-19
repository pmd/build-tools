
function pmd_ci_get_os() {
    case "$(uname)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "mac"
        ;;
        CYGWIN*|MINGW*)
            echo "windows"
        ;;
        *)
            log_error "Unknown OS: $(uname)"
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
function pmd_ci_determine_build_env() {
    local own_repo_name=$1
    if [ -z "${own_repo_name}" ]; then
        log_error "own repo name required"
        return 1
    fi

    if [[ "${GITHUB_ACTIONS}" == "true" ]]; then
        log_debug "Github Actions detected"

        PMD_CI_REPO="${GITHUB_REPOSITORY}"
        PMD_CI_IS_FORK="true"
        [ "${PMD_CI_REPO}" == "${own_repo_name}" ] && PMD_CI_IS_FORK="false"
        PMD_CI_JOB_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

        if [[ "${GITHUB_EVENT_NAME}" == "push" ]]; then
            if [[ "${GITHUB_REF}" == refs/heads/* ]]; then
                PMD_CI_BRANCH=${GITHUB_REF##refs/heads/}
                unset PMD_CI_TAG
            elif [[ "${GITHUB_REF}" == refs/tags/* ]]; then
                PMD_CI_TAG=${GITHUB_REF##refs/tags/}
                unset PMD_CI_BRANCH
            else
                log_error "Unknown branch/tag: GITHUB_REF=${GITHUB_REF}"
                return 1
            fi
            PMD_CI_PUSH_COMMIT_COMPARE=$(cat ${GITHUB_EVENT_PATH} | jq .compare)
            unset PMD_CI_PULL_REQUEST_NUMBER

        elif [[ "${GITHUB_EVENT_NAME}" == "pull_request" ]]; then
            PMD_CI_PULL_REQUEST_NUMBER=$(cat ${GITHUB_EVENT_PATH} | jq .number)
            PMD_CI_BRANCH=${GITHUB_BASE_REF}
            unset PMD_CI_TAG
            unset PMD_CI_PUSH_COMMIT_COMPARE

        else
            log_error "Unsupported event: ${GITHUB_EVENT_NAME}"
            return 1
        fi

    else
        log_error "Could not determine CI type"
        return 1
    fi

    if [ -z "${PMD_CI_PULL_REQUEST_NUMBER}" ]; then
        log_info "Push:"
    else
        log_info "Pull Request:"
    fi
    log_info "  PMD_CI_REPO=${PMD_CI_REPO}"
    log_info "  PMD_CI_JOB_URL=${PMD_CI_JOB_URL}"
    log_info "  PMD_CI_PUSH_COMMIT_COMPARE=${PMD_CI_PUSH_COMMIT_COMPARE}"
    log_info "  PMD_CI_BRANCH=${PMD_CI_BRANCH}"
    log_info "  PMD_CI_TAG=${PMD_CI_TAG}"
    log_info "  PMD_CI_PULL_REQUEST_NUMBER=${PMD_CI_PULL_REQUEST_NUMBER}"
    log_info "  PMD_CI_IS_FORK=${PMD_CI_IS_FORK}"
}

function pmd_ci_is_fork_or_pull_request() {
    if [[ "${PMD_CI_IS_FORK}" = "false" && -z "${PMD_CI_PULL_REQUEST_NUMBER}" ]]; then
        return 1
    fi

    # default: true
    return 0
}
