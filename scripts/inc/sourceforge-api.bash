#!/usr/bin/env bash

MODULE="sourceforge-api"
SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

#
# The functions here require the following environment variables:
# PMD_SF_USER
# PMD_SF_APIKEY
# PMD_SF_BEARER_TOKEN
#

#
# Uploads the release notes to sourceforge files as "ReadMe.md".
#
# Note: this function always succeeds, even if the upload fails.
# In that case, just a error logging is provided.
#
function pmd_ci_sourceforge_uploadReleaseNotes() {
    local basePath="$1"
    local releaseNotes="$2"

    pmd_ci_log_debug "${FUNCNAME[0]} basePath=$basePath"
    local targetUrl="https://sourceforge.net/projects/pmd/files/${basePath}"

    (
        # This handler is called if any command fails
        function release_notes_fail() {
            pmd_ci_log_error "Error while uploading release notes as ReadMe.md to sourceforge!"
            pmd_ci_log_error "Please upload manually: ${targetUrl}"
            cleanup_temp_dir
            exit 0 # exit from subshell successfully
        }

        function cleanup_temp_dir() {
            pmd_ci_log_debug "Cleanup tempdir $releaseNotesTempDir"
            rm -rf "${releaseNotesTempDir}"
        }

        # exit subshell after trap
        set -e
        trap release_notes_fail ERR

        local releaseNotesTempDir
        releaseNotesTempDir=$(mktemp -d)
        pmd_ci_log_debug "Tempdir: $releaseNotesTempDir"
        mkdir -p "${releaseNotesTempDir}/${basePath}"
        echo "$releaseNotes" > "${releaseNotesTempDir}/${basePath}/ReadMe.md"

        pmd_ci_log_info "Uploading release notes to sourceforge at $basePath"
        rsync -rltvz \
            "${releaseNotesTempDir}/" \
            "${PMD_SF_USER}@web.sourceforge.net:/home/frs/project/pmd/"

        pmd_ci_log_success "Successfully uploaded release notes as ReadMe.md to sourceforge: ${targetUrl}"

        cleanup_temp_dir
    )
}

#
# Uploads the given file to sourceforge.
#
# Note: This function always succeeds, even if the upload fails.
# In that case, just a error logging is provided.
#
function pmd_ci_sourceforge_uploadFile() {
    local basePath="$1"
    local filename="$2"

    pmd_ci_log_debug "${FUNCNAME[0]} basePath=$basePath filename=$filename"
    local targetUrl="https://sourceforge.net/projects/pmd/files/${basePath}"

    (
        # This handler is called if any command fails
        function upload_failed() {
            pmd_ci_log_error "Error while uploading ${filename} to sourceforge!"
            pmd_ci_log_error "Please upload manually: ${targetUrl}"
            exit 0 # exit from subshell successfully
        }

        # exit subshell after trap
        set -e
        trap upload_failed ERR

        pmd_ci_log_info "Uploading $filename to sourceforge..."
        rsync -avh "${filename}" "${PMD_SF_USER}@web.sourceforge.net:/home/frs/project/pmd/${basePath}/"
        pmd_ci_log_success "Successfully uploaded ${filename} to sourceforge: ${targetUrl}"
    )
}

#
# Select the given version as the new default download.
#
# https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/
# https://sourceforge.net/projects/pmd/best_release.json
#
# Note: This function always succeeds, even if the request fails.
# In that case, just a error logging is provided.
#
function pmd_ci_sourceforge_selectDefault() {
    local pmdVersion="$1"

    pmd_ci_log_debug "${FUNCNAME[0]} pmdVersion=$pmdVersion"
    local targetUrl="https://sourceforge.net/projects/pmd/files/pmd/${pmdVersion}"

    (
        # This handler is called if any command fails
        function request_failed() {
            pmd_ci_log_error "Error while selecting ${pmdVersion} as new default download on sourceforge!"
            pmd_ci_log_error "Please do it manually: ${targetUrl}"
            exit 0 # exit from subshell successfully
        }

        # exit subshell after trap
        set -e
        trap request_failed ERR

        pmd_ci_log_info "Selecting $pmdVersion as new default on sourceforge..."
        local response
        response=$(curl -s -H "Accept: application/json" \
            -X PUT \
            -d "api_key=${PMD_SF_APIKEY}" \
            -d "default=windows&default=mac&default=linux&default=bsd&default=solaris&default=others" \
            "https://sourceforge.net/projects/pmd/files/pmd/${pmdVersion}/pmd-bin-${pmdVersion}.zip")
        pmd_ci_log_debug " -> response: $response"
        response=$(echo "$response" | jq -e ".result")
        pmd_ci_log_success "Successfully selected $pmdVersion as new default on sourceforge: ${targetUrl}"
    )
}

#
# Rsyncs the complete documentation to sourceforge.
#
# Note: This function always succeeds, even if the upload fails.
# In that case, just a error logging is provided.
#
function pmd_ci_sourceforge_rsyncSnapshotDocumentation() {
    local pmdVersion="$1"
    local targetPath="$2"

    pmd_ci_log_debug "${FUNCNAME[0]} pmdVersion=$pmdVersion targetPath=$targetPath"
    local targetUrl="https://pmd.sourceforge.io/${targetPath}/"

    (
        # This handler is called if any command fails
        function upload_failed() {
            pmd_ci_log_error "Couldn't upload the documentation. It won't be current on ${targetUrl}"
            exit 0 # exit from subshell successfully
        }

        # exit subshell after trap
        set -e
        trap upload_failed ERR

        pmd_ci_log_info "Uploading documentation to ${targetUrl}..."
        rsync -ah --stats --delete "docs/pmd-doc-${pmdVersion}/" "${PMD_SF_USER}@web.sourceforge.net:/home/project-web/pmd/htdocs/${targetPath}/"
        pmd_ci_log_success "Successfully uploaded documentation: ${targetUrl}"
    )
}

#
# Create a new blog post on sourceforge. The blog post will be in state "draft" first.
#
# $RESULT = REST url to the blog post
#
# See https://sourceforge.net/p/forge/documentation/Allura%20API/
#
function pmd_ci_sourceforge_createDraftBlogPost() {
    local title="$1"
    local text="$2"
    local labels="$3"
    local labels_arg=""

    if [ -n "$labels" ]; then
      labels_arg="--form"
      labels="labels=${labels}"
    fi

    RESULT=$(curl --silent --include --request POST \
      --header "Authorization: Bearer ${PMD_SF_BEARER_TOKEN}" \
      "${labels_arg}" "${labels}" \
      --form "state=draft" \
      --form "text=$text" \
      --form "title=$title" \
      https://sourceforge.net/rest/p/pmd/news | grep -i "location: "|cut -d " " -f 2|tr -d "\r\n")

    pmd_ci_log_success "Created sourceforge blog post: ${RESULT}"
}

#
# Publishes an existing blog post
#
# See https://sourceforge.net/p/forge/documentation/Allura%20API/
#
function pmd_ci_sourceforge_publishBlogPost() {
    local url="$1"

    local response
    response=$(curl --silent --request POST \
      --header "Authorization: Bearer ${PMD_SF_BEARER_TOKEN}" \
      --form "state=published" \
      "${url}")
    pmd_ci_log_debug "Response: ${response}"

    pmd_ci_log_success "Published sourceforge blog post: ${url}"
}
