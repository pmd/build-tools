[![Build Status](https://github.com/pmd/build-tools/workflows/build/badge.svg?branch=master)](https://github.com/pmd/build-tools/actions?query=workflow%3Abuild+branch%3Amaster)

# PMD build tools

Artifact containing configuration data and tools to build pmd/pmd from source.

**Note:** This projects does not use semantic versioning.

-----

*   [build-env](#build-env)
*   [scripts](#scripts)
    *   [Overview](#overview)
    *   [Usage](#usage)
        *   [inc/log.bash](#inc-log-bash)
        *   [inc/utils.bash](#inc-utils-bash)
        *   [inc/openjdk.bash](#inc-openjdk-bash)
        *   [check-environment.sh](#check-environment-sh)

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
before doing any work. This is always done in the function "fetch_ci_scripts()".

Library functions may depend on other library functions as well.

Namespaces: Exported global variables use the prefix `PMD_CI_`. Functions of a library use the same
common prefix starting with `pmd_ci_` followed by the library name, followed by the actual function name.

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
