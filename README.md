[![Build Status](https://github.com/pmd/build-tools/workflows/build/badge.svg?branch=master)](https://github.com/pmd/build-tools/actions?query=workflow%3Abuild+branch%3Amaster)

# PMD build tools

Artifact containing configuration data and scripts to build and release pmd/pmd from source.

**Note:** This project does not use semantic versioning.

-----

*   [build-env](#build-env)
*   [scripts](#scripts)
    *   [Overview](#overview)
    *   [Usage](#usage)
        *   [inc/log.bash](#inc-log-bash)
        *   [inc/utils.bash](#inc-utils-bash)
        *   [inc/openjdk.bash](#inc-openjdk-bash)
        *   [inc/github-releases-api.bash](#inc-github-releases-api-bash)
        *   [inc/setup-secrets.bash](#inc-setup-secrets-bash)
        *   [check-environment.sh](#check-environment-sh)
*   [files](#files)
    *   [private-env.asc](#private-env-asc)
    *   [release-signing-key-D0BF1D737C9A1C22.asc](#release-signing-key-d0bf1d737c9a1c22-asc)
    *   [id_rsa.asc](#id_rsa-asc)
    *   [id_rsa.pub](#id_rsa-pub)

## build-env

Ubuntu Linux based. Can be used to test the scripts.

Once build the docker container: 

    $ docker build \
        --tag pmd-build-env \
        build-env

This is only needed once. This builds the image, from which new containers can be started.
A new image needs to be created, if e.g. ubuntu is to be updated or any other program.

Then run the container, mounting in the pmd-build-tools repo as a volume:

    $ docker run \
        --interactive \
        --tty \
        --name pmd-build-env \
        --mount type=bind,source="$(pwd)",target=/workspaces/pmd/build-tools \
        pmd-build-env:latest

You're now in a shell inside the container. You can start a second shell in the same container:

    $ docker exec \
        --interactive \
        --tty pmd-build-env \
        /bin/bash --login

The container is stopped, if the first shell is exited. To start the same container again:

    $ docker start \
        --interactive \
        pmd-build-env

To list the running and stopped containers:

    $ docker ps \
        --all \
        --filter name=pmd-build-env

If not needed anymore, you can destroy the container:

    $ docker rm pmd-build-env

## scripts

### Overview

Scripts are stored in `scripts` subfolder. There are two types:

1. Shell scripts to be executed as programs. The extension is ".sh".
2. Library functions to be included by those scripts. The extension is ".bash" and they are
   located in `scripts/inc`.

All scripts are bash scripts.

The shell scripts might depend on one or more library scripts. They need to fetch their dependencies
before doing any work. This is always done in the function "fetch_ci_scripts()". The global variable
`PMD_CI_SCRIPTS_URL` is used as the base url to fetch the scripts.

Library functions may depend on other library functions as well.

Namespaces: Exported global variables use the prefix `PMD_CI_`. Functions of a library use the same
common prefix starting with `pmd_ci_` followed by the library name, followed by the actual function name.

Use [shellcheck](https://www.shellcheck.net/) to verify the scripts.

### Usage

#### inc/log.bash

Namespace: pmd_ci_log

Functions:

*   pmd_ci_log_error
*   pmd_ci_log_info
*   pmd_ci_log_success
*   pmd_ci_log_debug

Vars:

*   PMD_CI_LOG_COL_GREEN
*   PMD_CI_LOG_COL_RED
*   PMD_CI_LOG_COL_RESET
*   PMD_CI_LOG_COL_YELLOW

Used global vars:

*   PMD_CI_DEBUG: true|false.

#### inc/utils.bash

Namespace: pmd_ci_utils

Functions:

*   pmd_ci_utils_get_os: returns one of "linux", "macos", "windows"
*   pmd_ci_utils_determine_build_env
*   pmd_ci_utils_is_fork_or_pull_request

Test with: `bash -c "source inc/utils.bash; pmd_ci_utils_get_os" $(pwd)/test.sh`

#### inc/openjdk.bash

Namespace: pmd_ci_openjdk

Functions:

*   pmd_ci_openjdk_install_adoptopenjdk. Usage e.g. `pmd_ci_openjdk_install_adoptopenjdk 11`
    Supports also EA builds, e.g. `pmd_ci_openjdk_install_adoptopenjdk 16-ea`
*   pmd_ci_openjdk_install_zuluopenjdk. Usage e.g. `pmd_ci_openjdk_install_zuluopenjdk 7`
*   pmd_ci_openjdk_setdefault. Usage e.g. `pmd_ci_openjdk_setdefault 11`

Test with: `bash -c "source inc/openjdk.bash; pmd_ci_openjdk_install_adoptopenjdk 11" $(pwd)/test.sh`

#### inc/github-releases-api.bash

Namespace: pmd_ci_gh_releases

Functions:

*   pmd_ci_gh_releases_createDraftRelease
*   pmd_ci_gh_releases_getLatestDraftRelease
*   pmd_ci_gh_releases_deleteRelease
*   pmd_ci_gh_releases_getIdFromData
*   pmd_ci_gh_releases_getTagNameFromData
*   pmd_ci_gh_releases_uploadAsset
*   pmd_ci_gh_releases_updateRelease
*   pmd_ci_gh_releases_publishRelease


Used global vars:

*   GITHUB_OAUTH_TOKEN
*   GITHUB_BASE_URL

Test with: 

```
bash -c 'export GITHUB_OAUTH_TOKEN=.... ; \
         export GITHUB_BASE_URL=https://api.github.com/repos/pmd/pmd ; \
         export PMD_CI_DEBUG=false ; \
         source inc/github-releases-api.bash ; \
         pmd_ci_gh_releases_createDraftRelease ; \
         pmd_ci_gh_releases_getLatestDraftRelease ; \
         export therelease="$RESULT" ; \
         pmd_ci_gh_releases_uploadAsset "$therelease" "inc/github-releases-api.bash"
         export body='\''the body \
         line2'\'' ; \
         pmd_ci_gh_releases_updateRelease "$therelease" "test release" "$body" ; \
         #pmd_ci_gh_releases_deleteRelease "$therelease" ; \
         ' $(pwd)/test.sh
```

#### inc/setup-secrets.bash

Namespace: pmd_ci_setup_secrets

Functions:

*   pmd_ci_setup_secrets_private_env
*   pmd_ci_setup_secrets_gpg_key
*   pmd_ci_setup_secrets_ssh

Used global vars:

*   PMD_CI_SECRET_PASSPHRASE: This is provided as a github secret
    (`PMD_CI_SECRET_PASSPHRASE: ${{ secrets.PMD_CI_SECRET_PASSPHRASE }}`) in github actions workflow.
    It is used to decrypt further secrets used by other scripts (github releases api, ...)
*   PMD_CI_FILES_URL: This is the base url from where to fetch additional files. For setting up
    secrets, the file `private-env.asc` is fetched from there.

Test with:

```
bash -c 'set -e; \
         export PMD_CI_SECRET_PASSPHRASE=.... ; \
         export PMD_CI_DEBUG=false ; \
         source inc/setup-secrets.bash ; \
         pmd_ci_setup_secrets_private_env ; \
         pmd_ci_setup_secrets_gpg_key ; \
         pmd_ci_setup_secrets_ssh ; \
         # env # warning: prints out the passwords in clear! ; \
         ' $(pwd)/test.sh
```



#### check-environment.sh

Usage in github actions step:

```yaml
- name: Check Environment
  run: |
    f=check-environment.sh; \
    mkdir -p .ci && \
    ( [ -e .ci/$f ] || curl -sSL "${PMD_CI_SCRIPTS_URL}/$f" > ".ci/$f" ) && \
    .ci/$f
  env:
    PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/pmd/build-tools/master/scripts
  shell: bash
```

The script exits with code 0, if everything is fine and with 1, if one or more problems have been detected.
Thus it can fail the build.

## files

### private-env.asc

This file contains the encrypted secrets used during the build, e.g. github tokens, passwords for sonatype, ...

It is encrypted with the password in `PMD_CI_SECRET_PASSPHRASE`.

Here's a template for the file:

```
#
# private-env
#
# encrypt:
# printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
#  --passphrase-fd 0 \
#  private-env
#
# decrypt:
# printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --decrypt \
#  --passphrase-fd 0 \
#  --output private-env private-env.asc
#

export PMD_CI_SECRET_PASSPHRASE=...

# CI_DEPLOY_USERNAME - the user which can upload net.sourceforge.pmd:* to https://oss.sonatype.org/
# CI_DEPLOY_PASSWORD
export CI_DEPLOY_USER=...
export CI_DEPLOY_PASSWORD=...

# CI_SIGN_KEYNAME - GPG key used to sign the release jars before uploading to maven central
# CI_SIGN_PASSPHRASE
export CI_SIGN_KEY=...
export CI_SIGN_PASSPHRASE=...

export PMD_SF_USER=...
export PMD_SF_APIKEY=...

export GITHUB_OAUTH_TOKEN=...
export GITHUB_BASE_URL=https://api.github.com/repos/pmd/pmd
export SONAR_TOKEN=...
export COVERALLS_REPO_TOKEN=...

# These are also in public-env
export DANGER_GITHUB_API_TOKEN=...
export PMD_CI_CHUNK_TOKEN=...
```

### release-signing-key-D0BF1D737C9A1C22.asc

Export the private key and encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  release-signing-key-D0BF1D737C9A1C22
```

The public key is available here: https://keys.openpgp.org/vks/v1/by-fingerprint/EBB241A545CB17C87FACB2EBD0BF1D737C9A1C22
and http://pool.sks-keyservers.net:11371/pks/lookup?search=0xD0BF1D737C9A1C22&fingerprint=on&op=index

### id_rsa.asc

That's the private SSH key used for committing on github as pmd-bot and to access sourceforge and pmd-code.org.

Encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  id_rsa
```

### id_rsa.pub

The corresponding public key, here for convenience.

