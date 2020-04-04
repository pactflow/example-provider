PACTICIPANT := "pactflow-example-provider"
WEBHOOK_UUID := "c76b601e-d66a-4eb1-88a4-6ebc50c0df8b"

all: setup_webhook test deploy

# export TRAVIS_TOKEN first and run this once before you do anything
create_travis_token_secret:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-u ${PACT_BROKER_USERNAME}:${PACT_BROKER_PASSWORD} \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"travisToken\",\"description\":\"Travis CI Provider Build Token\",\"value\":\"${TRAVIS_TOKEN}\"}"

setup_webhook:
	docker run --rm \
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

test_webhook:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/webhooks/${WEBHOOK_UUID}/execute -u ${PACT_BROKER_USERNAME}:${PACT_BROKER_PASSWORD}

test:
	npm run test:pact

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
	echo "Deploying to prod"

tag_as_prod:
	docker run --rm \
	 -e PACT_BROKER_BASE_URL \
	 -e PACT_BROKER_USERNAME \
	 -e PACT_BROKER_PASSWORD \
	  pactfoundation/pact-cli:latest \
	  broker create-version-tag \
	  --pacticipant ${PACTICIPANT} \
	  --version ${TRAVIS_COMMIT} \
	  --tag prod

deploy: can_i_deploy deploy_app tag_as_prod
