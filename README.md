# Example Provider

This is an example of a Node provider that uses Pact, [Pactflow](https://pactflow.io) and Github Actions to ensure that it is compatible with the expectations its consumers have of it.

## Pact verifications

When using Pact in a CI/CD pipeline, there are two reasons for a pact verification task to take place:

   * When the provider changes (to make sure it does not break any existing consumer expectations)
   * When a pact changes (to see if the provider is compatible with the new expectations)

When the provider changes, the pact verification task runs as part the provider's normal build pipeline, generally after the unit tests, and before any deployment takes place. This pact verification task is configured to dynamically fetch all the relevant pacts for the specified provider from Pactflow, verify them, and publish the results back to Pactflow.

To ensure that a verification is also run whenever a pact changes, we create a webhook in Pactflow that triggers a provider build, and passes in the URL of the changed pact. Ideally, this would be a completely separate build from your normal provider pipeline, and it should just verify the changed pact.

## Features

* In [.github/workflows/build.yml](.github/workflows/build.yml)
    * Our PACT_BROKER_TOKEN environment variable is set from a Github Secret. This is a read/write token. For normal development use, you would use a read only token, as you would not be publishing verification results from your local machine.

* In the [Makefile](Makefile):
    * The target `create_or_update_pact_changed_webhook` creates the Pactflow webhook that will trigger a build of the provider when any of its consumers publishes a pact with changed content.
    * To call the Github API that triggers the build, the webhook uses a bearer token that is stored in a Pactflow secret called `${user.githubToken}`. The secret can be created using the `create_github_token_secret` target, or through the Pactflow UI.
    * The target `ci` runs when the provider has pushed a new commit. It performs the following tasks:
        * Run the isolated tests (including the pact verification tests, which publish the verification results)
        * If we are on master:
            * Check if we are safe to deploy to prod using `can-i-deploy` (ie. do we have a succesfully verified pact with the version of the consumer that is currently in production)
            * Deploy (just pretend!)
            * Record the deployed application version in Pactflow so Pactflow knows which version of the provider is in production when the consumer runs `can-i-deploy`.
    * The target `ci_webhook` just runs the pact verification step, and is used when the build is triggered by the webhook.

* In [src/product/product.pact.test.js](src/product/product.pact.test.js):
    * When the `$PACT_URL` is not set (ie. the build is running because the provider changed), the provider is configured to fetch all the pacts for the 'example-provider' provider which belong to the latest consumer versions tagged with `master` and those currently deployed to an environment. This ensures the provider is compatible with the latest changes that the consumer has made, and is also backwards compatible with the production/test versions of the consumer.
    * When the `$PACT_URL` is set (ie. the build is running because it was triggered by the 'contract content changed' webhook), we just verify the pact at the `$PACT_URL`.
    * Pact-JS has a very flexible verification task configuration that allows us to use the same code for both the main pipeline verifications and the webhook-triggered verifications, with dynamically set options. Depending on your pact implementation, you may need to define separate tasks for each of these concerns.
    * When the verification results are published, the provider version number is set to the git sha, and the provider version tag is the git branch name. You can read more about versioning [here](https://docs.pact.io/getting_started/versioning_in_the_pact_broker).

## Usage

See the [Pactflow CI/CD Workshop](https://github.com/pactflow/ci-cd-workshop).
