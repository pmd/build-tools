[![Build Status](https://github.com/pmd/build-tools/workflows/build/badge.svg?branch=master)](https://github.com/pmd/build-tools/actions?query=workflow%3Abuild+branch%3Amaster)

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
    *   [id_rsa.asc](#id_rsaasc)
    *   [id_rsa.pub](#id_rsapub)
    *   [maven-settings.xml](#maven-settingsxml)
*   [Testing](#testing)
*   [Miscellaneous](#miscellaneous)
    *   [Nexus Staging Maven Plugin](#nexus-staging-maven-plugin)
    *   [Remote debugging](#remote-debugging)
    *   [Intermittent connection resets or timeouts while downloading dependencies from maven central](#intermittent-connection-resets-or-timeouts-while-downloading-dependencies-from-maven-central)

## build-env

Ubuntu Linux based, same as github actions runner, see [Virtual Environment](https://github.com/actions/virtual-environments).
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

*   PMD_CI_SCRIPTS_URL - defaults to https://raw.githubusercontent.com/pmd/build-tools/master/scripts

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
    Defaults to https://raw.githubusercontent.com/pmd/build-tools/master/scripts
    The files are fetched from the sub directory "files".

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
bash -c 'set -x ; \
         export GITHUB_OAUTH_TOKEN=.... ; \
         export GITHUB_BASE_URL=https://api.github.com/repos/pmd/pmd ; \
         export PMD_CI_DEBUG=false ; \
         source inc/github-releases-api.bash ; \
         pmd_ci_gh_releases_createDraftRelease "pmd_releases/6.30.0" "d2e4fb4ca370e7d5612dcc96fb74c29767a7671e" ; \
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
    echo "PMD_CI_SCRIPTS_URL=https://raw.githubusercontent.com/pmd/build-tools/master/scripts" >> $GITHUB_ENV
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

# CI_SIGN_KEYNAME - GPG key used to sign the release jars before uploading to maven central
# CI_SIGN_PASSPHRASE
# the passphrase is also used for the keystore password in pmd-eclipse-plugin for JAR signing.
export CI_SIGN_KEYNAME=...
export CI_SIGN_PASSPHRASE=...

export PMD_SF_USER=...
# https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/
export PMD_SF_APIKEY=...
# https://sourceforge.net/p/forge/documentation/Allura%20API/ (blog, wiki, ...)
# https://sourceforge.net/auth/oauth/
export PMD_SF_BEARER_TOKEN=...

# Token for github actions to push as <https://github.com/pmd-bot>
# The token needs the scope "public_repo".
export GITHUB_OAUTH_TOKEN=...
export SONAR_TOKEN=...
export COVERALLS_REPO_TOKEN=...

# for pmd-regression-tester
# https://rubygems.org/settings/edit
export GEM_HOST_API_KEY=...

# These are also in public-env:
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

### maven-settings.xml

The maven-settings.xml file contains a profile `sign`, which brings in the configuration for
`maven-gpg-plugin` to sign the artifacts prior to uploading it to maven central. The configuration
comes in via environment variables: `CI_SIGN_KEYNAME` and `CI_SIGN_PASSPHRASE`.

It also contains the credentials for uploading the artifacts to maven-central for the server `ossrh`. Again,
the actual configuration comes in via environment variables: `CI_DEPLOY_USERNAME` and `CI_DEPLOY_PASSWORD`.

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

Note, that `MAVEN_OPTS` contains `-DskipRemoteStaging=true`, so that no maven artifacts are not deployed.

## Miscellaneous

### Nexus Staging Maven Plugin

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

The workflow [`troubleshooting`](https://github.com/pmd/pmd/blob/master/.github/workflows/troubleshooting.yml)
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
