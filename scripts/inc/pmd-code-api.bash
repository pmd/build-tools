#!/usr/bin/env bash

MODULE="pmd-code-api"
SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

PMD_CODE_SSH_USER=pmd

function pmd_ci_pmd_code_uploadFile() {
    local targetPath="$1"
    local filename="$2"

    pmd_ci_log_debug "${FUNCNAME[0]} targetPath=$targetPath filename=$filename"

    # shellcheck disable=SC2029
    # -> targetPath shall be expanded on the client side
    ssh "${PMD_CODE_SSH_USER}@pmd-code.org" "mkdir -p \"${targetPath}\"" &&
        scp "${filename}" "${PMD_CODE_SSH_USER}@pmd-code.org:${targetPath}"
    pmd_ci_log_success "Uploaded ${filename} to pmd-code.org:${targetPath}"
}

function pmd_ci_pmd_code_uploadZipAndExtract() {
    local targetPath="$1"
    local filename="$2"
    local basefilename
    basefilename="$(basename "$filename")"

    pmd_ci_log_debug "${FUNCNAME[0]} targetPath=$targetPath filename=$filename"

    # shellcheck disable=SC2029
    # -> targetPath and basefilename shall be expanded on the client side
    ssh "${PMD_CODE_SSH_USER}@pmd-code.org" "mkdir -p \"${targetPath}\"" &&
        scp "${filename}" "${PMD_CODE_SSH_USER}@pmd-code.org:${targetPath}" &&
        ssh "${PMD_CODE_SSH_USER}@pmd-code.org" "cd \"${targetPath}\" && \
            unzip -qo \"${basefilename}\" && \
            rm \"${basefilename}\""
    pmd_ci_log_success "Uploaded and extracted ${filename} to pmd-code.org:${targetPath}"
}

function pmd_ci_pmd_code_removeFolder() {
    local targetPath="$1"

    pmd_ci_log_debug "${FUNCNAME[0]} targetPath=$targetPath"

    # shellcheck disable=SC2029
    # -> targetPath shall be expanded on the client side
    ssh ${PMD_CODE_SSH_USER}@pmd-code.org "rm -rf \"${targetPath}\""
    pmd_ci_log_success "Removed remote folder: pmd-code.org:${targetPath}"
}

function pmd_ci_pmd_code_createSymlink() {
    local target="$1"
    local linkName="$2"

    pmd_ci_log_debug "${FUNCNAME[0]} target=$target linkName=$linkName"

    # shellcheck disable=SC2029
    # -> target and linkName shall be expanded on the client side
    ssh ${PMD_CODE_SSH_USER}@pmd-code.org "ln -snf \"$target\" \"$linkName\""
    pmd_ci_log_success "Symlink created: pmd-code.org:${linkName} -> pmd-code.org:${target}"
}
