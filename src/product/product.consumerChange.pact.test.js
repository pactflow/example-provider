require('dotenv').config();
const { Verifier } = require('@pact-foundation/pact');
const {
  baseOpts,
  setupServer,
  stateHandlers,
  requestFilter
} = require('./pact.setup');

describe('Pact Verification', () => {
  let server;
  beforeAll(() => {
    server = setupServer();
  });
  afterAll(() => {
    if (server) {
      server.close();
    }
  });
  it('validates the expectations of a contract required verification that has been published for this provider', () => {
    // For builds trigged by a 'contract_requiring_verification_published' webhook, verify the changed pact against latest of mainBranch and any version currently deployed to an environment
    // https://docs.pact.io/pact_broker/webhooks#using-webhooks-with-the-contract_requiring_verification_published-event
    // The URL will bave been passed in from the webhook to the CI job.

    if (!process.env.PACT_URL) {
      console.log('no pact url specified');
      return;
    }

    const opts = {
      ...baseOpts,
      pactUrls: [process.env.PACT_URL],
      stateHandlers: stateHandlers,
      requestFilter: requestFilter
    };

    return new Verifier(opts).verifyProvider().then(() => {
      console.log('Pact Verification Complete!');
    });
  });
});
