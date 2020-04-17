PACTICIPANT := "pactflow-example-provider"
WEBHOOK_UUID := "c76b601e-d66a-4eb1-88a4-6ebc50c0df8b"
TRIGGER_PROVIDER_BUILD_URL := "https://api.travis-ci.com/repo/pactflow%2Fexample-provider/requests"

# Only deploy from master
ifeq ($(TRAVIS_BRANCH),master)
	DEPLOY_TARGET=deploy
else
	DEPLOY_TARGET=no_deploy
endif

all: test

## ====================
## CI tasks
## ====================

ci_main_pipeline: test $(DEPLOY_TARGET)

ci_verify:
	npm run test:pact

## =====================
## Build/test tasks
## =====================

test:
	npm run test

## =====================
## Deploy tasks
## =====================

deploy: can_i_deploy deploy_app tag_as_prod

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_TOKEN \
	  pactfoundation/pact-cli:latest \
	  broker can-i-deploy \
	  --pacticipant ${PACTICIPANT} \
	  --version ${TRAVIS_COMMIT} \
	  --to prod

deploy_app:
	@echo "Deploying to prod"

tag_as_prod:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_TOKEN \
	  pactfoundation/pact-cli:latest \
	  broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${TRAVIS_COMMIT} \
	  --tag prod

## =====================
## Pactflow set up tasks
## =====================

# export the TRAVIS_TOKEN environment variable before running this
# You can get your token from the Settings tab of https://travis-ci.com/account/preferences
create_travis_token_secret:
	@curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"travisToken\",\"description\":\"Travis CI Provider Build Token\",\"value\":\"${TRAVIS_TOKEN}\"}"

# NOTE: the travis token secret must be created (either through the UI or using the
# `create_travis_token_secret` target) before the webhook is invoked.
create_or_update_travis_webhook:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_TOKEN \
	 -v ${PWD}:${PWD} \
	  pactfoundation/pact-cli:latest \
	  broker create-or-update-webhook \
	  "${TRIGGER_PROVIDER_BUILD_URL}" \
	  --header "Content-Type: application/json" "Accept: application/json" "Travis-API-Version: 3" 'Authorization: token $${user.travisToken}' \
	  --request POST \
	  --data @${PWD}/pactflow/travis-ci-webhook.json \
	  --uuid ${WEBHOOK_UUID} \
	  --provider ${PACTICIPANT} \
	  --contract-content-changed \
	  --description "Travis CI webhook for ${PACTICIPANT}"

test_travis_webhook:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_TOKEN \
	 -v ${PWD}:${PWD} \
	  pactfoundation/pact-cli:latest \
	  broker test-webhook \
	  --uuid ${WEBHOOK_UUID}

## ======================
## Travis CI set up tasks
## ======================

travis_login:
	@docker run --rm -v ${HOME}/.travis:/root/.travis -it lirantal/travis-cli login --pro

travis_encrypt_pact_broker_token:
	@docker run --rm -v ${HOME}/.travis:/root/.travis -v ${PWD}:${PWD} --workdir ${PWD} lirantal/travis-cli encrypt --pro PACT_BROKER_TOKEN="${PACT_BROKER_TOKEN}"
