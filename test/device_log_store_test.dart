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
  });
}
