#!/usr/bin/env bash

set -e

if [ $# -ne 3 ]; then
    echo 'echo -e "Syntax error: missing parameters\neval \$(create-gh-actions.sh {pull_request\|push} user/repo branch_name)"'
    exit 1
fi

GITHUB_EVENT_PATH=/workspaces/event.json
cat > "$GITHUB_EVENT_PATH" <<EOF
{
    "number": 1,
    "compare": "https://github.com/${GITHUB_REPOSITORY}/compare/6113728f27ae...000000000000",
    "repository": {
        "clone_url": "https://github.com/${GITHUB_REPOSITORY}.git"
    }
}
EOF

if [[ "$3" == refs/* ]]; then
    ref="$3"
else
    ref="refs/heads/$3"
fi

echo "
export GITHUB_ACTIONS=true
export GITHUB_ACTION=1
export GITHUB_RUN_ID=1
export GITHUB_EVENT_NAME=\"$1\"
export GITHUB_EVENT_PATH=\"$GITHUB_EVENT_PATH\"
export GITHUB_REPOSITORY=\"$2\"
export GITHUB_REF=\"$ref\"
export GITHUB_BASE_REF=master
export MAVEN_OPTS=\"-Dmaven.wagon.httpconnectionManager.ttlSeconds=180 -Dmaven.wagon.http.retryHandler.count=3 -DskipRemoteStaging=true\"
"
