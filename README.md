# Example Provider

[![Build Status](https://travis-ci.com/pactflow/example-provider.svg?branch=master)](https://travis-ci.com/pactflow/example-provider)

This is an example of a Node provider that uses Pact, [Pactflow](https://pactflow.io) and Travis CI to ensure that it is compatible with the expectations its consumers have of it.

The project uses a Makefile to simulate a very simple build pipeline with two steps - test and deploy.

It is using a public tenant on Pactflow, which you can access [here](https://test.pact.dius.com.au) using the credentials `dXfltyFMgNOFZAxr8io9wJ37iUpY42M`/`O5AIZWxelWbLvqMd8PkAVycBJh2Psyg1`. The latest version of the Example Consumer/Example Provider pact is published [here](https://test.pact.dius.com.au/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest).

## Pact verifications

When using Pact in a CI/CD pipeline, there are two reasons for the pact verification to take place:

   * When the provider changes (to make sure it does not break any existing consumer expectations)
   * When a pact changes (to see if the provider is compatible with the new expectations)

When the provider changes, the pact verification runs as part the provider's normal build pipeline, generally after the unit tests, and before any deployment takes place. The pact verification task is configured to dynamically fetch all the relevant pacts for the specified provider from Pactflow, verify them, and publish the results back to Pactflow.

To ensure that a verification is also run whenever a pact changes, we create a webhook in Pactflow that triggers a provider build, and passes in the URL of the changed pact. Ideally, this should be a completely separate build from your normal provider pipeline, and it should just verify the changed pact.

Because Travis CI only allows us to have one build configuration per repository, we switch between the main pipeline mode and the webhook-triggered mode based on the presence of an environment variable that is only set via the webhook. Keep in mind that this is just a constraint of the tools we're using for this example, and is not necessarily the way you would implement Pact your own pipeline.

## Features

* In [.travis.yml](.travis.yml)
    * Our PACT_BROKER_TOKEN environment variable is encrypted. This is a read/write token. For normal development use, you would use a read only token, as you would not be publishing verification results from your local machine.
    * In the `script` section, we switch between running the target for the normal provider build pipeline, and the webhook-triggered pact verification target, based on whether or not the PACT_URL is set. The PACT_URL will be set when this build has been trigged by a 'contract content changed' webhook (more on this later). This switch is just required because Travis only lets us have one build configuration file per repository - usually you would define a completely separate job in your CI for the pact changed webhook.

* In the [Makefile](Makefile):
    * The target `create_or_update_travis_webhook` creates the Pactflow webhook that will trigger a build of the provider when any of its consumers publishes a pact with changed content.
    * To call the Travis API that triggers the build, the webhook uses a bearer token that is stored in a Pactflow secret called `${user.travisToken}`. The secret can be created using the `create_travis_token_secret` target, or through the Pactflow UI.
    * The target `ci_main_pipeline` runs when the provider has pushed a new commit. It performs the following tasks:
        * Run the isolated tests (including the pact verification tests, which publish the verification results)
        * If we are on master:
            * Check if we are safe to deploy to prod using `can-i-deploy` (ie. do we have a succesfully verified pact with the version of the consumer that is currently in production)
            * Deploy (just pretend!)
            * Tag the deployed application version as `prod` in Pactflow so Pactflow knows which version of the provider is in production when the consumer runs `can-i-deploy`.
    * The target `ci_verify` just runs the pact verification step, and is used when the build is triggered by the webhook.

* In [product/product.pact.test.js](product/product.pact.test.js):
    * When the `$PACT_URL` is not set (ie. the build is running because the provider changed), the provider is configured to fetch all the pacts for the 'example-provider' provider which belong to the latest consumer versions tagged with `master` and `prod`. This ensures the provider is compatible with the latest changes that the consumer has made, and is also backwards compatible with the production version of the consumer.
    * When the `$PACT_URL` is set (ie. the build is running because it was triggered by the 'contract content changed' webhook), we just verify the pact at the `${PACT_URL}`.
    * Pact-JS has a very flexible verification task configuration that allows us to use the same code for both the main pipeline verifications and the webhook-triggered verifications, with dynamically set options. Depending on your pact implementation, you may need to define separate tasks for each of these concerns.
    * When we publish the verification results, we use the git sha as the provider version number, and the branch name as the provider version tag. You can read more about versioning [here](https://docs.pact.io/getting_started/versioning_in_the_pact_broker).

## Usage

### Set up

TBC - flesh out each step.

1. Fork consumer and provider projects
1. Create a Pactflow account
1. Update the env vars with the new Pactflow account details
1. Set up Travis CI
    1. `travis login --pro`
    1. Encrypt new PACT_BROKER_TOKEN
1. Push consumer and provider repos
1. Create provider webhook

## Consumer changed workflow

TBC. Cover pending flag.

## Provider changed workflow

TBC.
