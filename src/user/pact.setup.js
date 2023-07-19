const controller = require("./user.controller");
const User = require("./user");

const baseOpts = {
  logLevel: "INFO",
  providerBaseUrl: "http://localhost:8080",
  providerVersion: process.env.GIT_COMMIT,
  providerVersionBranch: process.env.GIT_BRANCH, // the recommended way of publishing verification results with the branch property
  verbose: process.env.VERBOSE === "true",
};

// Setup provider server to verify

const stateHandlers = {
  "a user with ID 0 does not exist": () => {
    controller.repository.users = new Map();
  },
  "a user with ID 1 does not exist": () => {
    controller.repository.users = new Map([
      ["1", new User("1", "user", "user@mxmv.uk", "hunter2")],
    ]);
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
