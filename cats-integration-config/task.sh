#!/bin/bash
set -xeu

build_dir=${PWD}

export CONFIG
original_config="$PWD/cats-concourse-task/${CONFIG_FILE_PATH}"

cats_integration_configuration=$(
jq -n \
--arg api $CF_API \
--arg apps_domain $APPS_DOMAIN \
--arg admin_user $ADMIN_USER \
--arg admin_password $ADMIN_PASSWORD \
--arg skip_ssl_validation $SKIP_SSL_VALIDATION \
--arg include_apps $INCLUDE_APPS \
'
{
  "api": "$api",
  "apps_domain": "$apps_domain",
  "admin_user": "$admin_user",
  "admin_password": "$admin_password",
  "skip_ssl_validation": $skip_ssl_validation,
  "include_apps": $include_apps
}
'
)

echo $cats_integration_configuration > $original_config

if ${CAPTURE_LOGS}; then
  CONFIG=$(mktemp)
  jq ".artifacts_directory=\"${build_dir}/cats-trace-output\"" ${original_config} > ${CONFIG}
else
  CONFIG=${original_config}
fi

CF_GOPATH=/go/src/github.com/cloudfoundry/

echo "Moving cf-acceptance-tests onto the gopath..."
mkdir -p $CF_GOPATH
cp -R cf-acceptance-tests $CF_GOPATH

cd /go/src/github.com/cloudfoundry/cf-acceptance-tests

export CF_DIAL_TIMEOUT=11

export CF_PLUGIN_HOME=$HOME

./bin/test \
-keepGoing \
-randomizeAllSpecs \
-skipPackage=helpers \
-slowSpecThreshold=120 \
-nodes="${NODES}" \
-skip="${SKIP_REGEXP}" \
-flakeAttempts=2 \
-noisySkippings=false
