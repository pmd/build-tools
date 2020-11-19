#
# Configures maven.
# Needed for deploy to central (both snapshots and releases)
# and for signing the artifacts.
#
function pmd_ci_maven_setup_settings() {
    mkdir -p ${HOME}/.m2
    cp .ci/files/maven-settings.xml ${HOME}/.m2/settings.xml
}

function pmd_ci_maven_get_project_version() {
    # running once without -q to fetch needed dependencies and to be able to see any errors
    ./mvnw org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version
    
    RESULT=$(./mvnw org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version -q -DforceStdout)
}

function pmd_ci_maven_get_project_name() {
    # running once without -q to fetch needed dependencies and to be able to see any errors
    ./mvnw org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.name
    
    RESULT=$(./mvnw org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.name -q -DforceStdout)
}

function pmd_ci_maven_verify_version() {
    local -r version=$1
    if [ -z "${version}" ]; then
        log_error "version required"
        return 1
    fi

    if [[ "${version}" == *-SNAPSHOT && -z "$PMD_CI_BRANCH" ]]; then
        log_error "Invalid combination: snapshot version ${version} but no branch"
        return 1
    fi

    if [[ "${version}" != *-SNAPSHOT && -z "$PMD_CI_TAG" ]]; then
        log_error "Invalid combination: non-snapshot version ${version} but no tag"
        return 1
    fi
}