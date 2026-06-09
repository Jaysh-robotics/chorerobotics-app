/// BLE Service and Characteristic UUIDs — mirror of scripts/robot_server/config.py
/// Keep in sync with the robot's GATT server.
class BleUuids {
  static const String devicePrefix = 'ChoreBot-';

  // Services
  static const String serviceRobotInfo   = 'c40e0001-0001-1000-8000-00805f9b34fb';
  static const String servicePairing     = 'c40e0002-0001-1000-8000-00805f9b34fb';
  static const String serviceCommand     = 'c40e0003-0001-1000-8000-00805f9b34fb';
  static const String serviceTelemetry   = 'c40e0004-0001-1000-8000-00805f9b34fb';
  static const String serviceWifiConfig  = 'c40e0005-0001-1000-8000-00805f9b34fb';

  // Robot Info characteristics
  static const String charSerialNumber    = 'c40e0101-0001-1000-8000-00805f9b34fb';
  static const String charModel           = 'c40e0102-0001-1000-8000-00805f9b34fb';
  static const String charFirmwareVersion = 'c40e0103-0001-1000-8000-00805f9b34fb';
  static const String charRobotName       = 'c40e0104-0001-1000-8000-00805f9b34fb';
  static const String charAttachmentType  = 'c40e0105-0001-1000-8000-00805f9b34fb';

  // Pairing characteristics
  static const String charPairingState  = 'c40e0201-0001-1000-8000-00805f9b34fb';
  static const String charPairingCode   = 'c40e0202-0001-1000-8000-00805f9b34fb';
  static const String charPairingResult = 'c40e0203-0001-1000-8000-00805f9b34fb';
  static const String charPairingToken  = 'c40e0204-0001-1000-8000-00805f9b34fb';

  // Command characteristics
  static const String charDriveCommand = 'c40e0301-0001-1000-8000-00805f9b34fb';
  static const String charTaskCommand  = 'c40e0302-0001-1000-8000-00805f9b34fb';
  static const String charEstop        = 'c40e0303-0001-1000-8000-00805f9b34fb';
  static const String charCommandAck   = 'c40e0304-0001-1000-8000-00805f9b34fb';
  static const String charBladeControl = 'c40e0305-0001-1000-8000-00805f9b34fb';

  // Telemetry characteristics
  static const String charCoreTelemetry     = 'c40e0401-0001-1000-8000-00805f9b34fb';
  static const String charGpsPosition       = 'c40e0402-0001-1000-8000-00805f9b34fb';
  static const String charMotorSpeeds       = 'c40e0403-0001-1000-8000-00805f9b34fb';
  static const String charExtendedTelemetry = 'c40e0404-0001-1000-8000-00805f9b34fb';
  static const String charDiagnostics       = 'c40e0405-0001-1000-8000-00805f9b34fb';
  static const String charTaskProgress      = 'c40e0406-0001-1000-8000-00805f9b34fb';

  // WiFi Config characteristics
  static const String charWifiScan        = 'c40e0501-0001-1000-8000-00805f9b34fb';
  static const String charWifiCredentials = 'c40e0502-0001-1000-8000-00805f9b34fb';
  static const String charWifiStatus      = 'c40e0503-0001-1000-8000-00805f9b34fb';
  static const String charWifiIpAddress   = 'c40e0504-0001-1000-8000-00805f9b34fb';
}
