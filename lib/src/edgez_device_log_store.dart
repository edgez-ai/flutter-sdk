import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

typedef EdgezDeviceLogDirectoryProvider = Future<Directory> Function();
typedef EdgezDeviceLogExportDirectoryProvider = Future<Directory> Function();

/// A durable, size-rotated log for device firmware output.
///
/// The active file rotates at [maxFileBytes] (10 MiB by default) and numbered
/// backups retain earlier output. Serializing operations prevents concurrent
/// transport events from interleaving writes. Loading returns only the newest
/// [maxInMemoryLines] entries for the UI.
class EdgezDeviceLogStore {
  EdgezDeviceLogStore({
    this.maxFileBytes = 10 * 1024 * 1024,
    this.maxFiles = 5,
    this.maxInMemoryLines = 500,
    this.standardFlushLineCount = 100,
    this.debugFlushLineCount = 250,
    this.idleFlushInterval = const Duration(seconds: 1),
    EdgezDeviceLogDirectoryProvider? directoryProvider,
    EdgezDeviceLogExportDirectoryProvider? exportDirectoryProvider,
  })  : _directoryProvider = directoryProvider ?? _defaultDirectory,
        _exportDirectoryProvider =
            exportDirectoryProvider ?? _defaultExportDirectory;

  final int maxFileBytes;
  final int maxFiles;
  final int maxInMemoryLines;
  final int standardFlushLineCount;
  final int debugFlushLineCount;
  final Duration idleFlushInterval;
  final EdgezDeviceLogDirectoryProvider _directoryProvider;
  final EdgezDeviceLogExportDirectoryProvider _exportDirectoryProvider;
  Future<void> _tail = Future<void>.value();
  final List<String> _pendingLines = <String>[];
  Timer? _idleFlushTimer;

  int _flushLineCount(EdgezDeviceLogLevel configuredLevel) {
    return configuredLevel == EdgezDeviceLogLevel.debug ||
            configuredLevel == EdgezDeviceLogLevel.verbose
        ? debugFlushLineCount
        : standardFlushLineCount;
  }

  Future<List<String>> load() => _enqueue(() async {
        await _flushPending();
        final directory = await _directoryProvider();
        final lines = <String>[];
        for (var index = maxFiles - 1; index >= 0; index--) {
          final file = _file(directory, index);
          if (await file.exists()) {
            lines.addAll(await file.readAsLines());
          }
        }
        return List<String>.unmodifiable(_tailLines(lines));
      });

  Future<void> append(
    String line, {
    EdgezDeviceLogLevel configuredLevel = EdgezDeviceLogLevel.info,
  }) =>
      _enqueue(() async {
        _pendingLines.add(line);
        if (_pendingLines.length >= _flushLineCount(configuredLevel)) {
          await _flushPending();
        } else {
          _scheduleIdleFlush();
        }
      });

  /// Persists records that have not yet reached their configured level's
  /// normal batch size.
  Future<void> flush() => _enqueue(_flushPending);

  /// Deletes the active log and every rotated backup.
  Future<void> clear() => _enqueue(() async {
        _idleFlushTimer?.cancel();
        _idleFlushTimer = null;
        _pendingLines.clear();
        final directory = await _directoryProvider();
        for (var index = 0; index < maxFiles; index++) {
          final file = _file(directory, index);
          if (await file.exists()) await file.delete();
        }
      });

  /// Combines the current log and its rotated backups into one export file.
  Future<File> export() => _enqueue(() async {
        await _flushPending();
        final sourceDirectory = await _directoryProvider();
        final exportDirectory = await _exportDirectoryProvider();
        await exportDirectory.create(recursive: true);
        final timestamp = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .replaceAll('.', '-');
        final output =
            File('${exportDirectory.path}/device-log-$timestamp.log');
        final temporary = File('${output.path}.tmp');
        final sink = temporary.openWrite();
        try {
          for (var index = maxFiles - 1; index >= 0; index--) {
            final source = _file(sourceDirectory, index);
            if (await source.exists()) {
              await sink.addStream(source.openRead());
            }
          }
        } finally {
          await sink.close();
        }
        await temporary.rename(output.path);
        return output;
      });

  File _file(Directory directory, int index) {
    final suffix = index == 0 ? '' : '.$index';
    return File('${directory.path}/device.log$suffix');
  }

  Future<void> _rotate(Directory directory) async {
    for (var index = maxFiles - 1; index >= 1; index--) {
      final destination = _file(directory, index);
      if (await destination.exists()) await destination.delete();
      final source = _file(directory, index - 1);
      if (await source.exists()) await source.rename(destination.path);
    }
  }

  void _scheduleIdleFlush() {
    if (_idleFlushTimer != null || idleFlushInterval <= Duration.zero) return;
    _idleFlushTimer = Timer(idleFlushInterval, () {
      _idleFlushTimer = null;
      unawaited(flush());
    });
  }

  Future<void> _flushPending() async {
    _idleFlushTimer?.cancel();
    _idleFlushTimer = null;
    if (_pendingLines.isEmpty) return;

    final lines = List<String>.of(_pendingLines);
    _pendingLines.clear();
    final directory = await _directoryProvider();
    await directory.create(recursive: true);
    final file = _file(directory, 0);
    final bytes = utf8.encode('${lines.join('\n')}\n');
    if (await file.exists() &&
        (await file.length()) + bytes.length > maxFileBytes) {
      await _rotate(directory);
    }
    await _file(directory, 0).writeAsBytes(
      bytes,
      mode: FileMode.append,
      flush: true,
    );
  }

  List<String> _tailLines(List<String> lines) {
    if (lines.length <= maxInMemoryLines) return lines;
    return lines.sublist(lines.length - maxInMemoryLines);
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final scheduled = _tail.then((_) => operation());
    _tail = scheduled.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return scheduled;
  }

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/logs');
  }

  static Future<Directory> _defaultExportDirectory() async {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return Directory('${downloads.path}/EdgeZ');
    }
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/EdgeZ/Downloads');
  }
}
