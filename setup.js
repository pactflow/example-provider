module.exports = async function (globalConfig, projectConfig) {
  console.log(globalConfig.testPathPattern);
  console.log(projectConfig.cache);

  
// Setup provider server to verify
  const app = require("express")();
  const authMiddleware = require("./src/middleware/auth.middleware");
  app.use(authMiddleware);
  app.use(require("./src/product/product.routes"));
  app.use(require("./src/user/user.routes"));
  const server = app.listen("8080");

  // Set reference to mongod in order to close the server during teardown.
  globalThis.__SERVER__ = server;
};