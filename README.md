# Example Provider

[![Build Status](https://travis-ci.com/pactflow/example-provider.svg?branch=master)](https://travis-ci.com/pactflow/example-provider)

This is an example of a Node provider using Pact and [Pactflow](https://pactflow.io) to ensure that it is compatible with the expectations its consumers have of it.

It is using a public tenant on Pactflow, which you can access [here](https://test.pact.dius.com.au) using the credentials `dXfltyFMgNOFZAxr8io9wJ37iUpY42M`/`O5AIZWxelWbLvqMd8PkAVycBJh2Psyg1`. The latest version of the Example Consumer/Example Provider pact is published [here](https://test.pact.dius.com.au/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest).

The build "pipeline" is simulated with a Makefile, and performs the following tasks:

* Upsert webhook to allow the verification to run whenever a consumer's contract changes
* Run unit tests
* Run pact verification tests (including publishing verification results)
* Check if we are safe to deploy (ie. has the pact content been successfully verified)
* Deploy
* Tag the deployed version

If the PACT_URL environment variable is set, then we know that this build has been triggered by a 'contract content changed' webhook, so we only run the pact verification tests for the pact at that URL (see the switch in the `ci` target of the [Makefile](Makefile) and the logic for setting up the `opts` in [product/product.pact.test.js](product/product.pact.test.js)). The switch in the Makefile is a bit of a hack because Travis only lets us have one pipeline per repository - usually you would define a completely separate job in your CI for the pact changed webhook.
