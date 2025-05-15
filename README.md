[![Build Status](https://github.com/pmd/build-tools/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/pmd/build-tools/actions/workflows/build.yml)

# PMD build tools

Artifact containing configuration data and scripts to build and release pmd/pmd from source.

**Note:** This project does not use semantic versioning.

-----

*   [build-env](#build-env)
*   [scripts](#scripts)
    *   [Overview](#overview)
    *   [Usage](#usage)
        *   [inc/fetch_ci_scripts.bash](#incfetch_ci_scriptsbash)
        *   [inc/log.bash](#inclogbash)
        *   [inc/utils.bash](#incutilsbash)
        *   [inc/openjdk.bash](#incopenjdkbash)
        *   [inc/github-releases-api.bash](#incgithub-releases-apibash)
        *   [inc/setup-secrets.bash](#incsetup-secretsbash)
        *   [inc/sourceforge-api.bash](#incsourceforge-apibash)
        *   [inc/maven.bash](#incmavenbash)
        *   [inc/pmd-code-api.bash](#incpmd-code-apibash)
        *   [check-environment.sh](#check-environmentsh)
*   [files](#user-content-files)
    *   [private-env.asc](#private-envasc)
    *   [release-signing-key-D0BF1D737C9A1C22.asc](#release-signing-key-d0bf1d737c9a1c22asc)
    *   [pmd.github.io_deploy_key.asc](#pmdgithubio_deploy_keyasc)
    *   [pmd-eclipse-plugin-p2-site_deploy_key.asc](#pmd-eclipse-plugin-p2-site_deploy_keyasc)
    *   [pmd-code.org_deploy_key.asc](#pmdcodeorg_deploy_keyasc)
    *   [web.sourceforge.net_deploy_key.asc](#websourceforgenet_deploy_keyasc)
    *   [maven-settings.xml](#maven-settingsxml)
*   [Testing](#testing)
*   [Miscellaneous](#miscellaneous)
    *   [Nexus Staging Maven Plugin](#nexus-staging-maven-plugin)
    *   [Remote debugging](#remote-debugging)
    *   [Intermittent connection resets or timeouts while downloading dependencies from maven central](#intermittent-connection-resets-or-timeouts-while-downloading-dependencies-from-maven-central)

## build-env

Ubuntu Linux based, same as github actions runner, see [Runner Images](https://github.com/actions/runner-images).
It can be used to test the scripts and perform the builds without github actions.

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

#### inc/fetch_ci_scripts.bash

Little helper script to download dependencies.

The only function is `fetch_ci_scripts`.

Use it in other scripts like this:

```
MODULE="my-library"
SCRIPT_INCLUDES="log.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

# other parts of your script
```

That's the only script, that needs to be copied and existing before. Only with this script, the
other scripts can be fetched as needed.

Used global vars:

*   PMD_CI_SCRIPTS_URL - defaults to https://raw.githubusercontent.com/pmd/build-tools/main/scripts

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
*   pmd_ci_utils_determine_build_env. Sets many variables, e.g. GITHUB_BASE_URL, PMD_CI_IS_FORK, ...
*   pmd_ci_utils_is_fork_or_pull_request
*   pmd_ci_utils_fetch_ci_file

Used global vars:

*   PMD_CI_SCRIPTS_URL: This is the base url from where to fetch additional files. For setting up
    secrets, the file `private-env.asc` is fetched from there.
    Defaults to https://raw.githubusercontent.com/pmd/build-tools/main/scripts
    The files are fetched from the sub directory "files".

Test with: `bash -c "source inc/utils.bash; pmd_ci_utils_get_os" $(pwd)/test.sh`

#### inc/openjdk.bash

Namespace: pmd_ci_openjdk

Functions:

*   pmd_ci_openjdk_install_adoptium. Usage e.g. `pmd_ci_openjdk_install_adoptium 11`
    Supports also EA builds, e.g. `pmd_ci_openjdk_install_adoptium 16-ea`
*   pmd_ci_openjdk_install_zuluopenjdk. Usage e.g. `pmd_ci_openjdk_install_zuluopenjdk 7`
*   pmd_ci_openjdk_setdefault. Usage e.g. `pmd_ci_openjdk_setdefault 11`

Test with: `bash -c "source inc/openjdk.bash; pmd_ci_openjdk_install_adoptium 11" $(pwd)/test.sh`

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

*   GITHUB_TOKEN - this is the default github actions token
*   GITHUB_BASE_URL

Test with: 

```
bash -c 'set -x ; \
         export GITHUB_TOKEN=.... ; \
         export GITHUB_BASE_URL=https://api.github.com/repos/pmd/pmd ; \
         export PMD_CI_DEBUG=false ; \
         source inc/github-releases-api.bash ; \
         pmd_ci_gh_releases_createDraftRelease "pmd_releases/6.30.0" "d2e4fb4ca370e7d5612dcc96fb74c29767a7671e" ; \
         sleep 1; \
         pmd_ci_gh_releases_getLatestDraftRelease ; \
         export therelease="$RESULT" ; \
         pmd_ci_gh_releases_uploadAsset "$therelease" "inc/github-releases-api.bash"
         export body='\''the body \
         line2'\'' ; \
         pmd_ci_gh_releases_updateRelease "$therelease" "test release" "$body" ; \
         #pmd_ci_gh_releases_deleteRelease "$therelease" ; \
         #pmd_ci_gh_releases_publishRelease "$therelease" ; \
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
*   PMD_CI_GPG_PRIVATE_KEY: The exported private key used for release signing, provided as a secret
    (`PMD_CI_GPG_PRIVATE_KEY: ${{ secrets.PMD_CI_GPG_PRIVATE_KEY }}`) in github actions workflow.

Test with:

```
bash -c 'set -e; \
         export PMD_CI_SECRET_PASSPHRASE=.... ; \
         export PMD_CI_GPG_PRIVATE_KEY=.... ; \
         export PMD_CI_DEBUG=false ; \
         source inc/setup-secrets.bash ; \
         pmd_ci_setup_secrets_private_env ; \
         pmd_ci_setup_secrets_gpg_key ; \
         pmd_ci_setup_secrets_ssh ; \
         # env # warning: prints out the passwords in clear! ; \
         ' $(pwd)/test.sh
```

#### inc/sourceforge-api.bash

Namespace: pmd_ci_sourceforge

Functions:

*   pmd_ci_sourceforge_uploadReleaseNotes
*   pmd_ci_sourceforge_uploadFile
*   pmd_ci_sourceforge_selectDefault
*   pmd_ci_sourceforge_rsyncSnapshotDocumentation
*   pmd_ci_sourceforge_createDraftBlogPost
*   pmd_ci_sourceforge_publishBlogPost

Used global vars:

*   PMD_SF_USER
*   PMD_SF_APIKEY
*   PMD_SF_BEARER_TOKEN

Test with:

```
bash -c 'set -e; \
         export PMD_CI_SECRET_PASSPHRASE=.... ; \
         export PMD_CI_DEBUG=false ; \
         source inc/setup-secrets.bash ; \
         source inc/sourceforge-api.bash ; \
         pmd_ci_setup_secrets_private_env ; \
         #pmd_ci_setup_secrets_gpg_key ; \
         pmd_ci_setup_secrets_ssh ; \
         pmd_ci_sourceforge_uploadReleaseNotes "pmd/Release-Script-Test" "Testing release notes" ; \
         echo "test file" > "release-test-file.txt" ; \
         pmd_ci_sourceforge_uploadFile "pmd/Release-Script-Test" "release-test-file.txt" ; \
         rm "release-test-file.txt" ; \
         pmd_ci_sourceforge_selectDefault "Release-Script-Test" ; \
         mkdir -p "docs/pmd-doc-Release-Script-Test/" ; \
         echo "test-file" > "docs/pmd-doc-Release-Script-Test/release-test.txt" ; \
         pmd_ci_sourceforge_rsyncSnapshotDocumentation "Release-Script-Test" "test-Release-Script-Test" ; \
         rm "docs/pmd-doc-Release-Script-Test/release-test.txt"; rmdir "docs/pmd-doc-Release-Script-Test"; rmdir "docs" ; \
         pmd_ci_sourceforge_createDraftBlogPost "draft post 1" "text with labels" "label1,label2" ; \
         blog="${RESULT}" ; \
         echo "URL: ${blog}" ; \
         pmd_ci_sourceforge_createDraftBlogPost "draft post 2" "text without labels" ; \
         blog="${RESULT}" ; \
         echo "URL: ${blog}" ; \
         #pmd_ci_sourceforge_publishBlogPost "${blog}" ; \
         ' $(pwd)/test.sh
```

Note that "pmd_ci_sourceforge_selectDefault" won't be successful, because the file to be selected as default
doesn't exist.

Don't forget to delete <https://sourceforge.net/projects/pmd/files/pmd/Release-Script-Test> and
<https://pmd.sourceforge.io/test-Release-Script-Test> after the test.

And also the created blog posts under <https://sourceforge.net/p/pmd/news/>.

#### inc/maven.bash

Namespace: pmd_ci_maven

Functions:

*   pmd_ci_maven_setup_settings
*   pmd_ci_maven_get_project_version: exports PMD_CI_MAVEN_PROJECT_VERSION
*   pmd_ci_maven_get_project_name
*   pmd_ci_maven_verify_version
*   pmd_ci_maven_display_info_banner
*   pmd_ci_maven_isSnapshotBuild
*   pmd_ci_maven_isReleaseBuild

Used global vars:

*   PMD_CI_BRANCH
*   PMD_CI_TAG

Exported global vars:

*   PMD_CI_MAVEN_PROJECT_VERSION

Test with:

```
bash -c 'set -e; \
         export PMD_CI_SECRET_PASSPHRASE=.... ; \
         export PMD_CI_DEBUG=true ; \
         source inc/maven.bash ; \
         pmd_ci_maven_setup_settings ; \
         cd .. ; \
         pmd_ci_maven_get_project_version ; \
         echo "version: $RESULT" ; \
         pmd_ci_maven_get_project_name ; \
         echo "name: $RESULT" ; \
         PMD_CI_MAVEN_PROJECT_VERSION="1.2.3-SNAPSHOT" ; \
         PMD_CI_BRANCH="test-branch" ; \
         pmd_ci_maven_verify_version ; \
         unset PMD_CI_BRANCH ; \
         PMD_CI_TAG="test-tag" ; \
         PMD_CI_MAVEN_PROJECT_VERSION="1.2.3" ; \
         pmd_ci_maven_verify_version ; \
         pmd_ci_maven_display_info_banner ; \
         pmd_ci_maven_isReleaseBuild && echo "release build" ; \
         PMD_CI_MAVEN_PROJECT_VERSION="1.2.3-SNAPSHOT" ; \
         unset PMD_CI_TAG ; \
         PMD_CI_BRANCH="test-branch" ; \
         pmd_ci_maven_isSnapshotBuild && echo "snapshot build" ; \
         ' $(pwd)/test.sh
```

#### inc/pmd-code-api.bash

Namespace: pmd_ci_pmd_code

Functions:

*   pmd_ci_pmd_code_uploadFile
*   pmd_ci_pmd_code_uploadZipAndExtract
*   pmd_ci_pmd_code_removeFolder
*   pmd_ci_pmd_code_createSymlink

Used global vars:

Test with:

```
bash -c 'set -e; \
         export PMD_CI_SECRET_PASSPHRASE=.... ; \
         export PMD_CI_DEBUG=true ; \
         source inc/setup-secrets.bash ; \
         source inc/pmd-code-api.bash ; \
         pmd_ci_setup_secrets_private_env ; \
         pmd_ci_setup_secrets_ssh ; \
         echo "test file" > "test-file-for-upload.txt" ; \
         zip "test-zip.zip" "test-file-for-upload.txt" ; \
         pmd_ci_pmd_code_uploadFile "/httpdocs/test-folder" "test-file-for-upload.txt" ; \
         echo "test file" > "test-file-for-upload.txt" ; \
         pmd_ci_pmd_code_uploadZipAndExtract "/httpdocs/test-folder2" "test-zip.zip" ; \
         rm "test-zip.zip" "test-file-for-upload.txt" ; \
         pmd_ci_pmd_code_createSymlink "/httpdocs/test-folder" "/httpdocs/test-folder3" ; \
         pmd_ci_pmd_code_removeFolder "/httpdocs/test-folder" ; \
         pmd_ci_pmd_code_removeFolder "/httpdocs/test-folder2" ; \
         pmd_ci_pmd_code_removeFolder "/httpdocs/test-folder3" ; \
         ' $(pwd)/test.sh
```


#### check-environment.sh

Usage in github actions step:

```yaml
- name: Setup Environment
  shell: bash
  run: |
    echo "LANG=en_US.UTF-8" >> $GITHUB_ENV
    echo "MAVEN_OPTS=-Dmaven.wagon.httpconnectionManager.ttlSeconds=180 -Dmaven.wagon.http.retryHandler.count=3" >> $GITHUB_ENV
    echo "PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/pmd/build-tools/main/scripts" >> $GITHUB_ENV
- name: Check Environment
  shell: bash
  run: |
    f=check-environment.sh; \
    mkdir -p .ci && \
    ( [ -e .ci/$f ] || curl -sSL "${PMD_CI_SCRIPTS_URL}/$f" > ".ci/$f" ) && \
    chmod 755 .ci/$f && \
    .ci/$f
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
# printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor --passphrase-fd 0 private-env
#
# decrypt:
# printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --decrypt --passphrase-fd 0 --output private-env private-env.asc
#

export PMD_CI_SECRET_PASSPHRASE=...

# CI_DEPLOY_USERNAME - the user which can upload net.sourceforge.pmd:* to https://oss.sonatype.org/
# CI_DEPLOY_PASSWORD
export CI_DEPLOY_USERNAME=...
export CI_DEPLOY_PASSWORD=...

export PMD_SF_USER=...
# https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/
export PMD_SF_APIKEY=...
# https://sourceforge.net/p/forge/documentation/Allura%20API/ (blog, wiki, ...)
# https://sourceforge.net/auth/oauth/
export PMD_SF_BEARER_TOKEN=...

# https://sonarcloud.io/dashboard?id=net.sourceforge.pmd%3Apmd
# The token can be configured here: https://sonarcloud.io/account/security/
export SONAR_TOKEN=...

# https://coveralls.io/github/pmd/pmd
# when logged in, the token is display on that page
export COVERALLS_REPO_TOKEN=...

# for pmd-regression-tester
# https://rubygems.org/settings/edit
export GEM_HOST_API_KEY=...

# These are also in public-env:
export PMD_CI_CHUNK_TOKEN=...
```

### pmd.github.io_deploy_key.asc

Created with `ssh-keygen -t ed25519 -C "ssh key for pmd. used for github actions to push to pmd.github.io" -f pmd.github.io_deploy_key`.

Encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  pmd.github.io_deploy_key
```

The corresponding public key `pmd.github.io_deploy_key.pub` is here for convenience. It is configured as a
deploy key for the repository [pmd.github.io](https://github.com/pmd/pmd.github.io/settings/keys) with
write access.

In order to use this key to push, you need to clone the repo with
this url: `git@github.com-pmd.github.io:pmd/pmd.github.io.git`.

### pmd-eclipse-plugin-p2-site_deploy_key.asc

Created with `ssh-keygen -t ed25519 -C "ssh key for pmd. used for github actions to push to pmd-eclipse-plugin-p2-site" -f pmd-eclipse-plugin-p2-site_deploy_key`.

Encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  pmd-eclipse-plugin-p2-site_deploy_key
```

The corresponding public key `pmd-eclipse-plugin-p2-site_deploy_key.pub` is here for convenience.
It is configured as a
deploy key for the repository [pmd-eclipse-plugin-p2-site](https://github.com/pmd/pmd-eclipse-plugin-p2-site/settings/keys)
with write access.

In order to use this key to push, you need to clone the repo with
this url: `git@github.com-pmd-eclipse-plugin-p2-site:pmd/pmd-eclipse-plugin-p2-site.git`.

### pmd-code.org_deploy_key.asc

Created with `ssh-keygen -t ed25519 -C "ssh key for pmd. used for github actions push to pmd-code.org" -f pmd-code.org_deploy_key`.

Encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  pmd-code.org_deploy_key
```

The corresponding public key `pmd-code.org_deploy_key.pub` is here for convenience.
It is configured in `~/.ssh/authorized_keys` on pmd@pmd-code.org.

### web.sourceforge.net_deploy_key.asc

Created with `ssh-keygen -t ed25519 -C "ssh key for pmd. used for github actions push to web.sourceforge.net" -f web.sourceforge.net_deploy_key`.

Encrypt it with PMD_CI_SECRET_PASSPHRASE:

```
printenv PMD_CI_SECRET_PASSPHRASE | gpg --symmetric --cipher-algo AES256 --batch --armor \
  --passphrase-fd 0 \
  web.sourceforge.net_deploy_key
```

The corresponding public key `web.sourceforge.net_deploy_key.pub` is here for convenience.
It is configured in for user "PMD_SF_USER" (see private-env)
on sourceforge: <https://sourceforge.net/auth/shell_services>.

Note: The same key is used to push to "git.code.sf.net" as user "PMD_SF_USER".

### maven-settings.xml

It contains the credentials for uploading the artifacts to maven-central for the server `ossrh`.
The actual configuration comes in via environment variables: `CI_DEPLOY_USERNAME` and `CI_DEPLOY_PASSWORD`.

## Testing

To test a complete build (or run it manually), you can use the docker build-env.
The script `create-gh-actions-env.sh` can simulate a Github Actions environment by setting up
some specific environment variables. With these variables set, `utils.bash/pmd_ci_utils_determine_build_env`
can figure out the needed information and `utils.bash/pmd_ci_utils_is_fork_or_pull_request` works.

Example session for a pull request:

```
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ unset PMD_CI_SECRET_PASSPHRASE
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/adangel/build-tools/gh-action-scripts/scripts
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ eval $(~/create-gh-actions-env.sh pull_request adangel/build-tools gh-actions-scripts)
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ .ci/build.sh
...
```

Example session for a forked build (a build executing on a forked repository):

```
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ unset PMD_CI_SECRET_PASSPHRASE
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/adangel/build-tools/gh-action-scripts/scripts
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ eval $(~/create-gh-actions-env.sh push adangel/build-tools gh-actions-scripts)
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ .ci/build.sh
...
```

Example session for a push build on the main repository:

```
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SECRET_PASSPHRASE=...
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/adangel/build-tools/gh-action-scripts/scripts
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ eval $(~/create-gh-actions-env.sh push pmd/build-tools gh-actions-scripts)
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ .ci/build.sh
...
```

Example session for a release build on the main repository from tag "v1.0.0":

```
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SECRET_PASSPHRASE=...
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ export PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/adangel/build-tools/gh-action-scripts/scripts
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ eval $(~/create-gh-actions-env.sh push pmd/build-tools refs/tags/v1.0.0)
pmd-ci@6cc27446ef02:~/workspaces/pmd/build-tools$ .ci/build.sh
...
```

Note, that `create-gh-actions-env.sh` sets up `MAVEN_OPTS` with `-DskipRemoteStaging=true`, so that no maven
artifacts are deployed automatically. You need to remove this, if you really want to perform a release.
Also note, that the property `autoReleaseAfterClose` is not configured and the default is `false`, so that
you would need to manually publish the staging repo. See also the section below about "Nexus Staging Maven Plugin".

## Miscellaneous

### Release Signing Keys

#### Creating a new key
In general, a key created once should be reused. However, if the key is (potentially) compromised, a new
key needs to be generated. A gpg key consists of a master key and one or more subkeys. The master key
defines the identity (fingerpringt, key ID) and subkeys can be used for actual signing. The master key is
then only used to create new subkeys or renew subkeys. For a more safe operation, the master key should
be kept offline and only the subkeys should be used for signing. A Release Signing Key also doesn't need
a subkey for encryption. In case a signing key gets compromised, the subkey can be revoked and a new key
can be generated. But the master key still is safe.

Creating such a key is not straightforward, hence this how to (there are a couple of guides
in the internet about best practices):

```
$ gpg --expert --full-generate-key
...
Please select what kind of key you want:
> 8 (RSA (set your own capabilities)
> S (Toggle Sign)
> E (Toggle Encrypt)
> Q
Current allowed actions: Certify
What keysize do you want?
> 4096
Please specify how long the key should be valid.
> 2y
Real name:
> PMD Release Signing Key
Email address:
> releases@pmd-code.org
...
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
uid                      PMD Release Signing Key <releases@pmd-code.org>
```

Then we create a subkey for signing:
```
$ gpg --edit-key 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
gpg> addkey
> 4 (RSA (sign only))
keysize:
> 4096
Expiration
> 2y
...
> save
```

Now let's publish the public key:
```
$ gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | curl -T - https://keys.openpgp.org
Key successfully uploaded. Proceed with verification here:
https://keys.openpgp.org/upload/....
```

Export the key to upload it to <https://keyserver.ubuntu.com/#submitKey>:
`gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | wl-copy`
Also upload it to <http://pgp.mit.edu/>.

Also export the (public) key into a file and add it to build-tools repo:
```
$ gpg --armor --export 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 > scripts/files/release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
```

Verify the uploaded key (and expiration date):

```
gpg --show-keys release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
curl 'https://keys.openpgp.org/vks/v1/by-fingerprint/2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
curl 'https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&exact=on&options=mr&op=get' | gpg --show-keys
curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
```

#### Current Key

* Used since January 2025
* Fingerprint `2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838`
* Used for signing artifacts in Maven Central

```
$ gpg --list-keys --fingerprint 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838
uid           [ultimate] PMD Release Signing Key <releases@pmd-code.org>
sub   rsa4096 2025-01-04 [S] [expires: 2027-01-04]
```

The public key is available here:
* <https://keys.openpgp.org/search?q=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838>
* <https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&op=index>
* <http://pgp.mit.edu/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&op=index>
* <https://github.com/pmd/build-tools/blob/main/scripts/files/release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc>


#### Old keys

* Fingerprint `EBB2 41A5 45CB 17C8 7FAC B2EB D0BF 1D73 7C9A 1C22`
  * Used until December 2024
  * Replaced as the passphrase has been compromised and therefore the key is potentially
    compromised. Note - as until now (January 2025) we don't have any indication that the key
    actually has been misused.
  * Revoked 2025-01-04.
  * see file `release-signing-key-D0BF1D737C9A1C22-public.asc`.

* Fingerprint `94A5 2756 9CAF 7A47 AFCA  BDE4 86D3 7ECA 8C2E 4C5B`
  * Old key used to sign PMD Designer
  * Revoked 2025-01-04.

#### Private key

In order for GitHub Action to automatically sign the artifacts for snapshot builds and release builds,
we need to make the private key along with the passphrase available. This is done using
multiple [`secrets`](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).
The secrets are configured on the organization level of PMD, so that the Release Signing key is available
for all repositories.

To not expose the master key, we only export the subkeys we use for signing and store this in the secret
`PMD_CI_GPG_PRIVATE_KEY`.

For setting up, export the secret key and copy-paste it into a new secret:

```
gpg --armor --export-secret-subkeys 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838 | wl-copy
```

(instead of wl-copy, use xclip or pbcopy, depending on your os).

This private key will be imported by the script `setup-secrets.bash`.

**Note 1:** We use option `--export-secret-subkeys` to only export the subkey and not the master key.
That way, we don't need to transfer the master key.

**Note 2:** In order to use the key later on, the passphrase is needed. This is also setup as a secret:
`PMD_CI_GPG_PASSPHRASE`. This secret is then exported as "MAVEN_GPG_PASSPHRASE" where needed
(`MAVEN_GPG_PASSPHRASE: ${{ secrets.PMD_CI_GPG_PASSPHRASE }}`) in github actions workflows.
See also <https://maven.apache.org/plugins/maven-gpg-plugin/usage.html#sign-artifacts-with-gnupg>.

**Note 3:** The private key is now only secured by the passphrase. It is stored as a GitHub Actions
secret and available in an environment variable. It is not anymore committed in
this build-tools repository and is therefore not encrypted with another key (e.g. PMD_CI_SECRET_PASSPHRASE). 

#### Updating the key

From time to time the key needs to be renewed, passphrase needs to be changed or a whole (sub)key needs to
be replaced.

For renewing or changing the passphrase, import the private master key and public key into your local gpg keystore
(if you don't have it already in your keyring) and renew it.
Make sure to renew all subkeys. Then export the public key again.

For replacing, generate a new (sub) key, just export it.

You can verify the expiration date with `gpg --fingerprint --list-key 2EFA55D0785C31F956F2F87EA0B5CA1A4E086838`:

```
pub   rsa4096 2025-01-04 [C] [expires: 2027-01-04]
      2EFA 55D0 785C 31F9 56F2  F87E A0B5 CA1A 4E08 6838
uid           [ultimate] PMD Release Signing Key <releases@pmd-code.org>
sub   rsa4096 2025-01-04 [S] [expires: 2027-01-04]

```

Upload the exported *public* key to

* <https://keys.openpgp.org/upload>
* <https://keyserver.ubuntu.com/#submitKey>
* <http://pgp.mit.edu/>

Verify the uploaded key expiration date:

```
gpg --show-keys release-signing-key-2EFA55D0785C31F956F2F87EA0B5CA1A4E086838-public.asc
curl 'https://keys.openpgp.org/vks/v1/by-fingerprint/2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
curl 'https://keyserver.ubuntu.com/pks/lookup?search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838&fingerprint=on&exact=on&options=mr&op=get' | gpg --show-keys
curl 'http://pgp.mit.edu/pks/lookup?op=get&search=0x2EFA55D0785C31F956F2F87EA0B5CA1A4E086838' | gpg --show-keys
```

Don't forget to update the secret `PMD_CI_GPG_PRIVATE_KEY` with the renewed private signing subkey.

### Nexus Staging Maven Plugin

⚠ This is deprecated, see <https://central.sonatype.org/news/20250326_ossrh_sunset/>

See <https://github.com/sonatype/nexus-maven-plugins/tree/master/staging/maven-plugin>.

This plugin is used, to upload maven artifacts to https://oss.sonatype.org/ and eventually to maven central
using the open source workflow by sonatype, see [OSSRH Guide](https://central.sonatype.org/publish/publish-guide/).

The plugin can be configured, see <https://github.com/sonatype/nexus-maven-plugins/tree/master/staging/maven-plugin#configuring-the-plugin> for some options.

Most important here are these:

*   `skipRemoteStaging=true`: Used during test runs of releases. This makes sure, the artifacts are only staged
    locally and never uploaded to https://oss.sonatype.org/.
    
    Property: [skipRemoteStaging](https://github.com/sonatype/nexus-maven-plugins/blob/0aee3defb33cb133ff536aba59b11d32a368b1e6/staging/maven-plugin/src/main/java/org/sonatype/nexus/maven/staging/deploy/DeployMojo.java#L106)

*   `autoReleaseAfterClose=true`: After all modules have been uploaded to the staging repository it is
    automatically closed (this can be controlled through `skipStagingRepositoryClose` but is the default
    behavior). And with `autoReleaseAfterClose`, the closed staging repository will be automatically released
    and published to maven central. This allows for fully automated releases.
    
    This property is set via `MAVEN_OPTS` in the workflow (`build.yml`). It is not set in the pom.xml as a plugin
    configuration directly in order to allow to override this setting from command line
    if needed (e.g. during release tests).
    
    Property: [autoReleaseAfterClose](https://github.com/sonatype/nexus-maven-plugins/blob/0aee3defb33cb133ff536aba59b11d32a368b1e6/staging/maven-plugin/src/main/java/org/sonatype/nexus/maven/staging/AbstractStagingMojo.java#L158)

*   `stagingProgressTimeoutMinutes=30`: This increases the default timeout of 5 minutes to 30 minutes for
    interaction with oss.sonatype.org. The main PMD repo has a lot of modules and depending on the load
    of oss.sonatype.org, the release of the staging repo might take a while.
    
    Property: [stagingProgressTimeoutMinutes](https://github.com/sonatype/nexus-maven-plugins/blob/0aee3defb33cb133ff536aba59b11d32a368b1e6/staging/maven-plugin/src/main/java/org/sonatype/nexus/maven/staging/AbstractStagingMojo.java#L174)

After the staging repository has been released, it is eventually synced to maven central. The release
won't appear here immediately but usually within 2 hours. You can check the current publish latency at
<https://status.maven.org/>.

### Remote debugging

Debugging remotely is possible with <https://github.com/mxschmitt/action-tmate>.

Just add the following step into the job:

```
      - name: Setup tmate session
        uses: mxschmitt/action-tmate@v3
```

The workflow [`troubleshooting`](https://github.com/pmd/pmd/blob/main/.github/workflows/troubleshooting.yml)
in PMD can be started manually, which already contains the tmate action.

**Note**: This is dangerous for push/pull builds on repositories of pmd itself, because these have access
to the secrets and the SSH session
is not protected. Builds triggered by pull requests from forked repositories don't have access to the secrets.

See also <https://docs.github.com/en/actions/reference/encrypted-secrets>.

### Intermittent connection resets or timeouts while downloading dependencies from maven central

Root issue seems to be SNAT Configs in Azure, which closes long running [idle TCP connections
after 4 minutes](https://docs.microsoft.com/en-us/azure/load-balancer/troubleshoot-outbound-connection#idletimeout).

The workaround is described in [actions/virtual-environments#1499](https://github.com/actions/virtual-environments/issues/1499)
and [WAGON-545](https://issues.apache.org/jira/browse/WAGON-545)
and [WAGON-486](https://issues.apache.org/jira/browse/WAGON-486):

The setting `-Dmaven.wagon.httpconnectionManager.ttlSeconds=180 -Dmaven.wagon.http.retryHandler.count=3`
makes sure, that Maven doesn't try to use pooled connections that have been unused for more than 180 seconds.
These settings are placed as environment variable `MAVEN_OPTS` in the workflow, so that they are active for
all Maven executions (including builds done by regression tester).

Alternatively, pooling could be disabled completely via `-Dhttp.keepAlive=false -Dmaven.wagon.http.pool=false`.
This has the consequence, that for each dependency, that is being downloaded, a new https connection is
established.

More information about configuring this can be found at [wagon-http](https://maven.apache.org/wagon/wagon-providers/wagon-http/).

**Update: Since [Maven 3.9.0](https://maven.apache.org/docs/3.9.0/release-notes.html)**, the native transport instead of wagon is used:

> The Maven Resolver transport has changed from Wagon to “native HTTP”, see [Resolver Transport guide](https://maven.apache.org/guides/mini/guide-resolver-transport.html).

Therefore, the property to configure the timeouts changed to `-Daether.connector.http.connectionMaxTtl=180`.
Retry count is by default 3 and can be omitted.
See <https://maven.apache.org/resolver/configuration.html> for all available properties.

Note: This system property only works with Maven 3.9.2 or later!

