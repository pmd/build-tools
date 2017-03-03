#!/bin/bash
set -ev

if [ "$TRAVIS_PULL_REQUEST" != "false" ] || [ "${TRAVIS_SECURE_ENV_VARS}" != "true" ]; then
    echo "Not setting up secrets (TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST} TRAVIS_SECURE_ENV_VARS=${TRAVIS_SECURE_ENV_VARS})."
    exit 0
fi


openssl aes-256-cbc -K $encrypted_cb4f24b6413c_key -iv $encrypted_cb4f24b6413c_iv -in .travis/release-signing-key-82DE7BE82166E84E.gpg.enc -out .travis/release-signing-key-82DE7BE82166E84E.gpg -d

mkdir -p "$HOME/.gpg"
gpg --batch --import .travis/release-signing-key-82DE7BE82166E84E.gpg
rm .travis/release-signing-key-82DE7BE82166E84E.gpg
