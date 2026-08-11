import 'dart:io';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rotates device logs by file size and restores the newest UI lines',
      () async {
    final directory = await Directory.systemTemp.createTemp('edgez-log-test-');
    addTearDown(() => directory.delete(recursive: true));
    final store = EdgezDeviceLogStore(
      directoryProvider: () async => directory,
      exportDirectoryProvider: () async =>
          Directory('${directory.path}/exports'),
      maxFileBytes: 10,
      maxFiles: 2,
      maxInMemoryLines: 2,
      standardFlushLineCount: 1,
    );

    await store.append('one');
    await store.append('two');
    await store.append('three');

    expect(await File('${directory.path}/device.log.1').readAsLines(),
        <String>['one', 'two']);
    expect(await File('${directory.path}/device.log').readAsLines(),
        <String>['three']);
    expect(await store.load(), <String>['two', 'three']);
    expect(
      await (await store.export()).readAsLines(),
      <String>['one', 'two', 'three'],
    );

    await store.clear();
    expect(await store.load(), isEmpty);
    expect(await File('${directory.path}/device.log').exists(), isFalse);
    expect(await File('${directory.path}/device.log.1').exists(), isFalse);
  });

  test('uses larger batches for debug and verbose logging', () async {
    final directory = await Directory.systemTemp.createTemp('edgez-log-batch-');
    addTearDown(() => directory.delete(recursive: true));
    final store = EdgezDeviceLogStore(
      directoryProvider: () async => directory,
      exportDirectoryProvider: () async =>
          Directory('${directory.path}/exports'),
      standardFlushLineCount: 2,
      debugFlushLineCount: 3,
      idleFlushInterval: Duration.zero,
    );

    expect(store.standardFlushLineCount, 2);
    expect(store.debugFlushLineCount, 3);

    await store.append('one', configuredLevel: EdgezDeviceLogLevel.info);
    expect(await File('${directory.path}/device.log').exists(), isFalse);

    await store.append('two', configuredLevel: EdgezDeviceLogLevel.info);
    expect(
      await File('${directory.path}/device.log').readAsLines(),
      <String>['one', 'two'],
    );

    await store.clear();
    await store.append('debug-one', configuredLevel: EdgezDeviceLogLevel.debug);
    await store.append('debug-two', configuredLevel: EdgezDeviceLogLevel.debug);
    expect(await File('${directory.path}/device.log').exists(), isFalse);

    await store.append('debug-three',
        configuredLevel: EdgezDeviceLogLevel.debug);
    expect(
      await File('${directory.path}/device.log').readAsLines(),
      <String>['debug-one', 'debug-two', 'debug-three'],
    );

    await store.append('pending-before-download',
        configuredLevel: EdgezDeviceLogLevel.verbose);
    expect(
      await (await store.export()).readAsLines(),
      <String>[
        'debug-one',
        'debug-two',
        'debug-three',
        'pending-before-download',
      ],
    );
  });
}
