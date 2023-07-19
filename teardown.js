module.exports = async function (globalConfig, projectConfig) {
  console.log(globalConfig.testPathPattern);
  console.log(projectConfig.cache);

  globalThis.__SERVER__.close();
};