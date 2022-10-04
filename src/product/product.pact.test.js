require("dotenv").config();
const { Verifier } = require("@pact-foundation/pact");
const controller = require("./product.controller");
const Product = require("./product");

// Setup provider server to verify
const app = require("express")();
const authMiddleware = require("../middleware/auth.middleware");
app.use(authMiddleware);
app.use(require("./product.routes"));
const server = app.listen("8080");

describe("Pact Verification", () => {
  it("validates the expectations of ProductService", () => {
    const baseOpts = {
      logLevel: "INFO",
      providerBaseUrl: "http://localhost:8080",
      providerVersion: process.env.GIT_COMMIT,
      // providerVersionTags: process.env.GIT_BRANCH ? [process.env.GIT_BRANCH] : [], // the old way of publishing verification results with the tag property
      providerVersionBranch: process.env.GIT_BRANCH
        ? process.env.GIT_BRANCH
        : "", // the recommended way of publishing verification results with the branch property
      verbose: process.env.VERBOSE === "true",
    };

    // For builds triggered by a 'contract_content_changed' just verify the changed pact.
    // https://docs.pact.io/pact_broker/webhooks#the-contract-content-changed-event
    // For builds trigged by a 'contract_requiring_verification_published' webhook, verify the changed pact against latest of mainBranch and any version currently deployed to an environment
    // https://docs.pact.io/pact_broker/webhooks#using-webhooks-with-the-contract_requiring_verification_published-event
    // The URL will bave been passed in from the webhook to the CI job.
    const pactChangedOpts = {
      pactUrls: [process.env.PACT_URL],
    };

    // For 'normal' provider builds, fetch the the latest version from the main branch of each consumer, as specified by
    // the consumer's mainBranch property and all the currently deployed and currently released and supported versions of each consumer.
    // https://docs.pact.io/pact_broker/advanced_topics/consumer_version_selectors
    const fetchPactsDynamicallyOpts = {
      provider: "pactflow-example-provider",
      //consumerVersionTag: ['master', 'prod'], // the old way of specifying which pacts to verify if using tags
      // consumerVersionSelectors: [{ tag: 'master', latest: true }, { deployed: true } ], // the newer way of specifying which pacts to verify if using tags
      consumerVersionSelectors: [
        { mainBranch: true },
        { deployed: true },
      ], // the new way of specifying which pacts to verify if using branches (recommended)
      pactBrokerUrl: process.env.PACT_BROKER_BASE_URL,
      enablePending: false,
      includeWipPactsSince: undefined,
    };

    const stateHandlers = {
      "products exists": () => {
        controller.repository.products = new Map([
          ["10", new Product("10", "CREDIT_CARD", "28 Degrees", "v1")],
        ]);
      },
      "products exist": () => {
        controller.repository.products = new Map([
          ["10", new Product("10", "CREDIT_CARD", "28 Degrees", "v1")],
        ]);
      },
      "a product with ID 10 exists": () => {
        controller.repository.products = new Map([
          ["10", new Product("10", "CREDIT_CARD", "28 Degrees", "v1")],
        ]);
      },
      "a product with ID 11 does not exist": () => {
        controller.repository.products = new Map();
      },
    };

    const requestFilter = (req, res, next) => {
      if (!req.headers["authorization"]) {
        next();
        return;
      }
      req.headers["authorization"] = `Bearer ${new Date().toISOString()}`;
      next();
    };

    const opts = {
      ...baseOpts,
      ...(process.env.PACT_URL ? pactChangedOpts : fetchPactsDynamicallyOpts),
      stateHandlers: stateHandlers,
      requestFilter: requestFilter,
    };

    return new Verifier(opts)
      .verifyProvider()
      .then((output) => {
        console.log("Pact Verification Complete!");
        console.log(output);
      })
      .finally(() => {
        server.close();
      });
  });
});
