const controller = require("./product.controller");
const Product = require("./product");

const baseOpts = {
  logLevel: "INFO",
  providerBaseUrl: "http://localhost:8080",
  providerVersion: process.env.GIT_COMMIT,
  providerVersionBranch: process.env.GIT_BRANCH, // the recommended way of publishing verification results with the branch property
  verbose: process.env.VERBOSE === "true",
};


const stateHandlers = {
  "products exist": () => {
    controller.repository.products = new Map([
      ["09", new Product("09", "CREDIT_CARD", "Gem Visa", "v1")],
      ["10", new Product("10", "CREDIT_CARD", "28 Degrees", "v1")],
      ["13", new Product("13", "PERSONAL_LOAN", "MyFlexiPay", "v2")],
      ["12", new Product("12", "PERSONAL_LOAN", "Monzo", "v2")],
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

module.exports = {
  baseOpts,
  stateHandlers,
  requestFilter,
};
