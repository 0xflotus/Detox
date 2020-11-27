const detox = require('detox');
const adapter = require('detox/runners/mocha/adapter');

before(async () => {
  await detox.init();
  await detox.launchApp({
    newInstance: true,
  });
});

beforeEach(async function () {
  await adapter.beforeEach(this);
});

afterEach(async function () {
  await adapter.afterEach(this);
});

after(async () => {
  await detox.cleanup();
});
