import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/services.dart';

class ExampleDriver {
  const ExampleDriver({
    required this.key,
    required this.scriptId,
    required this.version,
    required this.name,
    required this.connector,
    required this.description,
    required this.assetDirectory,
    this.globalBufferSize = 4096,
    this.mimeType = 'application/x-lua',
    this.script = '',
    this.imagePath = '',
    this.isBundled = true,
  });

  final String key;
  final int scriptId;
  final int version;
  final String name;
  final EdgezSensorConnector connector;
  final String description;
  final String assetDirectory;
  final int globalBufferSize;
  final String mimeType;
  final String script;
  final String imagePath;
  final bool isBundled;

  String get label => '$name [id=$scriptId, v=$version]';

  Future<EdgezSensorScriptConfig> loadScript() async {
    final source = script.isNotEmpty
        ? script
        : await rootBundle.loadString('$assetDirectory/driver.lua');
    return EdgezSensorScriptConfig(
      scriptId: scriptId,
      version: version,
      name: name,
      sensorType: key,
      connector: connector,
      script: source,
      globalBufferSize: globalBufferSize,
      mimeType: mimeType,
    );
  }

  factory ExampleDriver.fromInstalled(EdgezDriverBundle bundle) {
    return ExampleDriver(
      key: bundle.key,
      scriptId: bundle.scriptId,
      version: bundle.version,
      name: bundle.name,
      connector: bundle.connector,
      description: bundle.description,
      assetDirectory: '',
      globalBufferSize: bundle.globalBufferSize,
      mimeType: bundle.mimeType,
      script: bundle.script,
      imagePath: bundle.imagePath,
      isBundled: false,
    );
  }

  static ExampleDriver fromManifest(
    String directory,
    Map<String, Object?> manifest,
  ) {
    if (manifest['format'] != 'edgez-driver/v1') {
      throw const FormatException('Unsupported EdgeZ driver manifest');
    }
    return ExampleDriver(
      key: manifest['key'] as String,
      scriptId: manifest['scriptId'] as int,
      version: manifest['version'] as int,
      name: manifest['name'] as String,
      connector: manifest['interface'] == 'rs485'
          ? EdgezSensorConnector.rs485
          : EdgezSensorConnector.uartI2c,
      description: manifest['description'] as String? ?? '',
      assetDirectory: directory,
      globalBufferSize: manifest['globalBufferSize'] as int? ?? 4096,
      mimeType: manifest['bufferMimeType'] as String? ?? 'application/x-lua',
    );
  }
}

class ExampleDriverCatalog {
  static const bundled = <ExampleDriver>[
    ExampleDriver(
      key: '1003-1',
      scriptId: 1003,
      version: 2,
      name: 'Random Temperature (Sample)',
      connector: EdgezSensorConnector.uartI2c,
      description: 'Virtual test sensor that generates a random temperature '
          'value. No external hardware is required.',
      assetDirectory: 'assets/drivers/random-temperature',
    ),
    ExampleDriver(
      key: '1002-1',
      scriptId: 1002,
      version: 2,
      name: 'SHT3x Temperature/Humidity',
      connector: EdgezSensorConnector.uartI2c,
      description: 'Digital I2C sensor for temperature and relative humidity '
          'measurements. Uses address 0x44 by default and validates readings '
          'with CRC.',
      assetDirectory: 'assets/drivers/sht3x',
    ),
    ExampleDriver(
      key: '1004-1',
      scriptId: 1004,
      version: 2,
      name: 'VC0706 UART Camera',
      connector: EdgezSensorConnector.uartI2c,
      description: 'UART JPEG camera using the VC0706 command protocol. '
          'Captures still images and transfers the JPEG data through the '
          'script global buffer.',
      assetDirectory: 'assets/drivers/vc0706-camera',
      globalBufferSize: 32768,
      mimeType: 'image/jpeg',
    ),
    ExampleDriver(
      key: '2002-1',
      scriptId: 2002,
      version: 1,
      name: 'Flow Meter RS485',
      connector: EdgezSensorConnector.rs485,
      description: 'Industrial Modbus RTU flow meter that reports '
          'instantaneous flow rate and accumulated volume over RS485.',
      assetDirectory: 'assets/drivers/flow-meter-rs485',
    ),
    ExampleDriver(
      key: '2003-1',
      scriptId: 2003,
      version: 1,
      name: 'RS485 Vibration Sensor',
      connector: EdgezSensorConnector.rs485,
      description: 'Modbus RTU vibration sensor used to calculate a pass-by '
          'score from velocity and displacement measurements.',
      assetDirectory: 'assets/drivers/vibration-rs485',
    ),
  ];
}
