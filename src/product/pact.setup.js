const controller = require("./product.controller");
const Product = require("./product");

const baseOpts = {
  logLevel: "debug",
  providerBaseUrl: "http://localhost:8080",
  providerVersion: process.env.GIT_COMMIT,
  providerVersionBranch: process.env.GIT_BRANCH, // the recommended way of publishing verification results with the branch property
  verbose: process.env.VERBOSE === "true",
};

// Setup provider server to verify

const setupServer = () => {
  const express = require('express');
  const app = express();
  const authMiddleware = require("../middleware/auth.middleware");
  app.use(express.json());
  app.use(authMiddleware);
  app.use(require("./product.routes"));
  const server = app.listen("8080");
  return server;
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
  if (req.method === "POST") {
    req['body']["foo"] = "v342234"
    req.headers['content-length'] = Buffer.byteLength(JSON.stringify(req.body))
  }
  next();
};

module.exports = {
  baseOpts,
  setupServer,
  stateHandlers,
  requestFilter,
};
