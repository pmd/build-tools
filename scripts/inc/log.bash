#!/usr/bin/env bash

export PMD_CI_LOG_COL_GREEN="\e[32m"
export PMD_CI_LOG_COL_RED="\e[31m"
export PMD_CI_LOG_COL_RESET="\e[0m"
export PMD_CI_LOG_COL_YELLOW="\e[33;1m"

function pmd_ci_log_error() {
    echo -e "${PMD_CI_LOG_COL_RED}[ERROR  ] $*${PMD_CI_LOG_COL_RESET}"
    # print stack trace
    for i in "${!FUNCNAME[@]}"; do
    echo -e "${PMD_CI_LOG_COL_RED}          at ${FUNCNAME[$i]} (${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]})${PMD_CI_LOG_COL_RESET}"
    done
}

function pmd_ci_log_info() {
    echo -e "${PMD_CI_LOG_COL_YELLOW}[INFO   ] $*${PMD_CI_LOG_COL_RESET}"
}

function pmd_ci_log_success() {
    echo -e "${PMD_CI_LOG_COL_GREEN}[SUCCESS] $*${PMD_CI_LOG_COL_RESET}"
}

function pmd_ci_log_debug() {
    if [ "${PMD_CI_DEBUG}" == "true" ]; then
        echo -e "[DEBUG  ] $*"
    fi
}

function pmd_ci_log_group_start() {
    echo "::group::$*"
    pmd_ci_log_info "$@"
}

function pmd_ci_log_group_end() {
    echo "::endgroup::"
}
