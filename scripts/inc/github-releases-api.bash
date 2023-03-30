#!/usr/bin/env bash

MODULE="github-releases-api"
SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

#
# The functions here require the following environment variables:
# GITHUB_TOKEN - this is the default github actions token
# GITHUB_BASE_URL
#

#
# Creates a new release on github with the given tag and target_commit.
# The release is draft and not published.
#
# $RESULT = release json string
#
# See: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#create-a-release
#
function pmd_ci_gh_releases_createDraftRelease() {
    local tagName="$1"
    local targetCommitish="$2"

    pmd_ci_log_debug "${FUNCNAME[0]}: Creating new draft release for tag=$tagName and commit=$targetCommitish"

    local request
    request=$(cat <<EOF
{
    "tag_name": "${tagName}",
    "target_commitish": "${targetCommitish}",
    "name": "${tagName}",
    "draft": true
}
EOF
    )

    pmd_ci_log_debug "POST $GITHUB_BASE_URL/releases"
    pmd_ci_log_info "Creating github draft release"
    RESULT=$(curl --fail -s -L \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: token ${GITHUB_TOKEN}" \
                -H "Content-Type: application/json" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                -X POST \
                --data "${request}" \
                "$GITHUB_BASE_URL/releases")
    pmd_ci_log_debug " -> response: $RESULT"

    pmd_ci_log_success "Created draft release with id $(echo "$RESULT" | jq --raw-output ".url")"
}

#
# Gets the latest draft release and returns with 0.
# Returns with 1, if the latest release is not a draft - meaning, there is no
# draft release (yet?).
# 
# RESULT = release json string (or empty, if there is no draft release)
#
# See: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#list-releases
#
function pmd_ci_gh_releases_getLatestDraftRelease() {
    pmd_ci_log_debug "${FUNCNAME[0]}"
    pmd_ci_log_debug "GET $GITHUB_BASE_URL/releases?per_page=1"
    RESULT=$(curl --fail -s -L \
                -H "Accept: application/vnd.github+json" \
                -H "Authorization: token ${GITHUB_TOKEN}" \
                -H "Content-Type: application/json" \
                -H "X-GitHub-Api-Version: 2022-11-28" \
                "$GITHUB_BASE_URL/releases?per_page=1" | jq ".[0]")
    pmd_ci_log_debug " -> response: $RESULT"

    local draft
    draft=$(echo "$RESULT" | jq ".draft")

    if [ "$draft" != "true" ]; then
        RESULT=""
        pmd_ci_log_error "Could not find draft release!"
        return 1
    fi
    pmd_ci_log_info "Found draft release: $(echo "$RESULT" | jq --raw-output ".url")"
}

#
# Deletes a release.
#
# See: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#delete-a-release
#
function pmd_ci_gh_releases_deleteRelease() {
    local release="$1"

    pmd_ci_gh_releases_getIdFromData "$release"
    local releaseId="$RESULT"
    pmd_ci_log_debug "${FUNCNAME[0]} id=$releaseId"
    pmd_ci_log_debug "DELETE $GITHUB_BASE_URL/releases/$releaseId"
    pmd_ci_log_info "Deleting github release $releaseId"
    local response
    response=$(curl --fail -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -X DELETE \
        "$GITHUB_BASE_URL/releases/$releaseId")
    pmd_ci_log_debug " -> response: $response"
    pmd_ci_log_success "Deleted release with id $releaseId"
}

#
# Determines the release id from the given JSON release data.
#
# RESULT = "the release id"
#
function pmd_ci_gh_releases_getIdFromData() {
    local release="$1"

    RESULT=$(echo "$release" | jq --raw-output ".id")
}

#
# Determines the tag_name from the given JSON release data.
#
# RESULT = "the tag name"
#
function pmd_ci_gh_releases_getTagNameFromData() {
    local release="$1"

    RESULT=$(echo "$release" | jq --raw-output ".tag_name")
}

#
# Uploads a asset to an existing release.
#
# See: https://docs.github.com/en/rest/releases/assets?apiVersion=2022-11-28#upload-a-release-asset
#
function pmd_ci_gh_releases_uploadAsset() {
    local release="$1"
    local filename="$2"
    local name
    name=$(basename "$filename")

    pmd_ci_gh_releases_getIdFromData "$release"
    local releaseId="$RESULT"
    pmd_ci_log_debug "${FUNCNAME[0]}: releaseId=$releaseId file=$filename name=$name"

    local uploadUrl
    uploadUrl=$(echo "$release" | jq --raw-output ".upload_url")
    uploadUrl="${uploadUrl%%\{\?name,label\}}"
    uploadUrl="${uploadUrl}?name=${name}"
    pmd_ci_log_debug "POST $uploadUrl"
    pmd_ci_log_info "Uploading $filename to github release $releaseId"
    local response
    response=$(curl --fail -s -L \
                        -H "Accept: application/vnd.github+json" \
                        -H "Authorization: token ${GITHUB_TOKEN}" \
                        -H "Content-Type: application/zip" \
                        -H "X-GitHub-Api-Version: 2022-11-28" \
                        --data-binary "@$filename" \
                        -X POST \
                        "${uploadUrl}")
    pmd_ci_log_debug " -> response: $response"
    pmd_ci_log_success "Uploaded release asset $filename for release $releaseId"
}

#
# Updates the release info: name and body.
# The body is escaped to fit into JSON, so it is allowed for the body to be
# a multi-line string.
#
# See: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#update-a-release
#
function pmd_ci_gh_releases_updateRelease() {
    local release="$1"
    local name="$2"
    local body="$3"

    pmd_ci_gh_releases_getIdFromData "$release"
    local releaseId="$RESULT"
    pmd_ci_gh_releases_getTagNameFromData "$release"
    local tagName="$RESULT"
    pmd_ci_log_debug "${FUNCNAME[0]} releaseId=$releaseId name=$name tag_name=$tagName"

    body="${body//\\/\\\\}"
    body="${body//$'\r'/}"
    body="${body//$'\n'/\\r\\n}"
    body="${body//\"/\\\"}"

    local request
    request=$(cat <<EOF
{
    "tag_name": "${tagName}",
    "name": "${name}",
    "body": "${body}"
}
EOF
    )

    pmd_ci_log_debug "PATCH $GITHUB_BASE_URL/releases/${releaseId}"
    pmd_ci_log_debug " -> request: $request"
    pmd_ci_log_info "Updating github release $releaseId"
    local response
    response=$(curl --fail -s -L \
                         -H "Accept: application/vnd.github+json" \
                         -H "Authorization: token ${GITHUB_TOKEN}" \
                         -H "Content-Type: application/json" \
                         -H "X-GitHub-Api-Version: 2022-11-28" \
                         --data "${request}" \
                         -X PATCH \
                         "$GITHUB_BASE_URL/releases/${releaseId}")
    pmd_ci_log_debug " -> response: $response"
    pmd_ci_log_success "Updated release with id=$releaseId"
}

#
# Publish a release by setting draft="false".
# Note: This will send out the notification emails if somebody
# watches the releases.
#
# See: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#update-a-release
#
function pmd_ci_gh_releases_publishRelease() {
    local release="$1"

    pmd_ci_gh_releases_getIdFromData "$release"
    local releaseId="$RESULT"
    pmd_ci_log_debug "${FUNCNAME[0]} releaseId=$releaseId"

    # Warning: Latest release cannot be draft or prerelease.
    local request='{"draft":false,"make_latest":"true","prerelease":false}'
    pmd_ci_log_debug "PATCH $GITHUB_BASE_URL/releases/${releaseId}"
    pmd_ci_log_debug " -> request: $request"
    pmd_ci_log_info "Publishing github release $releaseId"
    local response
    response=$(curl --fail -s -L \
                         -H "Accept: application/vnd.github+json" \
                         -H "Authorization: token ${GITHUB_TOKEN}" \
                         -H "Content-Type: application/json" \
                         -H "X-GitHub-Api-Version: 2022-11-28" \
                         --data "${request}" \
                         -X PATCH \
                         "$GITHUB_BASE_URL/releases/${releaseId}")
    pmd_ci_log_debug " -> response: $response"
    local htmlUrl
    htmlUrl=$(echo "$response" | jq --raw-output ".html_url")
    pmd_ci_log_success "Published release with id=$releaseId at $htmlUrl"
}
