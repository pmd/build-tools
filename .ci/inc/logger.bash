COL_GREEN="\e[32m"
COL_RED="\e[31m"
COL_RESET="\e[0m"
COL_YELLOW="\e[33;1m"

function log_error() {
    echo -e "${COL_RED}[ERROR  ] $*${COL_RESET}"
    # print stack trace
    for i in ${!FUNCNAME[@]}; do
    echo -e "${COL_RED}          at ${FUNCNAME[$i]} (${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]})${COL_RESET}"
    done
}

function log_info() {
    echo -e "${COL_YELLOW}[INFO   ] $*${COL_RESET}"
}

function log_success() {
    echo -e "${COL_GREEN}[SUCCESS] $*${COL_RESET}"
}

function log_debug() {
    if [ "${PMD_CI_DEBUG}" == "true" ]; then
        echo -e "[DEBUG  ] $*"
    fi
}

function log_group_start() {
    echo "::group::$*"
    log_info $*
}

function log_group_end() {
    echo "::endgroup::"
}
