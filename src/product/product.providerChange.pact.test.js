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
  it('validates the expectations of any consumers, by specified consumerVersionSelectors', () => {
    if (process.env.PACT_URL) {
      console.log('pact url specified, so this test should not run');
      return;
    }
    // For 'normal' provider builds, fetch the the latest version from the main branch of each consumer, as specified by
    // the consumer's mainBranch property and all the currently deployed and currently released and supported versions of each consumer.
    // https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors
    const fetchPactsDynamicallyOpts = {
      provider: 'pactflow-example-provider',
      consumerVersionSelectors: [
        { mainBranch: true },
        { deployed: true },
        { matchingBranch: true }
      ],
      pactBrokerUrl: process.env.PACT_BROKER_BASE_URL,
      // https://docs.pact.io/pact_broker/advanced_topics/pending_pacts
      enablePending: true,
      // https://docs.pact.io/pact_broker/advanced_topics/wip_pacts
      includeWipPactsSince: '2020-01-01'
    };

    const opts = {
      ...baseOpts,
      ...fetchPactsDynamicallyOpts,
      stateHandlers: stateHandlers,
      requestFilter: requestFilter
    };
    return new Verifier(opts).verifyProvider().then((output) => {
      console.log('Pact Verification Complete!');
    });
  });
});
