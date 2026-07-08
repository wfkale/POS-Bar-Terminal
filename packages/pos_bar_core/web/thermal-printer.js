/**
 * POS Bar thermal printer helpers for Chrome/Edge PWAs.
 * Web Bluetooth primary (tablets) + Web Serial fallback.
 * Tuned for Feasycom-style ESC/POS BLE printers (ROMESON QP160R / 0x18F0).
 */
(function (global) {
  'use strict';

  var activeSerialPort = null;
  var activeBtDevice = null;
  var activeBtCharacteristic = null;
  var activeBtWriteMode = null; // 'with' | 'without'
  var activeBtChunkSize = 20;
  var serialBaudRate = 9600;
  var writeQueue = Promise.resolve();

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
    '00002af1-0000-1000-8000-00805f9b34fb',
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

  function clearBtCache() {
    activeBtCharacteristic = null;
    activeBtWriteMode = null;
    activeBtChunkSize = 20;
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
        acceptAllDevices: true,
        optionalServices: BT_SERVICES,
      })
      .then(function (device) {
        activeBtDevice = device;
        clearBtCache();
        device.addEventListener('gattserverdisconnected', function () {
          // Characteristic handles are invalid after disconnect.
          clearBtCache();
        });
        return ensureBluetoothReady({ forceRediscover: true, probe: true }).then(function () {
          return {
            id: device.id || 'bt',
            name: device.name || 'Bluetooth thermal printer',
            transport: 'web_bluetooth',
          };
        });
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
    if (props.write) score += 3;
    if (props.writeWithoutResponse) score += 2;
    if (BT_CHARS.indexOf(uuid) !== -1) score += 5;
    if (uuid.indexOf('2af1') !== -1 || uuid.indexOf('ff02') !== -1 || uuid.indexOf('fff2') !== -1) {
      score += 4;
    }
    if (props.notify || props.indicate) score -= 1;
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

  function preferredModes(characteristic) {
    var props = characteristic.properties || {};
    var modes = [];
    // Android Chrome is happiest with classic writeValue (with response) for Feasycom.
    if (props.write) modes.push('with');
    if (props.writeWithoutResponse) modes.push('without');
    if (!modes.length) modes.push('with', 'without');
    return modes;
  }

  function tryWrite(characteristic, chunk, mode) {
    // Fresh copy — some Android stacks reject sliced SharedArrayBuffer views.
    var payload = new Uint8Array(chunk);

    if (mode === 'with') {
      // Prefer legacy writeValue — more reliable than writeValueWithResponse on Android Chrome.
      if (typeof characteristic.writeValue === 'function') {
        return characteristic.writeValue(payload);
      }
      if (typeof characteristic.writeValueWithResponse === 'function') {
        return characteristic.writeValueWithResponse(payload);
      }
      return Promise.reject(new Error('write-with-response not supported'));
    }

    if (typeof characteristic.writeValueWithoutResponse === 'function') {
      return characteristic.writeValueWithoutResponse(payload);
    }
    return Promise.reject(new Error('write-without-response not supported'));
  }

  function probeWrite(characteristic) {
    var init = new Uint8Array([0x1b, 0x40]);
    var modes = preferredModes(characteristic);
    var i = 0;

    function attempt() {
      if (i >= modes.length) {
        return Promise.reject(
          new Error('Bluetooth connected, but writing ESC/POS probe failed. Power-cycle printer BT and re-pair.')
        );
      }
      var mode = modes[i++];
      return tryWrite(characteristic, init, mode)
        .then(function () {
          activeBtWriteMode = mode;
          activeBtChunkSize = 20;
          return delay(40);
        })
        .catch(function () {
          return attempt();
        });
    }

    return attempt();
  }

  function writeChunks(characteristic, bytes) {
    // Default ATT MTU on Android is often 23 → 20 byte payload. Start safe.
    var chunkSize = activeBtChunkSize || 20;
    var mode = activeBtWriteMode || preferredModes(characteristic)[0] || 'with';
    var i = 0;
    var flipped = false;

    function writeAt(offset, useMode, size) {
      var end = Math.min(offset + size, bytes.length);
      var chunk = bytes.subarray(offset, end);
      return tryWrite(characteristic, chunk, useMode).then(function () {
        // Give the printer buffer time — QP160R / Feasycom get overwhelmed easily.
        return delay(useMode === 'without' ? 40 : 55);
      });
    }

    function next() {
      if (i >= bytes.length) {
        activeBtWriteMode = mode;
        activeBtChunkSize = chunkSize;
        return Promise.resolve();
      }
      return writeAt(i, mode, chunkSize)
        .then(function () {
          i += chunkSize;
          return next();
        })
        .catch(function (err) {
          var msg = String((err && err.name) || '') + ' ' + String((err && err.message) || err);
          var gattFail =
            msg.indexOf('NotSupported') !== -1 ||
            msg.indexOf('GATT') !== -1 ||
            msg.indexOf('InvalidState') !== -1 ||
            msg.indexOf('NetworkError') !== -1;

          if (!gattFail) throw err;

          if (!flipped) {
            flipped = true;
            mode = mode === 'with' ? 'without' : 'with';
            chunkSize = 20;
            return delay(80).then(function () {
              return writeAt(i, mode, chunkSize).then(function () {
                i += chunkSize;
                return next();
              });
            });
          }

          if (chunkSize > 10) {
            chunkSize = 10;
            return delay(100).then(next);
          }
          throw err;
        });
    }

    return next();
  }

  function ensureBluetoothReady(opts) {
    opts = opts || {};
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

    var mustRediscover = !!opts.forceRediscover || !activeBtCharacteristic;

    function connect() {
      if (gatt.connected) return Promise.resolve(gatt);
      // Old characteristic objects are invalid after a reconnect.
      clearBtCache();
      mustRediscover = true;
      return gatt.connect();
    }

    return connect()
      .then(function (server) {
        if (!mustRediscover && activeBtCharacteristic) return activeBtCharacteristic;
        return resolveBtCharacteristic(server).then(function (c) {
          if (!c) {
            throw new Error('No writable Bluetooth print characteristic found. Re-pair the printer.');
          }
          activeBtCharacteristic = c;
          return c;
        });
      })
      .then(function (characteristic) {
        if (!opts.probe && activeBtWriteMode) return characteristic;
        return probeWrite(characteristic).then(function () {
          return characteristic;
        });
      });
  }

  function enqueue(task) {
    var run = writeQueue.then(task, task);
    // Keep queue alive even if a job fails.
    writeQueue = run.catch(function () {});
    return run;
  }

  function printBluetooth(bytes) {
    return enqueue(function () {
      return ensureBluetoothReady({ forceRediscover: false, probe: !activeBtWriteMode })
        .then(function (characteristic) {
          return writeChunks(characteristic, bytes);
        })
        .catch(function (err) {
          var msg = String((err && err.name) || '') + ' ' + String((err && err.message) || err);
          var retryable =
            msg.indexOf('NotSupported') !== -1 ||
            msg.indexOf('GATT') !== -1 ||
            msg.indexOf('InvalidState') !== -1 ||
            msg.indexOf('NetworkError') !== -1 ||
            msg.indexOf('expired') !== -1;

          if (!retryable || !activeBtDevice || !activeBtDevice.gatt) throw enrichBtError(err);

          // Soft recovery: disconnect, wait, full rediscover + probe, then reprint.
          clearBtCache();
          try {
            if (activeBtDevice.gatt.connected) activeBtDevice.gatt.disconnect();
          } catch (_) {}

          return delay(400)
            .then(function () {
              return ensureBluetoothReady({ forceRediscover: true, probe: true });
            })
            .then(function (characteristic) {
              return writeChunks(characteristic, bytes);
            })
            .catch(function (err2) {
              throw enrichBtError(err2 || err);
            });
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
        ' — Forget printer, power-cycle printer Bluetooth, tap Connect Bluetooth, then Test print immediately without leaving this screen.'
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
    clearBtCache();
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
