#!/bin/bash

function main() {
    env | sort

    gcloud_auth "$INPUT_GCP_SA_KEY" 

    get_secrets "$INPUT_SECRETS"
}

function gcloud_auth() {
    GCP_SA_KEY=$1
    PROJECT_ID=$(echo "$GCP_SA_KEY" | jq -r '.project_id')

    echo "Authenticating Service Account with gcloud..."
    mkdir -p /tmp/certs
    echo "$GCP_SA_KEY" > /tmp/certs/svc_account.json
    gcloud auth activate-service-account --key-file=/tmp/certs/svc_account.json --project "$PROJECT_ID" --no-user-output-enabled
}

function get_secrets() {
    KEYS=$1
    PREFIX=$(env_prefixer "$GITHUB_ACTION_REF" "$GITHUB_REF_TYPE")

    echo "Retrieving secrets from Secret Manager..."
    for KEY in ${KEYS//,/ }
    do
        echo "Retrieving secret for: $KEY"

        # https://cloud.google.com/secret-manager/docs/creating-and-accessing-secrets#access
        SECRET=$(gcloud secrets versions access latest --secret="$PREFIX$KEY" --format='get(payload.data)' | tr '_-' '/+' | base64 -d)

        if [ -z "$SECRET" ]; then
            exit 1
        fi

        echo "::add-mask::$SECRET"

        echo "::set-output name=$KEY::$SECRET"
    done
}

function env_prefixer() {
    REF=$(get_ref)

    PROD="PROD_"
    DEVELOP="DEVELOP_"

    # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    # Semver official doesn't work with Bash, used this modified version: https://gist.github.com/rverst/1f0b97da3cbeb7d93f4986df6e8e5695#gistcomment-3029858
    SEMVER_REGEX="^(v*0|v*[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$"
    RELEASE_REGEX="release/*"

    if [[ "$GITHUB_REF_TYPE" = 'branch' ]] && ([[ "$REF" = 'main' ]] || [[ "$REF" =~ $RELEASE_REGEX ]]); then
        echo "$PROD"
    elif [[ "$GITHUB_REF_TYPE" = 'tag' ]] && [[ "$REF" =~ $SEMVER_REGEX ]] && [[ $(get_tag_parent $REF) = 'true' ]]; then
        echo "$PROD"
    else
        echo "$DEVELOP"
    fi
}

function get_tag_parent() {
    TAG=$1

    GIT_REPO_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY.git"

    if [ -n "$INPUT_GHA_ACCESS_USER" ] && [ -n "$INPUT_GHA_ACCESS_TOKEN" ]; then 
        git config --global url."https://$INPUT_GHA_ACCESS_USER:$INPUT_GHA_ACCESS_TOKEN@github.com".insteadOf "https://github.com"
    fi

    git clone "$GIT_REPO_URL"

    cd ${GITHUB_REPOSITORY##*/}

    git fetch origin "refs/tags/$TAG"

    if [[ $(git branch -r --contains $(git rev-list -n 1 tags/$TAG) | egrep "origin/(main|release/*)") ]]; then
        echo "true"
    else 
        echo "false"
    fi
}

function get_ref() {
    if [[ "$GITHUB_EVENT_NAME" == 'pull_request' ]]; then
        echo "$GITHUB_HEAD_REF"
    else
        echo "$GITHUB_REF_NAME"
    fi
}

main "$@"; exit