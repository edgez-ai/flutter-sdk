import 'dart:io';
import 'dart:typed_data';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late EdgezDriverStore store;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'edgez-driver-store-',
    );
    store = EdgezDriverStore(
      directoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('saves and lists an installed marketplace driver', () async {
    const bundle = EdgezDriverBundle(
      driverId: 'ai.edgez.test-driver',
      key: '3001-1',
      scriptId: 3001,
      version: 1,
      name: 'Test Driver',
      connector: EdgezSensorConnector.rs485,
      script: 'return { temperature = 21 }',
      description: 'Installed from the marketplace',
      marketplaceItemId: '12345678-1234-1234-1234-123456789abc',
      marketplaceSlug: 'test-driver',
    );

    final saved = await store.save(
      bundle,
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    final loaded = await store.load();

    expect(saved.imagePath, isNotEmpty);
    expect(loaded, hasLength(1));
    expect(loaded.single.driverId, bundle.driverId);
    expect(loaded.single.key, bundle.key);
    expect(loaded.single.script, bundle.script);
    expect(loaded.single.connector, EdgezSensorConnector.rs485);
    expect(loaded.single.imagePath, isNotEmpty);
    expect(loaded.single.toScriptConfig().sensorType, bundle.key);
  });

  test('rejects unsafe or incomplete driver bundles', () async {
    expect(
      () => store.save(
        const EdgezDriverBundle(
          driverId: '../escape',
          key: '1-1',
          scriptId: 1,
          version: 1,
          name: 'Unsafe',
          connector: EdgezSensorConnector.uartI2c,
          script: 'return {}',
        ),
      ),
      throwsFormatException,
    );
  });
}
