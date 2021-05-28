#!/usr/bin/env bash

#
# This script checks, whether all needed commands are available
# and are in the correct version.
#

set -e

SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

function main() {
    check_environment
}

function check_environment() {
    FAILED_CHECKS=""

    # every OS:
    check "curl" "curl --version" "curl"
    check "jq" "jq --version" "jq"
    check "locale" "echo $(locale|grep ^LANG=)" "en_US.UTF-8"

    case "$(uname)" in
        Linux*)
            check "ruby" "ruby --version" "ruby 2.7"
            check "gpg" "gpg --version" "gpg (GnuPG) 2."
            check "printenv" "printenv --version" "printenv (GNU coreutils)"
            check "rsync" "rsync --version" "version"
            check "ssh" "ssh -V" "OpenSSH"
            check "git" "git --version" "git version"
            check "mvn" "mvn --version" "Apache Maven"
            check "unzip" "unzip -v" "UnZip"
            check "zip" "zip --version" "This is Zip"
            #check "7z" "7z" "7-Zip"
            ;;
        Darwin*)
            ;;
        CYGWIN*|MINGW*|MSYS_NT*)
            check "7z" "7z" "7-Zip"
            ;;
        *)
            pmd_ci_log_error "Unknown OS: $(uname)"
            exit 1
        ;;
    esac
    
    if [ -n "${FAILED_CHECKS}" ]; then
        pmd_ci_log_error "Result: failed_checks: ${FAILED_CHECKS}"
        exit 1
    else
        pmd_ci_log_success "No problems detected."
        exit 0
    fi
}

function check() {
    local cmd
    local version_cmd
    local version_string
    local version_full
    local version

    cmd=$1
    version_cmd=$2
    version_string=$3

    echo -n "Checking ${cmd}..."

    if hash "$cmd" 2>/dev/null; then
      version_full=$(${version_cmd} 2>&1)
      version=$(echo "${version_full}" | grep "${version_string}" | head -1 2>&1)
      if [ -n "${version}" ]; then
          echo -e "${PMD_CI_LOG_COL_GREEN}OK${PMD_CI_LOG_COL_RESET}"
          echo "    ${version}"
      else
          echo -e "${PMD_CI_LOG_COL_RED}wrong version${PMD_CI_LOG_COL_RESET}. Expected: ${version_string}"
          echo "    ${version_full}"
          FAILED_CHECKS="${FAILED_CHECKS} ${cmd}"
      fi
    else
      echo -e "${PMD_CI_LOG_COL_RED}not found!${PMD_CI_LOG_COL_RESET}"
      FAILED_CHECKS="${FAILED_CHECKS} ${cmd}"
    fi
}

main
