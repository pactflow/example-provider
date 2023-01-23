# Example Provider

[![Build Status](https://github.com/pactflow/example-provider/actions/workflows/build.yml/badge.svg)](https://github.com/pactflow/example-provider/actions)

[![Can I deploy Status](https://test.pactflow.io/pacticipants/pactflow-example-provider/branches/master/latest-version/can-i-deploy/to-environment/production/badge)](https://test.pactflow.io/pacticipants/pactflow-example-provider/branches/master/latest-version/can-i-deploy/to-environment/production/badge)

[![pactflow-example-provider/pactflow-example-consumer](https://test.pactflow.io/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest/master/badge.svg)](https://test.pactflow.io/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest/master)

This is an example of a Node provider that uses Pact, [PactFlow](https://pactflow.io) and Github Actions to ensure that it is compatible with the expectations its consumers have of it.

It is using a public tenant on PactFlow, which you can access [here](https://test.pactflow.io/) using the credentials `dXfltyFMgNOFZAxr8io9wJ37iUpY42M`/`O5AIZWxelWbLvqMd8PkAVycBJh2Psyg1`. The latest version of the Example PactFlow Consumer/Example PactFlow Provider pact is published [here](https://test.pactflow.io/overview/provider/pactflow-example-provider/consumer/pactflow-example-consumer).

## Pact verifications

When using Pact in a CI/CD pipeline, there are two reasons for a pact verification task to take place:

* When the provider changes (to make sure it does not break any existing consumer expectations)
* When a pact changes (to see if the provider is compatible with the new expectations)

When the provider changes, the pact verification task runs as part the provider's normal build pipeline, generally after the unit tests, and before any deployment takes place. This pact verification task is configured to dynamically fetch all the relevant pacts for the specified provider from PactFlow, verify them, and publish the results back to PactFlow.

To ensure that a verification is also run whenever a pact changes, we create a webhook in PactFlow that triggers a provider build, and passes in the URL of the changed pact, to verify it against the head and deployed/released versions of the provider. Ideally, this would be a completely separate build from your normal provider pipeline, and it should just verify the changed pact.

## Features

* In [.github/workflows/build.yml](.github/workflows/build.yml)
  * Our PACT_BROKER_TOKEN environment variable is set from a Github Secret. This is a read/write token. For normal development use, you would use a read only token, as you would not be publishing verification results from your local machine.
  
* In [.github/workflows/contract_requiring_verification_published.yml](.github/workflows/contract_requiring_verification_published.yml)
  * Recommended - This build is triggered by a webhook event, when a pact file changes and passes the url of the changed pact to the provider pact test to verify, as well as the branch and commit sha and checks out the provider codebase on the specified sha. See [here](https://docs.pact.io/pact_broker/webhooks#the-contract-requiring-verification-published-event) for details on the `contract_requiring_verification_published` webhook

* In the [Makefile](Makefile):
  * Using the [contract requiring verification published](https://docs.pact.io/pact_broker/webhooks#the-contract-requiring-verification-published-event) event
    * The target `create_or_update_contract_requiring_verification_published_webhook` creates the PactFlow webhook that will trigger a build of the provider when any of its consumers publishes a pact with changed content.
    * To call the Github API that triggers the build, the webhook uses a bearer token that is stored in a PactFlow secret called `${user.githubToken}`. The secret can be created using the `create_github_token_secret` target, or through the PactFlow UI.
    * The target `ci` runs when the provider has pushed a new commit. It performs the following tasks:
      * Run the isolated tests (including the pact verification tests, which publish the verification results)
      * If we are on master:
        * Check if we are safe to deploy to prod using `can-i-deploy` (ie. do we have a succesfully verified pact with the version of the consumer that is currently in production)
        * Deploy (just pretend!)
        * Record the deployed application version in PactFlow so PactFlow knows which version of the provider is in production when the consumer runs `can-i-deploy`.
    * The target `ci_webhook` just runs the pact verification step, and is used when the build is triggered by the webhook.
    * The target `create_or_update_contract_requiring_verification_published_webhook` creates the PactFlow webhook that will trigger a build of the provider when any of its consumers publishes a pact with changed content.
    * To call the Github API that triggers the build, the webhook uses a bearer token that is stored in a PactFlow secret called `${user.githubToken}`. The secret can be created using the `create_github_token_secret` target, or through the PactFlow UI.

* In [src/product/product.providerChange.pact.test.js](src/product/product.providerChange.pact.test.js):
  * When the `$PACT_URL` is not set (ie. the build is running because the provider changed), the provider is configured to fetch all the pacts for the 'example-provider' provider which belong to the latest consumer versions associated with their main branch and those currently deployed to an environment. This ensures the provider is compatible with the latest changes that the consumer has made, and is also backwards compatible with the production/test versions of the consumer.
  * When the `$PACT_URL` is set (ie. the build is running because it was triggered by the ['contract requiring verification published'](https://docs.pact.io/pact_broker/webhooks#the-contract-requiring-verification-published-event) webhook, we just verify the pact at the `$PACT_URL` against the head, test and production versions of the provider.
  * Pact-JS has a very flexible verification task configuration that allows us to use the same code for both the main pipeline verifications and the webhook-triggered verifications, with dynamically set options. Depending on your pact implementation, you may need to define separate tasks for each of these concerns.
  * When the verification results are published, the provider version number is set to the git sha, and the provider version branch is the git branch name. You can read more about versioning [here](https://docs.pact.io/getting_started/versioning_in_the_pact_broker).

## Usage

See the [PactFlow CI/CD Workshop](https://github.com/pactflow/ci-cd-workshop).
