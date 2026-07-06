import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:sqflite/sqflite.dart';

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
            sleeping INTEGER NOT NULL
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
            vibration_average REAL
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
    });
  }

  Future<void> _upsertNode(Transaction txn, EdgezMeshNode node) async {
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
}
