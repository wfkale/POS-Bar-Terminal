/**
 * POS Bar thermal printer helpers for Chrome/Edge PWAs.
 * Supports Web Serial (USB / USB-Bluetooth dongles) and Web Bluetooth (BLE printers).
 * Targets 80mm paper (~72mm printable width) ESC/POS printers.
 */
(function (global) {
  'use strict';

  var activeSerialPort = null;
  var activeBtDevice = null;
  var activeBtCharacteristic = null;

  var BT_SERVICES = [
    '000018f0-0000-1000-8000-00805f9b34fb',
    '0000ff00-0000-1000-8000-00805f9b34fb',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455',
  ];
  var BT_CHARS = [
    '00002af1-0000-1000-8000-00805f9b34fb',
    '0000ff02-0000-1000-8000-00805f9b34fb',
    '49535343-8841-43f4-a8d0-bb4475514411',
    '49535343-1e4d-4bd9-ba61-23c647249616',
  ];

  function isSupported() {
    return !!(navigator.serial || navigator.bluetooth);
  }

  function requestSerial() {
    if (!navigator.serial) {
      return Promise.reject(new Error('Web Serial not available. Use Chrome/Edge over HTTPS.'));
    }
    return navigator.serial.requestPort().then(function (port) {
      activeSerialPort = port;
      var label = 'Serial thermal printer';
      try {
        var info = port.getInfo();
        if (info && info.usbProductId) {
          label = 'Serial printer (' + info.usbProductId + ')';
        }
      } catch (_) {}
      return { id: 'serial', name: label, transport: 'web_serial' };
    });
  }

  function requestBluetooth() {
    if (!navigator.bluetooth) {
      return Promise.reject(new Error('Web Bluetooth not available. Use Chrome on Android (HTTPS).'));
    }
    return navigator.bluetooth
      .requestDevice({
        acceptAllDevices: true,
        optionalServices: BT_SERVICES,
      })
      .then(function (device) {
        activeBtDevice = device;
        activeBtCharacteristic = null;
        return {
          id: device.id || 'bt',
          name: device.name || 'Bluetooth thermal printer',
          transport: 'web_bluetooth',
        };
      });
  }

  function ensureSerialPort() {
    if (activeSerialPort) return Promise.resolve(activeSerialPort);
    if (!navigator.serial) {
      return Promise.reject(new Error('Web Serial not available.'));
    }
    return navigator.serial.getPorts().then(function (ports) {
      if (!ports || !ports.length) {
        throw new Error('Serial printer disconnected. Reconnect in Printer settings.');
      }
      activeSerialPort = ports[0];
      return activeSerialPort;
    });
  }

  function printSerial(bytes) {
    return ensureSerialPort().then(function (port) {
      return port
        .open({ baudRate: 9600 })
        .catch(function (err) {
          // Already open is fine on some browsers.
          if (String(err).indexOf('open') === -1) throw err;
        })
        .then(function () {
          var writer = port.writable.getWriter();
          return writer
            .write(bytes)
            .then(function () {
              writer.releaseLock();
              return port.close().catch(function () {});
            })
            .catch(function (err) {
              try {
                writer.releaseLock();
              } catch (_) {}
              throw err;
            });
        });
    });
  }

  function resolveBtCharacteristic(server) {
    var chain = Promise.resolve(null);
    BT_SERVICES.forEach(function (svc) {
      chain = chain.then(function (found) {
        if (found) return found;
        return server
          .getPrimaryService(svc)
          .then(function (service) {
            var inner = Promise.resolve(null);
            BT_CHARS.forEach(function (cid) {
              inner = inner.then(function (c) {
                if (c) return c;
                return service.getCharacteristic(cid).catch(function () {
                  return null;
                });
              });
            });
            return inner;
          })
          .catch(function () {
            return null;
          });
      });
    });
    return chain;
  }

  function writeChunks(characteristic, bytes) {
    var chunkSize = 180;
    var i = 0;
    function next() {
      if (i >= bytes.length) return Promise.resolve();
      var end = Math.min(i + chunkSize, bytes.length);
      var chunk = bytes.slice(i, end);
      i = end;
      var write = characteristic.writeValueWithoutResponse
        ? characteristic.writeValueWithoutResponse(chunk)
        : characteristic.writeValue(chunk);
      return Promise.resolve(write).then(next);
    }
    return next();
  }

  function printBluetooth(bytes) {
    if (!activeBtDevice) {
      return Promise.reject(
        new Error('Bluetooth printer disconnected. Reconnect in Printer settings (requires a tap).')
      );
    }
    var gatt = activeBtDevice.gatt;
    if (!gatt) {
      return Promise.reject(new Error('Bluetooth GATT not available.'));
    }
    return gatt
      .connect()
      .then(function (server) {
        if (activeBtCharacteristic) return activeBtCharacteristic;
        return resolveBtCharacteristic(server).then(function (c) {
          if (!c) {
            throw new Error(
              'No writable print characteristic found. Try Web Serial (USB or USB-BT adapter).'
            );
          }
          activeBtCharacteristic = c;
          return c;
        });
      })
      .then(function (characteristic) {
        return writeChunks(characteristic, bytes);
      });
  }

  function printBytes(data, transport) {
    var bytes = data instanceof Uint8Array ? data : new Uint8Array(data);
    if (transport === 'web_serial') return printSerial(bytes);
    if (transport === 'web_bluetooth') return printBluetooth(bytes);
    return Promise.reject(new Error('Unknown printer transport: ' + transport));
  }

  global.PosBarPrinter = {
    isSupported: isSupported,
    requestSerial: requestSerial,
    requestBluetooth: requestBluetooth,
    printBytes: printBytes,
  };
})(window);
