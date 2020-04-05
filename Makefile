PACTICIPANT := "pactflow-example-provider"
WEBHOOK_UUID := "c76b601e-d66a-4eb1-88a4-6ebc50c0df8b"

all: test

## CI tasks

# When a webhook triggers a build, the PACT_URL will be set. In this case, just run the verification step.
# Otherwise, run the normal build.
# This is just to get around the fact that Travis CI only has one pipeline per repository.
# Normally you would define a separate job for the webhook triggered verification.
ci:
	@if [ -z "${PACT_URL}" ]; then echo "Running main pipeline" && make ci_main_pipeline; else echo "Verifying pact from webhook" && make ci_verify; fi

ci_main_pipeline: docker_pull prepare_pactflow test
# Only deploy from master
	@if [ "${TRAVIS_BRANCH}" == 'master' ]; then make deploy; else echo "Not deploying as not on master branch"; fi

ci_verify: test

## Build/test tasks

docker_pull:
# Pulling before running just makes the output a bit cleaner
	@docker pull pactfoundation/pact-cli:latest

prepare_pactflow: create_or_update_travis_webhook

create_or_update_travis_webhook:
	@docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_USERNAME \
	 -e PACT_BROKER_PASSWORD \
	 -v ${PWD}:${PWD} \
	  pactfoundation/pact-cli:latest \
	  broker create-or-update-webhook \
	  https://api.travis-ci.com/repo/pactflow%2Fexample-provider/requests \
	  --header "Content-Type: application/json" "Accept: application/json" "Travis-API-Version: 3" 'Authorization: token $${user.travisToken}' \
	  --request POST \
	  --data @${PWD}/pactflow/travis-ci-webhook.json \
	  --uuid ${WEBHOOK_UUID} \
	  --provider ${PACTICIPANT} \
	  --contract-content-changed \
	  --description "Travis CI webhook for ${PACTICIPANT}"

test:
	npm run test:pact

## Deploy tasks

deploy: can_i_deploy deploy_app tag_as_prod

can_i_deploy:
	docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_USERNAME \
	 -e PACT_BROKER_PASSWORD \
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
	 -e PACT_BROKER_USERNAME \
	 -e PACT_BROKER_PASSWORD \
	  pactfoundation/pact-cli:latest \
	  broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${TRAVIS_COMMIT} \
	  --tag prod

## Manual tasks

test_travis_webhook:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/webhooks/${WEBHOOK_UUID}/execute -u ${PACT_BROKER_USERNAME}:${PACT_BROKER_PASSWORD}

# export TRAVIS_TOKEN first and run this once before you do anything
create_travis_token_secret:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-u ${PACT_BROKER_USERNAME}:${PACT_BROKER_PASSWORD} \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"travisToken\",\"description\":\"Travis CI Provider Build Token\",\"value\":\"${TRAVIS_TOKEN}\"}"
