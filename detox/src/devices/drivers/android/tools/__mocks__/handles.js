const DeviceHandle = require('../DeviceHandle');
const EmulatorHandle = require('../EmulatorHandle');

const mockAvdName = 'mockAvdName';
class MockEmulatorHandle extends EmulatorHandle {
  queryName() {
    return Promise.resolve(mockAvdName);
  }
}

const emulator5556 = new MockEmulatorHandle('emulator-5556\tdevice');
const emulator5558 = new MockEmulatorHandle('emulator-5558\tdevice');
const emulator5560 = new MockEmulatorHandle('emulator-5560\tdevice');
const localhost5555 = new DeviceHandle('localhost:5555\tdevice');
const ip5557 = new DeviceHandle('192.168.4.19:5557\tdevice');

module.exports = {
  mockAvdName,
  emulator5556,
  emulator5558,
  emulator5560,
  localhost5555,
  ip5557,
};
