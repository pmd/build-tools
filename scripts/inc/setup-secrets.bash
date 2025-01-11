#!/usr/bin/env bash

MODULE="setup-secrets"
SCRIPT_INCLUDES="log.bash utils.bash"
# shellcheck source=inc/fetch_ci_scripts.bash
source "$(dirname "$0")/inc/fetch_ci_scripts.bash" && fetch_ci_scripts

#
# The functions here require the following environment variables:
# PMD_CI_SECRET_PASSPHRASE
#

function pmd_ci_setup_secrets_private_env() {
    pmd_ci_log_info "Setting up secrets as environment variables..."

    pmd_ci_utils_fetch_ci_file "private-env.asc"
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

    mkdir -p "${HOME}/.gpg"
    chmod 700 "${HOME}/.gpg"
    echo "${PMD_CI_GPG_PRIVATE_KEY}" | gpg --batch --import

    gpg --list-keys --fingerprint --keyid-format=long
    gpg --list-secret-keys --fingerprint --keyid-format=long
}

function pmd_ci_setup_secrets_ssh_privkey() {
    local -r name="$1"

    pmd_ci_log_info "Setting up .ssh/${name}..."
    pmd_ci_utils_fetch_ci_file "${name}.asc"
    local -r fullpath="$RESULT"
    printenv PMD_CI_SECRET_PASSPHRASE | gpg --batch --yes --decrypt \
        --passphrase-fd 0 \
        --output "${fullpath%.asc}" "${fullpath}"
    chmod 600 "${fullpath%.asc}"
    mv "${fullpath%.asc}" "${HOME}/.ssh/${name}"
}

function pmd_ci_setup_secrets_ssh() {
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    pmd_ci_setup_secrets_ssh_privkey "pmd.github.io_deploy_key"
    pmd_ci_setup_secrets_ssh_privkey "pmd-eclipse-plugin-p2-site_deploy_key"
    pmd_ci_setup_secrets_ssh_privkey "pmd-code.org_deploy_key"
    pmd_ci_setup_secrets_ssh_privkey "web.sourceforge.net_deploy_key"

    pmd_ci_log_info "Setting up .ssh/config..."
    echo "

Host github.com-pmd.github.io
        Hostname github.com
        IdentityFile=$HOME/.ssh/pmd.github.io_deploy_key

Host github.com-pmd-eclipse-plugin-p2-site
        Hostname github.com
        IdentityFile=$HOME/.ssh/pmd-eclipse-plugin-p2-site_deploy_key

Host pmd-code.org
        IdentityFile=$HOME/.ssh/pmd-code.org_deploy_key

Host web.sourceforge.net
        IdentityFile=$HOME/.ssh/web.sourceforge.net_deploy_key

Host git.code.sf.net
        IdentityFile=$HOME/.ssh/web.sourceforge.net_deploy_key

" > "$HOME/.ssh/config"

    pmd_ci_log_info "Setting up .ssh/known_hosts..."
    # cleanup old keys
    if [ -e "$HOME/.ssh/known_hosts" ]; then
        ssh-keygen -R web.sourceforge.net > /dev/null 2>&1
        ssh-keygen -R pmd-code.org > /dev/null 2>&1
        ssh-keygen -R github.com > /dev/null 2>&1
        ssh-keygen -R git.code.sf.net > /dev/null 2>&1
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
        # github.com ED25519 SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU
        # # Host github.com found: line 2
        # github.com RSA SHA256:uNiVztksCsDhcc0u9e8BujQXVUpKZIDTMczCvj3tD2s
        # # Host github.com found: line 3
        # github.com ECDSA SHA256:p2QAMXNIC1TJYWeIOttrVc98/R1BUFWu3/LiyKgUfQM
        # ssh-keygen -F github.com -f github_known_hosts
        echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
        echo 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk='
        echo 'github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg='

        #
        # git.code.sf.net (https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)
        #
        # ssh-keyscan git.code.sf.net | tee -a sf-git_known_hosts
        # ssh-keygen -F git.code.sf.net -l -f sf-git_known_hosts
        # # Host git.code.sf.net found: line 1 
        # git.code.sf.net RSA SHA256:3WhEqJaBPKb69eT5dfgYcPJTgqc9rq1Y9saZlXqkbWg
        # # Host git.code.sf.net found: line 2 
        # git.code.sf.net ECDSA SHA256:FeVkoYYBjuQzb5QVAgm3BkmeN5TTgL2qfmqz9tCPRL4
        # # Host git.code.sf.net found: line 3 
        # git.code.sf.net ED25519 SHA256:vDwNztsrZFViJXWpUTSKGo8cF6n79iKAURNiK68n/yE
        # ssh-keygen -F git.code.sf.net -f sf-git_known_hosts
        echo 'git.code.sf.net ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAoMesJ60dow5VqNsIqIQMBNmSYz6txSC5YSUXzPNWV4VIWTWdqbQoQuIu+oYGhBMoeaSWWCiVIDTwFDzQXrq8CwmyxWp+2TTuscKiOw830N2ycIVmm3ha0x6VpRGm37yo+z+bkQS3m/sE7bkfTU72GbeKufFHSv1VLnVy9nmJKFOraeKSHP/kjmatj9aC7Q2n8QzFWWjzMxVGg79TUs7sjm5KrtytbxfbLbKtrkn8OXsRy1ib9hKgOwg+8cRjwKbSXVrNw/HM+MJJWp9fHv2yzWmL8B6fKoskslA0EjNxa6d76gvIxwti89/8Y6xlhR0u65u1AiHTX9Q4BVsXcBZUDw=='
        echo 'git.code.sf.net ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPAa5MFfMaXyT3Trf/Av/laAvIhUzZJUnvPZAd9AC6bKWAhVl+A3s2+M6SlhF/Tn/W0akN03GyNviBtqJKtx0RU='
        echo 'git.code.sf.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGObtXLh/mZom0pXjE5Mu211O+JvtzolqdNKVA+XJ466'

    } >> "$HOME/.ssh/known_hosts"
}
