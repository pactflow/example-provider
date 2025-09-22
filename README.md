# Example Provider

[![Build Status](https://github.com/pactflow/example-provider/actions/workflows/build.yml/badge.svg)](https://github.com/pactflow/example-provider/actions)

[![Can I deploy Status](https://test.pactflow.io/pacticipants/pactflow-example-provider/branches/master/latest-version/can-i-deploy/to-environment/production/badge)](https://test.pactflow.io/pacticipants/pactflow-example-provider/branches/master/latest-version/can-i-deploy/to-environment/production/badge)

[![pactflow-example-provider/pactflow-example-consumer](https://test.pactflow.io/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest/master/badge.svg)](https://test.pactflow.io/pacts/provider/pactflow-example-provider/consumer/pactflow-example-consumer/latest/master)

This is an example of a Node provider that uses Pact, [PactFlow](https://pactflow.io) and Github Actions to ensure that it is compatible with the expectations its consumers have of it.

It is using a public tenant on PactFlow, which you can access [here](https://test.pactflow.io/) using the credentials `dXfltyFMgNOFZAxr8io9wJ37iUpY42M`/`O5AIZWxelWbLvqMd8PkAVycBJh2Psyg1`. The latest version of the Example PactFlow Consumer/Example PactFlow Provider pact is published [here](https://test.pactflow.io/matrix/provider/pactflow-example-provider/consumer/pactflow-example-consumer).

## Pactflow Onboarding

To simplify the onboarding tutorial, we have created `workshop/pactflow` branch on top of the existing functionality. It's to simplify the onboarding tutorial, allowing user to verify a contract without the use of Makefile. If you want to do a full workshop, please refer to the `main` branch to avoid unnecessary setups.

### Verify contract

This is the second part of the onboarding tutorial. We will verify a published contract in [public tenant](https://test.pactflow.io) on PactFlow. To be able to do it from local environment, you will need to export the following environment variables into your shell:

* `PACT_BROKER_TOKEN`: a valid [API token](https://docs.pactflow.io/#configuring-your-api-token) for PactFlow
* `PACT_URL`: a fully qualified domain name with protocol of public tenant `https://test.pactflow.io`
* `GIT_COMMIT`: git SHA which being used as provider version
* `GIT_BRANCH`: git branch which being used as provider branch

Alternatively, you can create a `.env` file at the project root folder and put the variables in. ie: 

```
PACT_URL=https://test.pactflow.io
PACT_BROKER_TOKEN=<<whatever-the-token-you-found>>
GIT_COMMIT="$(git rev-parse HEAD)"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD)" 
```

Please note it's `PACT_URL`, not `PACT_BROKER_BASE_URL` as specified in [example-consumer](https://github.com/pactflow/example-consumer/tree/workshop/pactflow). Although they are refering to the same thing.

Once you have the environment variables setup, you can verify the contract using the following npm command
```
npm run verify_pacts
```
