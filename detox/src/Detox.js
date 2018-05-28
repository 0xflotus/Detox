const log = require('npmlog');
const Device = require('./devices/Device');
const IosDriver = require('./devices/IosDriver');
const SimulatorDriver = require('./devices/SimulatorDriver');
const EmulatorDriver = require('./devices/EmulatorDriver');
const AttachedAndroidDriver = require('./devices/AttachedAndroidDriver');
const argparse = require('./utils/argparse');
const configuration = require('./configuration');
const Client = require('./client/Client');
const DetoxServer = require('detox-server');
const URL = require('url').URL;
const _ = require('lodash');
const ArtifactsManager = require('./artifacts/ArtifactsManager');

log.level = argparse.getArgValue('loglevel') || 'info';
log.addLevel('wss', 999, {fg: 'blue', bg: 'black'}, 'wss');
log.heading = 'detox';

const DEVICE_CLASSES = {
  'ios.simulator': SimulatorDriver,
  'ios.none': IosDriver,
  'android.emulator': EmulatorDriver,
  'android.attached': AttachedAndroidDriver,
};

class Detox {
  constructor({deviceConfig, session}) {
    this.deviceConfig = deviceConfig;
    this.userSession = deviceConfig.session || session;
    this.client = null;
    this.device = null;
    this.artifactsManager = null;
  }

  async init(userParams) {
    const sessionConfig = await this._getSessionConfig();
    const defaultParams = {launchApp: true, initGlobals: true};
    const params = Object.assign(defaultParams, userParams || {});

    if (!this.userSession) {
      this.server = new DetoxServer(new URL(sessionConfig.server).port);
    }

    this.client = new Client(sessionConfig);
    await this.client.connect();

    const deviceClass = DEVICE_CLASSES[this.deviceConfig.type];

    if (!deviceClass) {
      throw new Error(`'${this.deviceConfig.type}' is not supported`);
    }

    const deviceDriver = new deviceClass(this.client);
    this.artifactsManager = new ArtifactsManager();
    this.artifactsManager.registerArtifactPlugins(deviceDriver.declareArtifactPlugins());
    this.device = new Device(this.deviceConfig, sessionConfig, deviceDriver);
    this.artifactsManager.subscribeToDeviceEvents(this.device);

    await this.device.prepare(params);

    if (params.initGlobals) {
      deviceDriver.exportGlobals();
      global.device = this.device;
    }

    await this.artifactsManager.onBeforeAll();
  }

  async cleanup() {
    if (this.artifactsManager) {
      await this.artifactsManager.onAfterAll();
    }

    if (this.client) {
      await this.client.cleanup();
    }

    if (this.device) {
      await this.device._cleanup();
    }

    if (this.server) {
      this.server.close();
    }

    if (argparse.getArgValue('cleanup') && this.device) {
      await this.device.shutdown();
    }
  }

  terminate() {
    this.artifactsManager.onTerminate();
  }

  async beforeEach(testSummary) {
    await this._handleAppCrashIfAny(testSummary.fullName);
    await this.artifactsManager.onBeforeEach(testSummary);
  }

  async afterEach(testSummary) {
    await this.artifactsManager.onAfterEach(testSummary);
    await this._handleAppCrashIfAny(testSummary.fullName);
  }

  async _handleAppCrashIfAny(testName) {
    const pendingAppCrash = this.client.getPendingCrashAndReset();

    if (pendingAppCrash) {
      log.error('', `App crashed in test '${testName}', here's the native stack trace: \n${pendingAppCrash}`);
      await this.device.launchApp({ newInstance: true });
    }
  }

  async _getSessionConfig() {
    const session = this.userSession || await configuration.defaultSession();

    configuration.validateSession(session);

    return session;
  }
}

module.exports = Detox;
