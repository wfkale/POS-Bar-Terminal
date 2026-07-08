/**
 * POS Bar thermal printer helpers for Chrome/Edge PWAs.
 * Web Bluetooth (primary for tablets) + Web Serial fallback.
 * Tuned for Chinese ESC/POS BLE printers (Feasycom 0x18F0), e.g. ROMESON QP160R.
 */
(function (global) {
  'use strict';

  var activeSerialPort = null;
  var activeBtDevice = null;
  var activeBtCharacteristic = null;
  var activeBtWriteMode = null; // 'with' | 'without'
  var serialBaudRate = 9600;

  // Feasycom / Zijiang / Xprinter / generic Chinese ESC-POS BLE profiles.
  var BT_SERVICES = [
    '000018f0-0000-1000-8000-00805f9b34fb',
    '0000ff00-0000-1000-8000-00805f9b34fb',
    '0000fff0-0000-1000-8000-00805f9b34fb',
    '0000ffe0-0000-1000-8000-00805f9b34fb',
    '0000ae30-0000-1000-8000-00805f9b34fb',
    '49535343-fe7d-4ae5-8fa9-9fafd205e455',
    'e7810a71-73ac-3052-8f02-8672a9702000',
  ];

  var BT_CHARS = [
    '00002af1-0000-1000-8000-00805f9b34fb', // Feasycom print TX (most common)
    '0000ff02-0000-1000-8000-00805f9b34fb',
    '0000fff2-0000-1000-8000-00805f9b34fb',
    '0000ffe1-0000-1000-8000-00805f9b34fb',
    '0000ae01-0000-1000-8000-00805f9b34fb',
    '49535343-8841-43f4-a8d0-bb4475514411',
    '49535343-8841-43f4-a8d4-ecbe34729bb3',
    '49535343-1e4d-4bd9-ba61-23c647249616',
  ];

  function isSupported() {
    return !!(navigator.serial || navigator.bluetooth);
  }

  function toUint8Array(data) {
    if (data instanceof Uint8Array) return data;
    if (data instanceof ArrayBuffer) return new Uint8Array(data);
    if (ArrayBuffer.isView(data)) {
      return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
    }
    if (Array.isArray(data)) return new Uint8Array(data);
    if (data && typeof data.length === 'number') return new Uint8Array(data);
    throw new Error('Invalid print payload (expected bytes).');
  }

  function delay(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  function requestSerial() {
    if (!navigator.serial) {
      return Promise.reject(new Error('Web Serial not available. Use Chrome/Edge over HTTPS.'));
    }
    return navigator.serial.requestPort().then(function (port) {
      activeSerialPort = port;
      return openSerialPort(port).then(function () {
        var label = 'Serial thermal printer';
        try {
          var info = port.getInfo();
          if (info && info.usbProductId != null) {
            label = 'Serial printer (' + info.usbProductId + ')';
          }
        } catch (_) {}
        return { id: 'serial', name: label, transport: 'web_serial' };
      });
    });
  }

  function requestBluetooth() {
    if (!navigator.bluetooth) {
      return Promise.reject(new Error('Web Bluetooth not available. Use Chrome on Android/desktop (HTTPS).'));
    }
    return navigator.bluetooth
      .requestDevice({
        // acceptAllDevices works well on Android tablets; filters exclude some QP160R clones.
        acceptAllDevices: true,
        optionalServices: BT_SERVICES,
      })
      .then(function (device) {
        activeBtDevice = device;
        activeBtCharacteristic = null;
        activeBtWriteMode = null;
        device.addEventListener('gattserverdisconnected', function () {
          activeBtCharacteristic = null;
          activeBtWriteMode = null;
        });
        return device.gatt.connect().then(function (server) {
          return resolveBtCharacteristic(server).then(function (c) {
            if (!c) {
              throw new Error(
                'Paired, but no writable Bluetooth print characteristic was found. Forget the printer, put it in pairing mode, and try Connect Bluetooth again.'
              );
            }
            activeBtCharacteristic = c;
            return probeWrite(c).then(function () {
              return {
                id: device.id || 'bt',
                name: device.name || 'Bluetooth thermal printer',
                transport: 'web_bluetooth',
              };
            });
          });
        });
      });
  }

  /** Tiny ESC @ probe so we learn whether write-with-response works on this printer. */
  function probeWrite(characteristic) {
    var init = new Uint8Array([0x1b, 0x40]);
    return tryWrite(characteristic, init, 'with')
      .then(function () {
        activeBtWriteMode = 'with';
      })
      .catch(function () {
        return tryWrite(characteristic, init, 'without').then(function () {
          activeBtWriteMode = 'without';
        });
      })
      .catch(function (err) {
        throw new Error(
          'Bluetooth connected, but writing failed (' +
            ((err && err.name) || 'Error') +
            ': ' +
            ((err && err.message) || err) +
            '). Forget printer, power-cycle the printer, then Connect Bluetooth again.'
        );
      });
  }

  function openSerialPort(port) {
    if (port.readable && port.writable) return Promise.resolve(port);

    var rates = [serialBaudRate, 9600, 115200, 38400, 19200, 57600];
    var unique = [];
    rates.forEach(function (r) {
      if (unique.indexOf(r) === -1) unique.push(r);
    });

    var chain = Promise.reject(new Error('start'));
    unique.forEach(function (rate) {
      chain = chain.catch(function () {
        return port
          .open({ baudRate: rate, dataBits: 8, stopBits: 1, parity: 'none', bufferSize: 8192 })
          .then(function () {
            serialBaudRate = rate;
            return port;
          });
      });
    });
    return chain.catch(function (err) {
      var msg = String(err && err.message ? err.message : err).toLowerCase();
      if (msg.indexOf('open') !== -1 || msg.indexOf('already') !== -1) return port;
      throw err;
    });
  }

  function ensureSerialPort() {
    if (activeSerialPort) return openSerialPort(activeSerialPort);
    if (!navigator.serial) {
      return Promise.reject(new Error('Web Serial not available.'));
    }
    return navigator.serial.getPorts().then(function (ports) {
      if (!ports || !ports.length) {
        throw new Error('Serial printer disconnected. Reconnect in Printer settings.');
      }
      activeSerialPort = ports[0];
      return openSerialPort(activeSerialPort);
    });
  }

  function printSerial(bytes) {
    return ensureSerialPort().then(function (port) {
      if (!port.writable) {
        throw new Error('Serial port is not writable. Reconnect in Printer settings.');
      }
      var writer = port.writable.getWriter();
      return writer
        .write(bytes)
        .then(function () {
          return writer.ready;
        })
        .then(function () {
          return delay(120);
        })
        .then(function () {
          writer.releaseLock();
        })
        .catch(function (err) {
          try {
            writer.releaseLock();
          } catch (_) {}
          throw err;
        });
    });
  }

  function isWritableCharacteristic(characteristic) {
    try {
      var props = characteristic.properties || {};
      return !!(props.write || props.writeWithoutResponse);
    } catch (_) {
      return false;
    }
  }

  function scoreCharacteristic(characteristic) {
    var props = characteristic.properties || {};
    var uuid = String(characteristic.uuid || '').toLowerCase();
    var score = 0;
    if (props.write) score += 3; // prefer write-with-response for Feasycom / QP160R
    if (props.writeWithoutResponse) score += 1;
    if (BT_CHARS.indexOf(uuid) !== -1) score += 5;
    if (uuid.indexOf('2af1') !== -1 || uuid.indexOf('ff02') !== -1 || uuid.indexOf('fff2') !== -1) score += 4;
    if (props.notify || props.indicate) score -= 1; // status chars less useful for print
    return score;
  }

  function tryKnownCharacteristics(service) {
    var inner = Promise.resolve(null);
    BT_CHARS.forEach(function (cid) {
      inner = inner.then(function (found) {
        if (found) return found;
        return service.getCharacteristic(cid).then(
          function (c) {
            return isWritableCharacteristic(c) ? c : null;
          },
          function () {
            return null;
          }
        );
      });
    });
    return inner;
  }

  function bestWritableCharacteristic(service) {
    return service.getCharacteristics().then(
      function (chars) {
        var best = null;
        var bestScore = -1;
        for (var i = 0; i < chars.length; i++) {
          if (!isWritableCharacteristic(chars[i])) continue;
          var s = scoreCharacteristic(chars[i]);
          if (s > bestScore) {
            bestScore = s;
            best = chars[i];
          }
        }
        return best;
      },
      function () {
        return null;
      }
    );
  }

  function resolveBtCharacteristic(server) {
    var chain = Promise.resolve(null);
    BT_SERVICES.forEach(function (svc) {
      chain = chain.then(function (found) {
        if (found) return found;
        return server.getPrimaryService(svc).then(
          function (service) {
            return tryKnownCharacteristics(service).then(function (c) {
              return c || bestWritableCharacteristic(service);
            });
          },
          function () {
            return null;
          }
        );
      });
    });

    return chain.then(function (found) {
      if (found) return found;
      return server.getPrimaryServices().then(
        function (services) {
          var walk = Promise.resolve(null);
          services.forEach(function (service) {
            walk = walk.then(function (c) {
              if (c) return c;
              return tryKnownCharacteristics(service).then(function (known) {
                return known || bestWritableCharacteristic(service);
              });
            });
          });
          return walk;
        },
        function () {
          return null;
        }
      );
    });
  }

  function tryWrite(characteristic, chunk, mode) {
    // Always pass a fresh Uint8Array — ArrayBuffer views sometimes trigger NotSupportedError.
    var payload = chunk instanceof Uint8Array ? chunk : new Uint8Array(chunk);
    var props = characteristic.properties || {};

    if (mode === 'with') {
      if (characteristic.writeValueWithResponse) {
        return characteristic.writeValueWithResponse(payload);
      }
      if (props.write || characteristic.writeValue) {
        return characteristic.writeValue(payload);
      }
      return Promise.reject(new Error('write-with-response not supported'));
    }

    if (characteristic.writeValueWithoutResponse) {
      return characteristic.writeValueWithoutResponse(payload);
    }
    if (props.writeWithoutResponse && characteristic.writeValue) {
      return characteristic.writeValue(payload);
    }
    return Promise.reject(new Error('write-without-response not supported'));
  }

  function writeChunks(characteristic, bytes) {
    // Feasycom default in @point-of-sale/webbluetooth-receipt-printer is 100 bytes + writeWithResponse.
    var chunkSize = 100;
    var mode = activeBtWriteMode || 'with';
    var i = 0;

    function writeAt(offset, useMode) {
      var end = Math.min(offset + chunkSize, bytes.length);
      var chunk = bytes.slice(offset, end); // fresh Uint8Array
      return tryWrite(characteristic, chunk, useMode).then(function () {
        return delay(useMode === 'without' ? 20 : 30);
      });
    }

    function next() {
      if (i >= bytes.length) return Promise.resolve();
      return writeAt(i, mode)
        .then(function () {
          i += chunkSize;
          return next();
        })
        .catch(function (err) {
          var msg = String((err && err.name) || '') + ' ' + String((err && err.message) || err);
          var gattFail =
            msg.indexOf('NotSupported') !== -1 ||
            msg.indexOf('GATT') !== -1 ||
            msg.indexOf('InvalidState') !== -1;

          if (!gattFail) throw err;

          // Flip write mode once, shrink chunk, retry same offset.
          var alt = mode === 'with' ? 'without' : 'with';
          if (mode === activeBtWriteMode || !activeBtWriteMode) {
            mode = alt;
            activeBtWriteMode = alt;
            if (chunkSize > 20) chunkSize = 20;
            return delay(60).then(function () {
              return writeAt(i, mode).then(function () {
                i += chunkSize;
                return next();
              });
            });
          }

          if (chunkSize > 20) {
            chunkSize = 20;
            return delay(60).then(next);
          }
          throw err;
        });
    }

    return next();
  }

  function ensureBluetoothReady() {
    if (!activeBtDevice) {
      return Promise.reject(
        new Error(
          'Bluetooth session expired after reload. Tap Connect Bluetooth again (Chrome requires a user gesture).'
        )
      );
    }
    var gatt = activeBtDevice.gatt;
    if (!gatt) {
      return Promise.reject(new Error('Bluetooth GATT not available on this device.'));
    }

    function connect() {
      return gatt.connected ? Promise.resolve(gatt) : gatt.connect();
    }

    return connect().then(function (server) {
      if (activeBtCharacteristic) return activeBtCharacteristic;
      return resolveBtCharacteristic(server).then(function (c) {
        if (!c) {
          throw new Error('No writable Bluetooth print characteristic found. Re-pair the printer.');
        }
        activeBtCharacteristic = c;
        return c;
      });
    });
  }

  function printBluetooth(bytes) {
    return ensureBluetoothReady()
      .then(function (characteristic) {
        return writeChunks(characteristic, bytes);
      })
      .catch(function (err) {
        var msg = String((err && err.name) || '') + ' ' + String((err && err.message) || err);
        var retryable =
          msg.indexOf('NotSupported') !== -1 ||
          msg.indexOf('GATT') !== -1 ||
          msg.indexOf('InvalidState') !== -1 ||
          msg.indexOf('NetworkError') !== -1;

        if (!retryable || !activeBtDevice || !activeBtDevice.gatt) throw enrichBtError(err);

        // Soft recovery: drop cache, reconnect, rediscover, retry once.
        activeBtCharacteristic = null;
        activeBtWriteMode = null;
        try {
          if (activeBtDevice.gatt.connected) activeBtDevice.gatt.disconnect();
        } catch (_) {}

        return delay(300)
          .then(ensureBluetoothReady)
          .then(function (characteristic) {
            return probeWrite(characteristic).then(function () {
              return writeChunks(characteristic, bytes);
            });
          })
          .catch(function (err2) {
            throw enrichBtError(err2 || err);
          });
      });
  }

  function enrichBtError(err) {
    var name = (err && err.name) || 'Error';
    var message = (err && err.message) || String(err);
    if (String(message).indexOf('Connect Bluetooth') !== -1) return err;
    return new Error(
      name +
        ': ' +
        message +
        ' — Tip: forget printer here, turn printer BT off/on, then tap Connect Bluetooth again while staying on this screen.'
    );
  }

  function printBytes(data, transport) {
    var bytes = toUint8Array(data);
    if (!bytes.length) {
      return Promise.reject(new Error('Print payload is empty.'));
    }
    var mode = String(transport || '');
    if (mode === 'web_serial') return printSerial(bytes);
    if (mode === 'web_bluetooth') return printBluetooth(bytes);
    return Promise.reject(new Error('Unknown printer transport: ' + mode));
  }

  function printBase64(base64, transport) {
    try {
      var binary = atob(String(base64 || ''));
      var bytes = new Uint8Array(binary.length);
      for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
      return printBytes(bytes, transport);
    } catch (e) {
      return Promise.reject(new Error('Invalid print payload (base64).'));
    }
  }

  function forget() {
    activeBtCharacteristic = null;
    activeBtWriteMode = null;
    if (activeBtDevice && activeBtDevice.gatt && activeBtDevice.gatt.connected) {
      try {
        activeBtDevice.gatt.disconnect();
      } catch (_) {}
    }
    activeBtDevice = null;
    if (activeSerialPort) {
      var port = activeSerialPort;
      activeSerialPort = null;
      try {
        if (port.readable || port.writable) {
          return port.close().catch(function () {});
        }
      } catch (_) {}
    }
    return Promise.resolve();
  }

  global.PosBarPrinter = {
    isSupported: isSupported,
    requestSerial: requestSerial,
    requestBluetooth: requestBluetooth,
    printBytes: printBytes,
    printBase64: printBase64,
    forget: forget,
  };
})(window);
