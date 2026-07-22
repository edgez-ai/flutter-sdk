import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class ExampleDatabase {
  Database? _database;

  Future<void> open() async {
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      '$databasesPath/edgez_example.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE nodes (
            node_num INTEGER PRIMARY KEY,
            user_uuid TEXT NOT NULL,
            display_name TEXT NOT NULL,
            route TEXT NOT NULL,
            last_seen_ms INTEGER NOT NULL,
            marker TEXT NOT NULL,
            public_key BLOB NOT NULL DEFAULT X'',
            latitude REAL,
            longitude REAL,
            device_type TEXT NOT NULL,
            geo_fence_name TEXT NOT NULL,
            geo_index INTEGER NOT NULL,
            sleeping INTEGER NOT NULL,
            dashboard_show_on INTEGER NOT NULL DEFAULT 0,
            dashboard_widget TEXT NOT NULL DEFAULT 'tempHumidity',
            dashboard_range TEXT NOT NULL DEFAULT 'latest'
          )
        ''');
        await db.execute('''
          CREATE TABLE conversation_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            node_num INTEGER NOT NULL,
            text TEXT NOT NULL,
            mine INTEGER NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            status TEXT NOT NULL,
            message_uuid TEXT NOT NULL,
            voice_bytes BLOB NOT NULL DEFAULT X'',
            voice_codec INTEGER NOT NULL DEFAULT 0,
            duration_ms INTEGER NOT NULL DEFAULT 0,
            UNIQUE(node_num, timestamp_ms, mine, text, message_uuid)
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_messages_node_time
          ON conversation_messages(node_num, timestamp_ms)
        ''');
        await db.execute('''
          CREATE TABLE geo_fences (
            name TEXT PRIMARY KEY,
            marker TEXT NOT NULL,
            alert_condition TEXT NOT NULL,
            updated_at_ms INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE sensor_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            node_num INTEGER NOT NULL,
            timestamp_ms INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            altitude REAL,
            temperature REAL,
            humidity REAL,
            pressure REAL,
            vibration_average REAL,
            accel_x REAL,
            accel_y REAL,
            accel_z REAL,
            gyro_x REAL,
            gyro_y REAL,
            gyro_z REAL,
            sensor_data_length INTEGER
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_sensor_node_time
          ON sensor_data(node_num, timestamp_ms)
        ''');
      },
      onOpen: _ensureSchema,
    );
  }

  Future<void> _ensureSchema(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(nodes)');
    final columnNames = columns.map((row) => row['name'] as String).toSet();
    if (!columnNames.contains('public_key')) {
      await db.execute(
          "ALTER TABLE nodes ADD COLUMN public_key BLOB NOT NULL DEFAULT X''");
    }
    final messageColumns =
        await db.rawQuery('PRAGMA table_info(conversation_messages)');
    final messageColumnNames =
        messageColumns.map((row) => row['name'] as String).toSet();
    if (!messageColumnNames.contains('voice_bytes')) {
      await db.execute(
          "ALTER TABLE conversation_messages ADD COLUMN voice_bytes BLOB NOT NULL DEFAULT X''");
    }
    if (!messageColumnNames.contains('voice_codec')) {
      await db.execute(
          'ALTER TABLE conversation_messages ADD COLUMN voice_codec INTEGER NOT NULL DEFAULT 0');
    }
    if (!messageColumnNames.contains('duration_ms')) {
      await db.execute(
          'ALTER TABLE conversation_messages ADD COLUMN duration_ms INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<Map<int, EdgezMeshNode>> loadNodes() async {
    final db = _requireDatabase();
    final rows =
        await db.query('nodes', orderBy: 'display_name COLLATE NOCASE');
    return <int, EdgezMeshNode>{
      for (final row in rows)
        row['node_num'] as int: EdgezMeshNode(
          nodeNum: row['node_num'] as int,
          userUuid: row['user_uuid'] as String,
          displayName: row['display_name'] as String,
          route: row['route'] as String,
          lastSeenMs: row['last_seen_ms'] as int,
          marker: row['marker'] as String,
          publicKey: row['public_key'] as List<int>? ?? const <int>[],
          latitude: (row['latitude'] as num?)?.toDouble(),
          longitude: (row['longitude'] as num?)?.toDouble(),
          deviceType: row['device_type'] as String,
          geoFenceName: row['geo_fence_name'] as String,
          geoIndex: row['geo_index'] as int,
          sleeping: (row['sleeping'] as int) != 0,
        ),
    };
  }

  Future<Map<String, ExampleDashboardDisplay>> loadDashboardDisplays() async {
    final db = _requireDatabase();
    final rows = await db.query(
      'nodes',
      columns: <String>[
        'node_num',
        'user_uuid',
        'dashboard_show_on',
        'dashboard_widget',
        'dashboard_range',
      ],
    );
    return <String, ExampleDashboardDisplay>{
      for (final row in rows)
        _deviceKey(row['user_uuid'] as String, row['node_num'] as int):
            ExampleDashboardDisplay(
          deviceKey:
              _deviceKey(row['user_uuid'] as String, row['node_num'] as int),
          showOnDashboard: (row['dashboard_show_on'] as int) != 0,
          widget: ExampleDashboardWidget.fromName(
              row['dashboard_widget'] as String?),
          range:
              ExampleDashboardRange.fromName(row['dashboard_range'] as String?),
        ),
    };
  }

  Future<void> setDashboardDisplay(ExampleDashboardDisplay display) async {
    final db = _requireDatabase();
    await db.update(
      'nodes',
      <String, Object?>{
        'dashboard_show_on': display.showOnDashboard ? 1 : 0,
        'dashboard_widget': display.widget.name,
        'dashboard_range': display.range.name,
      },
      where: 'user_uuid = ? OR (user_uuid = ? AND CAST(node_num AS TEXT) = ?)',
      whereArgs: <Object?>[display.deviceKey, '', display.deviceKey],
    );
  }

  Future<Map<int, List<EdgezConversationMessage>>> loadConversations() async {
    final db = _requireDatabase();
    final rows = await db.query(
      'conversation_messages',
      orderBy: 'timestamp_ms ASC',
    );
    final conversations = <int, List<EdgezConversationMessage>>{};
    for (final row in rows) {
      final nodeNum = row['node_num'] as int;
      conversations.putIfAbsent(nodeNum, () => <EdgezConversationMessage>[]);
      conversations[nodeNum]!.add(
        EdgezConversationMessage(
          nodeNum: nodeNum,
          text: row['text'] as String,
          mine: (row['mine'] as int) != 0,
          timestampMs: row['timestamp_ms'] as int,
          status: row['status'] as String,
          messageUuid: row['message_uuid'] as String,
          voiceBytes: row['voice_bytes'] as List<int>? ?? const <int>[],
          voiceCodec: row['voice_codec'] as int? ?? 0,
          durationMs: row['duration_ms'] as int? ?? 0,
        ),
      );
    }
    return conversations;
  }

  Future<List<EdgezSensorSample>> loadSensorSamples(
    int nodeNum, {
    int limit = 120,
  }) async {
    final db = _requireDatabase();
    final rows = await db.query(
      'sensor_data',
      where: 'node_num = ?',
      whereArgs: <Object?>[nodeNum],
      orderBy: 'timestamp_ms DESC',
      limit: limit,
    );
    return rows.reversed.map((row) {
      return EdgezSensorSample(
        nodeNum: nodeNum,
        timestampMs: row['timestamp_ms'] as int,
        data: EdgezSensorData(
          latitude: (row['latitude'] as num?)?.toDouble(),
          longitude: (row['longitude'] as num?)?.toDouble(),
          altitude: (row['altitude'] as num?)?.toDouble(),
          temperature: (row['temperature'] as num?)?.toDouble(),
          humidity: (row['humidity'] as num?)?.toDouble(),
          pressure: (row['pressure'] as num?)?.toDouble(),
          vibrationAverage: (row['vibration_average'] as num?)?.toDouble(),
          accelX: (row['accel_x'] as num?)?.toDouble(),
          accelY: (row['accel_y'] as num?)?.toDouble(),
          accelZ: (row['accel_z'] as num?)?.toDouble(),
          gyroX: (row['gyro_x'] as num?)?.toDouble(),
          gyroY: (row['gyro_y'] as num?)?.toDouble(),
          gyroZ: (row['gyro_z'] as num?)?.toDouble(),
          binaryLengthBytes: row['sensor_data_length'] as int?,
        ),
      );
    }).toList(growable: false);
  }

  Future<void> persistStateSnapshot(EdgezMeshState state) async {
    final db = _requireDatabase();
    await db.transaction((txn) async {
      for (final node in state.nodes.values) {
        await _upsertNode(txn, node);
      }
      for (final messages in state.conversations.values) {
        for (final message in messages) {
          await _insertMessage(txn, message);
        }
      }
      await txn.delete('sensor_data');
      for (final samples in state.sensorSamples.values) {
        for (final sample in samples) {
          await _insertSensorSample(txn, sample);
        }
      }
    });
  }

  Future<void> deleteNode(int nodeNum) async {
    final db = _requireDatabase();
    await db.transaction((txn) async {
      await txn.delete(
        'sensor_data',
        where: 'node_num = ?',
        whereArgs: <Object?>[nodeNum],
      );
      await txn.delete(
        'conversation_messages',
        where: 'node_num = ?',
        whereArgs: <Object?>[nodeNum],
      );
      await txn.delete(
        'nodes',
        where: 'node_num = ?',
        whereArgs: <Object?>[nodeNum],
      );
    });
  }

  Future<void> insertSensorSample(
    int nodeNum,
    EdgezSensorSample sample,
  ) async {
    final db = _requireDatabase();
    await db.insert('sensor_data', <String, Object?>{
      'node_num': nodeNum,
      'timestamp_ms': sample.timestampMs,
      'latitude': sample.data.latitude,
      'longitude': sample.data.longitude,
      'altitude': sample.data.altitude,
      'temperature': sample.data.temperature,
      'humidity': sample.data.humidity,
      'pressure': sample.data.pressure,
      'vibration_average': sample.data.vibrationAverage,
      'accel_x': sample.data.accelX,
      'accel_y': sample.data.accelY,
      'accel_z': sample.data.accelZ,
      'gyro_x': sample.data.gyroX,
      'gyro_y': sample.data.gyroY,
      'gyro_z': sample.data.gyroZ,
      'sensor_data_length': sample.data.binaryLengthBytes,
    });
  }

  Future<void> _upsertNode(Transaction txn, EdgezMeshNode node) async {
    final deviceKey = _deviceKey(node.userUuid, node.nodeNum);
    final savedDisplays = await txn.query(
      'nodes',
      columns: <String>[
        'dashboard_show_on',
        'dashboard_widget',
        'dashboard_range',
      ],
      where: node.userUuid.isEmpty ? 'node_num = ?' : 'user_uuid = ?',
      whereArgs: <Object?>[
        node.userUuid.isEmpty ? node.nodeNum : node.userUuid,
      ],
      limit: 1,
    );
    final savedDisplay = savedDisplays.isEmpty
        ? ExampleDashboardDisplay(deviceKey: deviceKey)
        : ExampleDashboardDisplay(
            deviceKey: deviceKey,
            showOnDashboard:
                (savedDisplays.single['dashboard_show_on'] as int) != 0,
            widget: ExampleDashboardWidget.fromName(
                savedDisplays.single['dashboard_widget'] as String?),
            range: ExampleDashboardRange.fromName(
                savedDisplays.single['dashboard_range'] as String?),
          );
    // Android keys cached peers by user UUID, which remains stable when a
    // device receives a different mesh node number. Remove the stale row
    // before replacing the current node-number keyed Flutter row.
    if (node.userUuid.isNotEmpty) {
      await txn.delete(
        'nodes',
        where: 'user_uuid = ? AND node_num != ?',
        whereArgs: <Object?>[node.userUuid, node.nodeNum],
      );
    }
    await txn.insert(
      'nodes',
      <String, Object?>{
        'node_num': node.nodeNum,
        'user_uuid': node.userUuid,
        'display_name': node.resolvedDisplayName,
        'route': node.route,
        'last_seen_ms': node.lastSeenMs,
        'marker': node.marker,
        'public_key': node.publicKey,
        'latitude': node.latitude,
        'longitude': node.longitude,
        'device_type': node.deviceType,
        'geo_fence_name': node.geoFenceName,
        'geo_index': node.geoIndex,
        'sleeping': node.sleeping ? 1 : 0,
        'dashboard_show_on': savedDisplay.showOnDashboard ? 1 : 0,
        'dashboard_widget': savedDisplay.widget.name,
        'dashboard_range': savedDisplay.range.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (node.geoFenceName.isNotEmpty) {
      await txn.insert(
        'geo_fences',
        <String, Object?>{
          'name': node.geoFenceName,
          'marker': node.marker,
          'alert_condition': 'Enter',
          'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> _insertMessage(
    Transaction txn,
    EdgezConversationMessage message,
  ) async {
    await txn.insert(
      'conversation_messages',
      <String, Object?>{
        'node_num': message.nodeNum,
        'text': message.text,
        'mine': message.mine ? 1 : 0,
        'timestamp_ms': message.timestampMs,
        'status': message.status,
        'message_uuid': message.messageUuid,
        'voice_bytes': message.voiceBytes,
        'voice_codec': message.voiceCodec,
        'duration_ms': message.durationMs,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _insertSensorSample(
    Transaction txn,
    EdgezSensorSample sample,
  ) async {
    await txn.insert(
      'sensor_data',
      <String, Object?>{
        'node_num': sample.nodeNum,
        'timestamp_ms': sample.timestampMs,
        'latitude': sample.data.latitude,
        'longitude': sample.data.longitude,
        'altitude': sample.data.altitude,
        'temperature': sample.data.temperature,
        'humidity': sample.data.humidity,
        'pressure': sample.data.pressure,
        'vibration_average': sample.data.vibrationAverage,
        'accel_x': sample.data.accelX,
        'accel_y': sample.data.accelY,
        'accel_z': sample.data.accelZ,
        'gyro_x': sample.data.gyroX,
        'gyro_y': sample.data.gyroY,
        'gyro_z': sample.data.gyroZ,
        'sensor_data_length': sample.data.binaryLengthBytes,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Database _requireDatabase() {
    final db = _database;
    if (db == null) {
      throw StateError('Example database is not open');
    }
    return db;
  }

  static String _deviceKey(String userUuid, int nodeNum) {
    return userUuid.isNotEmpty ? userUuid : nodeNum.toString();
  }
}
