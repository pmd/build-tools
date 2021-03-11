#!/usr/bin/env bash

MODULE="setup-secrets"
SCRIPT_INCLUDES="log.bash"

#
# The functions here require the following environment variables:
# PMD_CI_SECRET_PASSPHRASE
#

function pmd_ci_setup_secrets_private_env() {
    pmd_ci_log_info "Setting up secrets as environment variables..."

    fetch_ci_file "private-env.asc"
    local -r fullpath="$RESULT"

    printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --yes --decrypt \
        --passphrase-fd 0 \
        --output "${fullpath%.asc}" "${fullpath}"

    # shellcheck source=/dev/null
    source "${fullpath%.asc}" >/dev/null 2>&1
    rm "${fullpath%.asc}"
}

function pmd_ci_setup_secrets_gpg_key() {
    pmd_ci_log_info "Setting up GPG release signing key..."

    fetch_ci_file "release-signing-key-D0BF1D737C9A1C22.asc"
    local -r fullpath="$RESULT"

    mkdir -p "${HOME}/.gpg"
    printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --yes --decrypt \
        --passphrase-fd 0 \
        --output "${fullpath%.asc}" "${fullpath}"
    gpg --batch --import "${fullpath%.asc}"
    rm "${fullpath%.asc}"
}

function pmd_ci_setup_secrets_ssh() {
    pmd_ci_log_info "Setting up .ssh/id_rsa..."
    fetch_ci_file "id_rsa.asc"
    local -r fullpath="$RESULT"

    printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --yes --decrypt \
        --passphrase-fd 0 \
        --output "${fullpath%.asc}" "${fullpath}"
    chmod 600 "${fullpath%.asc}"

    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    mv "${fullpath%.asc}" "${HOME}/.ssh/id_rsa"

    pmd_ci_log_info "Setting up .ssh/known_hosts..."
    # cleanup old keys
    if [ -e "$HOME/.ssh/known_hosts" ]; then
        ssh-keygen -R web.sourceforge.net > /dev/null 2>&1
        ssh-keygen -R pmd-code.org > /dev/null 2>&1
        ssh-keygen -R github.com > /dev/null 2>&1
    fi

    {
        #
        # web.sourceforge.net (https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)
        #
        # run locally:
        # ssh-keyscan web.sourceforge.net | tee -a sf_known_hosts
        #
        # verify fingerprints:
        # ssh-keygen -F web.sourceforge.net -l -f sf_known_hosts
        # # Host web.sourceforge.net found: line 1 
        # web.sourceforge.net RSA SHA256:xB2rnn0NUjZ/E0IXQp4gyPqc7U7gjcw7G26RhkDyk90 
        # # Host web.sourceforge.net found: line 2 
        # web.sourceforge.net ECDSA SHA256:QAAxYkf0iI/tc9oGa0xSsVOAzJBZstcO8HqGKfjpxcY 
        # # Host web.sourceforge.net found: line 3 
        # web.sourceforge.net ED25519 SHA256:209BDmH3jsRyO9UeGPPgLWPSegKmYCBIya0nR/AWWCY 
        #
        # then add output of `ssh-keygen -F web.sourceforge.net -f sf_known_hosts`
        #
        echo 'web.sourceforge.net ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA2uifHZbNexw6cXbyg1JnzDitL5VhYs0E65Hk/tLAPmcmm5GuiGeUoI/B0eUSNFsbqzwgwrttjnzKMKiGLN5CWVmlN1IXGGAfLYsQwK6wAu7kYFzkqP4jcwc5Jr9UPRpJdYIK733tSEmzab4qc5Oq8izKQKIaxXNe7FgmL15HjSpatFt9w/ot/CHS78FUAr3j3RwekHCm/jhPeqhlMAgC+jUgNJbFt3DlhDaRMa0NYamVzmX8D47rtmBbEDU3ld6AezWBPUR5Lh7ODOwlfVI58NAf/aYNlmvl2TZiauBCTa7OPYSyXJnIPbQXg6YQlDknNCr0K769EjeIlAfY87Z4tw=='
        echo 'web.sourceforge.net ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCwsY6sZT4MTTkHfpRzYjxG7mnXrGL74RCT2cO/NFvRrZVNB5XNwKNn7G5fHbYLdJ6UzpURDRae1eMg92JG0+yo='
        echo 'web.sourceforge.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQD35Ujalhh+JJkPvMckDlhu4dS7WH6NsOJ15iGCJLC'

        #
        # pmd-code.org
        #
        # ssh-keyscan pmd-code.org | tee -a pmd_known_hosts
        # ssh-keygen -F pmd-code.org -l -f pmd_known_hosts
        # # Host pmd-code.org found: line 1 
        # pmd-code.org RSA SHA256:/uKehVNumCNvJL8C5CziwV9KkUUxHfggq0C4GTrUhwg
        # # Host pmd-code.org found: line 2 
        # pmd-code.org ECDSA SHA256:6aD1r1XuIoc/zgBT3bt1S9L5ToyJzdQ9rrcMchnqiRA
        # # Host pmd-code.org found: line 3 
        # pmd-code.org ED25519 SHA256:nvkIAzZhYTxXqSU3DWvos83A0EocZ5dsxNkx1LoMZhg
        # ssh-keygen -F pmd-code.org -f pmd_known_hosts
        echo 'pmd-code.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVsIeF6xU0oPb/bMbxG1nU1NDyBpR/cBEPZcm/PuJwdI9B0ydPHA6FysqAnt32fNFznC2SWisnWyY3iNsP3pa8RQJVwmnnv9OboGFlW2/61o3iRyydcpPbgl+ADdt8iU9fmMI7dC04UqgHGBoqOwVNna9VylTjp5709cK2qHnwU450F6YcOEiOKeZfJvV4PmpJCz/JcsUVqft6StviR31jKnqbnkZdP8qNoTbds6WmGKyXkhHdLSZE7X1CFQH28tk8XFqditX93ezeCiThFL7EleDexV/3+2+cs5878sDMUMzHS5KShTjkxzhHaodhtIEdNesinq/hOPbxAGkQ0FbD'
        echo 'pmd-code.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMfSJtZcJCeENSZMvdngr+Hwe7oUVQWWKwC4HnfiOoAh/NSIlzJyQvpoPZxnEFid6Y3ntDK+rnx04Japo63zD8Q='
        echo 'pmd-code.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFa88nqfMavMH/tGeS5DNrSeM5AVHmZQGHh98vC1717o'

        #
        # github.com (https://docs.github.com/en/github/authenticating-to-github/githubs-ssh-key-fingerprints)
        #
        # ssh-keyscan github.com | tee -a github_known_hosts
        # ssh-keygen -F github.com -l -f github_known_hosts
        # # Host github.com found: line 1 
        # github.com RSA SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8
        # ssh-keygen -F github.com -f github_known_hosts
        echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='

    } >> "$HOME/.ssh/known_hosts"
}

function fetch_ci_file() {
    local -r file="$1"
    local -r files_url="${PMD_CI_FILES_URL:-https://raw.githubusercontent.com/pmd/build-tools/master/files}"
    local files_dir
    files_dir="$(dirname "$0")/../files"
    files_dir="$(realpath "$files_dir")"

    mkdir -p "${files_dir}"
    if [ ! -e "${files_dir}/${file}" ]; then
        pmd_ci_log_info "Fetching ${files_url}/${file} to ${files_dir}"
        curl -sSL "${files_url}/${file}" > "${files_dir}/${file}"
    else
        pmd_ci_log_info "Using existing ${files_dir}/${file}"
    fi

    RESULT="${files_dir}/${file}"
}

function fetch_ci_scripts() {
    local inc_dir
    local inc_url
    inc_dir="$(dirname "$0")/inc"
    inc_url="${PMD_CI_SCRIPTS_URL:-https://raw.githubusercontent.com/pmd/build-tools/master/scripts}/inc"

    mkdir -p "${inc_dir}"

    for f in ${SCRIPT_INCLUDES}; do
        if [ ! -e "${inc_dir}/$f" ]; then
            curl -sSL "${inc_url}/$f" > "${inc_dir}/$f"
        fi
        [ "$PMD_CI_DEBUG" = "true" ] && echo "loading ${inc_dir}/$f in ${MODULE}"
        # shellcheck source=/dev/null
        source "${inc_dir}/$f" || exit 1
    done
}

fetch_ci_scripts
