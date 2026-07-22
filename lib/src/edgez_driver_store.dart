import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

class EdgezDriverBundle {
  const EdgezDriverBundle({
    required this.driverId,
    required this.key,
    required this.scriptId,
    required this.version,
    required this.name,
    required this.connector,
    required this.script,
    this.description = '',
    this.globalBufferSize = 4096,
    this.mimeType = 'application/x-lua',
    this.imagePath = '',
    this.marketplaceItemId = '',
    this.marketplaceSlug = '',
  });

  final String driverId;
  final String key;
  final int scriptId;
  final int version;
  final String name;
  final EdgezSensorConnector connector;
  final String script;
  final String description;
  final int globalBufferSize;
  final String mimeType;
  final String imagePath;
  final String marketplaceItemId;
  final String marketplaceSlug;

  EdgezSensorScriptConfig toScriptConfig() => EdgezSensorScriptConfig(
        scriptId: scriptId,
        version: version,
        name: name,
        sensorType: key,
        connector: connector,
        script: script,
        globalBufferSize: globalBufferSize,
        mimeType: mimeType,
      );

  Map<String, Object?> toManifest({required bool hasImage}) => {
        'format': 'edgez-driver/v1',
        'driverId': driverId,
        'key': key,
        'scriptId': scriptId,
        'version': version,
        'name': name,
        'interface':
            connector == EdgezSensorConnector.rs485 ? 'rs485' : 'uart_i2c',
        'entrypoint': 'driver.lua',
        'description': description,
        'globalBufferSize': globalBufferSize,
        'bufferMimeType': mimeType,
        if (hasImage) 'image': 'image',
        if (marketplaceItemId.isNotEmpty)
          'marketplaceItemId': marketplaceItemId,
        if (marketplaceSlug.isNotEmpty) 'marketplaceSlug': marketplaceSlug,
      };
}

typedef EdgezDriverDirectoryProvider = Future<Directory> Function();

/// Persists downloaded driver bundles and returns the installed driver list.
///
/// Resolving marketplace links and downloading remote assets belongs to the
/// host application. The SDK only validates and stores the resulting bundle.
class EdgezDriverStore {
  EdgezDriverStore({EdgezDriverDirectoryProvider? directoryProvider})
      : _directoryProvider = directoryProvider ?? _defaultDirectory;

  final EdgezDriverDirectoryProvider _directoryProvider;

  Future<List<EdgezDriverBundle>> load() async {
    final root = await _directoryProvider();
    if (!await root.exists()) return const <EdgezDriverBundle>[];
    final drivers = <EdgezDriverBundle>[];
    await for (final driverEntity in root.list()) {
      if (driverEntity is! Directory) continue;
      await for (final versionEntity in driverEntity.list()) {
        if (versionEntity is! Directory) continue;
        try {
          final manifestFile = File('${versionEntity.path}/manifest.json');
          final scriptFile = File('${versionEntity.path}/driver.lua');
          final manifest = jsonDecode(await manifestFile.readAsString());
          if (manifest is! Map) continue;
          final bundle = _fromManifest(
            manifest.cast<String, Object?>(),
            await scriptFile.readAsString(),
            imagePath: await File('${versionEntity.path}/image').exists()
                ? '${versionEntity.path}/image'
                : '',
          );
          if (bundle != null) {
            _validate(bundle);
            drivers.add(bundle);
          }
        } catch (_) {
          // A broken or partially written bundle must not hide valid drivers.
        }
      }
    }
    drivers
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List<EdgezDriverBundle>.unmodifiable(drivers);
  }

  Future<EdgezDriverBundle> save(
    EdgezDriverBundle bundle, {
    Uint8List? imageBytes,
  }) async {
    _validate(bundle);
    final root = await _directoryProvider();
    final directory = Directory(
      '${root.path}/${bundle.driverId}/${bundle.version}',
    );
    await directory.create(recursive: true);

    final image = File('${directory.path}/image');
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final temporaryImage = File('${directory.path}/image.tmp');
      await temporaryImage.writeAsBytes(imageBytes, flush: true);
      if (await image.exists()) await image.delete();
      await temporaryImage.rename(image.path);
    } else if (await image.exists()) {
      await image.delete();
    }

    final script = File('${directory.path}/driver.lua');
    final temporaryScript = File('${directory.path}/driver.lua.tmp');
    await temporaryScript.writeAsString(bundle.script, flush: true);
    if (await script.exists()) await script.delete();
    await temporaryScript.rename(script.path);

    final manifest = File('${directory.path}/manifest.json');
    final temporaryManifest = File('${directory.path}/manifest.tmp');
    await temporaryManifest.writeAsString(
      jsonEncode(bundle.toManifest(hasImage: await image.exists())),
      flush: true,
    );
    if (await manifest.exists()) await manifest.delete();
    await temporaryManifest.rename(manifest.path);

    return EdgezDriverBundle(
      driverId: bundle.driverId,
      key: bundle.key,
      scriptId: bundle.scriptId,
      version: bundle.version,
      name: bundle.name,
      connector: bundle.connector,
      script: bundle.script,
      description: bundle.description,
      globalBufferSize: bundle.globalBufferSize,
      mimeType: bundle.mimeType,
      imagePath: await image.exists() ? image.path : '',
      marketplaceItemId: bundle.marketplaceItemId,
      marketplaceSlug: bundle.marketplaceSlug,
    );
  }

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/drivers');
  }

  EdgezDriverBundle? _fromManifest(
    Map<String, Object?> manifest,
    String script, {
    required String imagePath,
  }) {
    if (manifest['format'] != 'edgez-driver/v1' || script.trim().isEmpty) {
      return null;
    }
    final connector = switch (manifest['interface']) {
      'uart_i2c' => EdgezSensorConnector.uartI2c,
      'rs485' => EdgezSensorConnector.rs485,
      _ => null,
    };
    final scriptId = (manifest['scriptId'] as num?)?.toInt() ?? 0;
    final version = (manifest['version'] as num?)?.toInt() ?? 0;
    if (connector == null || scriptId <= 0 || version <= 0) return null;
    final key = (manifest['key'] as String?)?.trim();
    return EdgezDriverBundle(
      driverId: manifest['driverId'] as String? ?? '',
      key: key == null || key.isEmpty ? '$scriptId-$version' : key,
      scriptId: scriptId,
      version: version,
      name: manifest['name'] as String? ?? '$scriptId-$version',
      connector: connector,
      script: script,
      description: manifest['description'] as String? ?? '',
      globalBufferSize: (manifest['globalBufferSize'] as num?)?.toInt() ?? 4096,
      mimeType: manifest['bufferMimeType'] as String? ?? 'application/x-lua',
      imagePath: imagePath,
      marketplaceItemId: manifest['marketplaceItemId'] as String? ?? '',
      marketplaceSlug: manifest['marketplaceSlug'] as String? ?? '',
    );
  }

  void _validate(EdgezDriverBundle bundle) {
    final safeId = RegExp(r'^[A-Za-z0-9._-]+$');
    if (!safeId.hasMatch(bundle.driverId) ||
        bundle.key.trim().isEmpty ||
        bundle.scriptId <= 0 ||
        bundle.version <= 0 ||
        bundle.name.trim().isEmpty ||
        bundle.script.trim().isEmpty) {
      throw const FormatException('Driver bundle is incomplete or invalid');
    }
  }
}
