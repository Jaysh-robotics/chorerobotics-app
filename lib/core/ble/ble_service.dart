import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_uuids.dart';

class DiscoveredRobot {
  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;

  DiscoveredRobot({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });

  int get signalBars {
    if (rssi >= -55) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }
}

class RobotInfo {
  final String serial;
  final String model;
  final String firmware;
  final String name;
  final String attachment;

  RobotInfo({
    required this.serial,
    required this.model,
    required this.firmware,
    required this.name,
    required this.attachment,
  });
}

enum PairingResultCode { pending, success, failed, timeout }

class BleService {
  BluetoothDevice? _connected;
  final Map<String, BluetoothCharacteristic> _chars = {};
  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<bool> ensurePermissions() async {
    // iOS handles BLE permission via Info.plist at first use.
    if (!Platform.isAndroid) return true;

    // Android 12+ (API 31+): BLUETOOTH_SCAN + BLUETOOTH_CONNECT are the
    // only runtime perms (the "Nearby devices" prompt). Location is NOT
    // required because our manifest declares neverForLocation.
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    if (scan.isGranted && connect.isGranted) return true;

    // Older Android (11 and below) needs ACCESS_FINE_LOCATION for scans.
    // If scan perm isn't even applicable on this OS version, try location.
    final loc = await Permission.locationWhenInUse.request();
    return loc.isGranted || loc.isLimited;
  }

  Future<void> ensureBluetoothOn() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported on this device.');
    }
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  /// Scan for ChoreBot robots. Matches by advertised Pairing service UUID
  /// (reliable across platforms) OR device name prefix (works on Android/Linux
  /// peripherals).
  Stream<DiscoveredRobot> scanForRobots({
    Duration timeout = const Duration(seconds: 15),
  }) async* {
    await ensureBluetoothOn();

    final controller = StreamController<DiscoveredRobot>();
    final seen = <String, DiscoveredRobot>{};

    bool isChoreBot(ScanResult r) {
      final name = r.device.platformName;
      final advName = r.advertisementData.advName;
      // Match by device name or advertised name prefix.
      if (name.startsWith(BleUuids.devicePrefix) ||
          advName.startsWith(BleUuids.devicePrefix)) {
        return true;
      }
      // Fallback: match by advertised service UUID (macOS bless often
      // strips the local name but always includes service UUIDs).
      for (final svc in r.advertisementData.serviceUuids) {
        final s = svc.str128.toLowerCase();
        if (s == BleUuids.servicePairing ||
            s == BleUuids.serviceRobotInfo ||
            s == BleUuids.serviceCommand) {
          return true;
        }
      }
      return false;
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        // Debug every scanned device — surfaces in `flutter logs`.
        developer.log(
          '[BLE scan] ${r.device.remoteId.str} '
          'name="${r.device.platformName}" '
          'advName="${r.advertisementData.advName}" '
          'rssi=${r.rssi} '
          'services=${r.advertisementData.serviceUuids.map((u) => u.str128).join(",")}',
          name: 'chorerobotics.ble',
        );
        if (!isChoreBot(r)) continue;
        final id = r.device.remoteId.str;
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : 'ChoreBot-${id.substring(0, 6)}');
        final robot = DiscoveredRobot(
          id: id,
          name: name,
          rssi: r.rssi,
          device: r.device,
        );
        final prev = seen[id];
        if (prev == null || prev.rssi != r.rssi) {
          seen[id] = robot;
          controller.add(robot);
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidScanMode: AndroidScanMode.lowLatency,
        // No withServices filter — we match client-side so missing service
        // UUIDs in the advertisement (macOS bless quirk) don't hide the robot.
      );
    } catch (e) {
      controller.addError(e);
    }

    await for (final robot in controller.stream.timeout(
      timeout,
      onTimeout: (sink) => sink.close(),
    )) {
      yield robot;
    }

    await stopScan();
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  Future<RobotInfo> connect(DiscoveredRobot robot) async {
    await stopScan();
    await robot.device.connect(
      timeout: const Duration(seconds: 15),
      autoConnect: false,
    );
    _connected = robot.device;

    // Discover services
    final services = await robot.device.discoverServices();

    _chars.clear();
    for (final svc in services) {
      for (final c in svc.characteristics) {
        _chars[c.uuid.str128.toLowerCase()] = c;
      }
    }

    // Read robot info
    final serial     = await _readString(BleUuids.charSerialNumber);
    final model      = await _readString(BleUuids.charModel);
    final firmware   = await _readString(BleUuids.charFirmwareVersion);
    final name       = await _readString(BleUuids.charRobotName);
    final attachment = await _readString(BleUuids.charAttachmentType);

    return RobotInfo(
      serial: serial,
      model: model,
      firmware: firmware,
      name: name,
      attachment: attachment,
    );
  }

  /// Subscribe to pairing state changes. Emits raw state bytes (LED state code).
  Stream<int> pairingStateStream() {
    final c = _chars[BleUuids.charPairingState.toLowerCase()];
    if (c == null) throw Exception('Pairing state characteristic not found');
    return _subscribe(c).map((data) => data.isEmpty ? -1 : data[0]);
  }

  /// Subscribe to pairing result (1=success, 2=failed, 3=timeout).
  Stream<PairingResultCode> pairingResultStream() {
    final c = _chars[BleUuids.charPairingResult.toLowerCase()];
    if (c == null) throw Exception('Pairing result characteristic not found');
    return _subscribe(c).map((data) {
      if (data.isEmpty) return PairingResultCode.pending;
      switch (data[0]) {
        case 1:
          return PairingResultCode.success;
        case 2:
          return PairingResultCode.failed;
        case 3:
          return PairingResultCode.timeout;
        default:
          return PairingResultCode.pending;
      }
    });
  }

  /// Read the pairing token after a successful pairing. Returns an empty
  /// string if the characteristic is unavailable or empty.
  Future<String> readPairingToken() async {
    final c = _chars[BleUuids.charPairingToken.toLowerCase()];
    if (c == null) return '';
    try {
      final data = await c.read();
      return utf8.decode(data, allowMalformed: true).trim();
    } catch (_) {
      return '';
    }
  }

  Future<void> sendPairingCode(String code) async {
    final c = _chars[BleUuids.charPairingCode.toLowerCase()];
    if (c == null) throw Exception('Pairing code characteristic not found');
    await c.write(utf8.encode(code), withoutResponse: false);
  }

  Future<void> disconnect() async {
    try {
      await _connected?.disconnect();
    } catch (_) {}
    _connected = null;
    _chars.clear();
  }

  // Internal helpers
  Future<String> _readString(String uuid) async {
    final c = _chars[uuid.toLowerCase()];
    if (c == null) return '';
    try {
      final data = await c.read();
      return utf8.decode(data, allowMalformed: true).trim();
    } catch (_) {
      return '';
    }
  }

  Stream<List<int>> _subscribe(BluetoothCharacteristic c) async* {
    await c.setNotifyValue(true);
    yield* c.onValueReceived;
  }
}
