PACTICIPANT := "pactflow-example-provider"
GITHUB_REPO := "pactflow/example-provider"
PACT_CHANGED_WEBHOOK_UUID := "c76b601e-d66a-4eb1-88a4-6ebc50c0df8b"
CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID := "8ce63439-6b70-4e9b-8891-703d5ea2953c"
PACT_CLI="docker run --rm -v ${PWD}:${PWD} -e PACT_BROKER_BASE_URL -e PACT_BROKER_TOKEN pactfoundation/pact-cli"

.EXPORT_ALL_VARIABLES:
GIT_COMMIT?=$(shell git rev-parse HEAD)
GIT_BRANCH?=$(shell git rev-parse --abbrev-ref HEAD)
ENVIRONMENT?=production

# Only deploy from master (to production env) or test (to test env)
ifeq ($(GIT_BRANCH),master)
	ENVIRONMENT=production
	DEPLOY_TARGET=deploy
else
	ifeq ($(GIT_BRANCH),test)
		ENVIRONMENT=test
		DEPLOY_TARGET=deploy
	else
		DEPLOY_TARGET=no_deploy
	endif
endif

all: test

## ====================
## CI tasks
## ====================

ci: test can_i_deploy $(DEPLOY_TARGET)

# Run the ci target from a developer machine with the environment variables
# set as if it was on Github Actions.
# Use this for quick feedback when playing around with your workflows.
fake_ci: .env
	CI=true \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci

ci_webhook: .env
	npm run test:pact

fake_ci_webhook:
	CI=true \
	PACT_BROKER_PUBLISH_VERIFICATION_RESULTS=true \
	make ci_webhook

## =====================
## Build/test tasks
## =====================

test:
	npm run test

## =====================
## Deploy tasks
## =====================

deploy: deploy_app record_deployment

no_deploy:
	@echo "Not deploying as not on master branch"

can_i_deploy: .env
	"${PACT_CLI}" broker can-i-deploy --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --to-environment ${ENVIRONMENT}

deploy_app:
	@echo "Deploying to ${ENVIRONMENT}"

record_deployment: .env
	@"${PACT_CLI}" broker record_deployment --pacticipant ${PACTICIPANT} --version ${GIT_COMMIT} --environment ${ENVIRONMENT}

## =====================
## PactFlow set up tasks
## =====================

# export the GITHUB_TOKEN environment variable before running this
create_github_token_secret:
	curl -v -X POST ${PACT_BROKER_BASE_URL}/secrets \
	-H "Authorization: Bearer ${PACT_BROKER_TOKEN}" \
	-H "Content-Type: application/json" \
	-H "Accept: application/hal+json" \
	-d  "{\"name\":\"githubToken\",\"description\":\"Github token\",\"value\":\"${GITHUB_TOKEN}\"}"

create_or_update_contract_requiring_verification_published_webhook:
	"${PACT_CLI}" \
	  broker create-or-update-webhook \
	  "https://api.github.com/repos/${GITHUB_REPO}/dispatches" \
	  --header 'Content-Type: application/json' 'Accept: application/vnd.github.everest-preview+json' 'Authorization: Bearer $${user.githubToken}' \
	  --request POST \
	  --data '{ "event_type": "contract_requiring_verification_published","client_payload": { "pact_url": "$${pactbroker.pactUrl}", "sha": "$${pactbroker.providerVersionNumber}", "branch":"$${pactbroker.providerVersionBranch}" , "message": "Verify changed pact for $${pactbroker.consumerName} version $${pactbroker.consumerVersionNumber} branch $${pactbroker.consumerVersionBranch} by $${pactbroker.providerVersionNumber} ($${pactbroker.providerVersionDescriptions})" } }' \
	  --uuid ${CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID} \
	  --provider ${PACTICIPANT} \
	  --contract-requiring-verification-published \
	  --description "contract_requiring_verification_published for ${PACTICIPANT}"

test_contract_requiring_verification_published_webhook:
	@curl -v -X POST ${PACT_BROKER_BASE_URL}/webhooks/${CONTRACT_REQUIRING_VERIFICATION_PUBLISHED_WEBHOOK_UUID}/execute -H "Authorization: Bearer ${PACT_BROKER_TOKEN}"

## ======================
## Misc
## ======================

.env:
	touch .env