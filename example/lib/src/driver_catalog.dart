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
  ];
}
