enum EdgezConnectionType {
  none,
  ble;

  static EdgezConnectionType fromWire(String? value) {
    return EdgezConnectionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => EdgezConnectionType.none,
    );
  }
}

enum EdgezMeshEventType {
  connection,
  bleDevice,
  ready,
  packet,
  status,
  node,
  message,
  log;

  static EdgezMeshEventType fromWire(String? value) {
    return EdgezMeshEventType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => EdgezMeshEventType.log,
    );
  }
}

class EdgezSensorData {
  const EdgezSensorData({
    this.latitude,
    this.longitude,
    this.altitude,
    this.temperature,
    this.humidity,
    this.pressure,
    this.vibrationAverage,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? temperature;
  final double? humidity;
  final double? pressure;
  final double? vibrationAverage;

  bool get hasAnyValue {
    return latitude != null ||
        longitude != null ||
        altitude != null ||
        temperature != null ||
        humidity != null ||
        pressure != null ||
        vibrationAverage != null;
  }
}

class EdgezSensorSample {
  const EdgezSensorSample({
    required this.nodeNum,
    required this.timestampMs,
    required this.data,
  });

  final int nodeNum;
  final int timestampMs;
  final EdgezSensorData data;
}

class EdgezBleDevice {
  const EdgezBleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.lastSeenMs,
  });

  final String id;
  final String name;
  final int rssi;
  final int lastSeenMs;

  String get label => name.isEmpty ? id : '$name $id';

  factory EdgezBleDevice.fromMap(Map<Object?, Object?> map) {
    return EdgezBleDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      rssi: map['rssi'] as int? ?? 0,
      lastSeenMs: map['lastSeenMs'] as int? ?? 0,
    );
  }
}

class EdgezUserIdentity {
  const EdgezUserIdentity({
    this.userUuid = '',
    required this.userIdHigh,
    required this.userIdLow,
    required this.name,
    this.privateKey = const <int>[],
    required this.publicKey,
  });

  final String userUuid;
  final int userIdHigh;
  final int userIdLow;
  final String name;
  final List<int> privateKey;
  final List<int> publicKey;

  EdgezUserIdentity copyWith({
    String? name,
    List<int>? privateKey,
    List<int>? publicKey,
  }) {
    return EdgezUserIdentity(
      userUuid: userUuid,
      userIdHigh: userIdHigh,
      userIdLow: userIdLow,
      name: name ?? this.name,
      privateKey: privateKey ?? this.privateKey,
      publicKey: publicKey ?? this.publicKey,
    );
  }

  Map<String, Object?> toMap() => {
        'userUuid': userUuid,
        'userIdHigh': userIdHigh,
        'userIdLow': userIdLow,
        'name': name,
        'privateKey': privateKey,
        'publicKey': publicKey,
      };
}

class EdgezMeshConfig {
  const EdgezMeshConfig({
    required this.identity,
    this.countryCode = 'US',
    this.meshId = 'edgez',
    this.passphrase = '',
    this.maxHop = 4,
    this.beacon = const EdgezBeaconConfig(),
  });

  final String countryCode;
  final String meshId;
  final String passphrase;
  final int maxHop;
  final EdgezUserIdentity identity;
  final EdgezBeaconConfig beacon;

  Map<String, Object?> toMap() => {
        'countryCode': countryCode,
        'meshId': meshId,
        'passphrase': passphrase,
        'maxHop': maxHop,
        'identity': identity.toMap(),
        'beacon': beacon.toMap(),
      };
}

class EdgezBeaconConfig {
  const EdgezBeaconConfig({
    this.intervalSeconds = 30,
    this.marker = 'blue',
    this.shareLocation = false,
    this.latitude,
    this.longitude,
    this.locationTimestampMs = 0,
  });

  final int intervalSeconds;
  final String marker;
  final bool shareLocation;
  final double? latitude;
  final double? longitude;
  final int locationTimestampMs;

  int get normalizedIntervalSeconds => intervalSeconds.clamp(5, 3600);

  Map<String, Object?> toMap() => {
        'intervalSeconds': intervalSeconds,
        'marker': marker,
        'shareLocation': shareLocation,
        'latitude': latitude,
        'longitude': longitude,
        'locationTimestampMs': locationTimestampMs,
      };
}

class EdgezDeviceSettings {
  const EdgezDeviceSettings({
    this.deviceModeEnabled = false,
    this.meshId = '',
    this.shareLocation = false,
    this.userName = '',
    this.marker = 'green',
    this.beaconIntervalSeconds = 30,
    this.maxHop = 0,
    this.latitude,
    this.longitude,
    this.geoFenceName = '',
    this.geoIndex = 0,
    this.uartI2cSensorType = '',
    this.rs485SensorType = '',
  });

  final bool deviceModeEnabled;
  final String meshId;
  final bool shareLocation;
  final String userName;
  final String marker;
  final int beaconIntervalSeconds;
  final int maxHop;
  final double? latitude;
  final double? longitude;
  final String geoFenceName;
  final int geoIndex;
  final String uartI2cSensorType;
  final String rs485SensorType;

  Map<String, Object?> toMap() => {
        'deviceModeEnabled': deviceModeEnabled,
        'meshId': meshId,
        'shareLocation': shareLocation,
        'userName': userName,
        'marker': marker,
        'beaconIntervalSeconds': beaconIntervalSeconds,
        'maxHop': maxHop,
        'latitude': latitude,
        'longitude': longitude,
        'geoFenceName': geoFenceName,
        'geoIndex': geoIndex,
        'uartI2cSensorType': uartI2cSensorType,
        'rs485SensorType': rs485SensorType,
      };
}

class EdgezMeshStatus {
  const EdgezMeshStatus({
    required this.supported,
    required this.stackInitialized,
    required this.meshMode,
    required this.linkUp,
    required this.routeReady,
    required this.readyForReport,
    required this.meshId,
    required this.ipAddress,
    required this.gateway,
    required this.macAddress,
  });

  final bool supported;
  final bool stackInitialized;
  final bool meshMode;
  final bool linkUp;
  final bool routeReady;
  final bool readyForReport;
  final String meshId;
  final String ipAddress;
  final String gateway;
  final int macAddress;

  bool get isUsable => supported && stackInitialized && linkUp && routeReady;

  factory EdgezMeshStatus.fromMap(Map<Object?, Object?> map) {
    return EdgezMeshStatus(
      supported: map['supported'] == true,
      stackInitialized: map['stackInitialized'] == true,
      meshMode: map['meshMode'] == true,
      linkUp: map['linkUp'] == true,
      routeReady: map['routeReady'] == true,
      readyForReport: map['readyForReport'] == true,
      meshId: map['meshId'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      gateway: map['gateway'] as String? ?? '',
      macAddress: map['macAddress'] as int? ?? 0,
    );
  }
}

class EdgezMeshNode {
  const EdgezMeshNode({
    required this.nodeNum,
    required this.userUuid,
    required this.displayName,
    required this.route,
    required this.lastSeenMs,
    required this.marker,
    this.publicKey = const <int>[],
    this.latitude,
    this.longitude,
    this.deviceType = '',
    this.geoFenceName = '',
    this.geoIndex = 0,
    this.sleeping = false,
  });

  final int nodeNum;
  final String userUuid;
  final String displayName;
  final String route;
  final int lastSeenMs;
  final String marker;
  final List<int> publicKey;
  final double? latitude;
  final double? longitude;
  final String deviceType;
  final String geoFenceName;
  final int geoIndex;
  final bool sleeping;

  String get nodeId {
    final mac = nodeNum & 0xffffffffffff;
    final parts = List<String>.generate(6, (index) {
      final shift = (5 - index) * 8;
      return ((mac >> shift) & 0xff).toRadixString(16).padLeft(2, '0');
    });
    return parts.join(':');
  }

  bool get opensConversation {
    final normalized = deviceType.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'unspecified' ||
        normalized == 'user' ||
        normalized == 'device_type_user';
  }

  bool get hasLocation => latitude != null && longitude != null;

  String get resolvedDisplayName =>
      displayName.isNotEmpty ? displayName : nodeId;

  EdgezMeshNode mergeDiscovery(EdgezMeshNode? previous) {
    return EdgezMeshNode(
      nodeNum: nodeNum,
      userUuid: userUuid.isNotEmpty ? userUuid : previous?.userUuid ?? '',
      displayName: displayName.isNotEmpty
          ? displayName
          : previous?.displayName ?? nodeId,
      route: route.isNotEmpty ? route : previous?.route ?? 'BLE',
      lastSeenMs:
          lastSeenMs > 0 ? lastSeenMs : DateTime.now().millisecondsSinceEpoch,
      marker: marker.isNotEmpty ? marker : previous?.marker ?? 'blue',
      publicKey: publicKey.isNotEmpty
          ? publicKey
          : previous?.publicKey ?? const <int>[],
      latitude: latitude ?? previous?.latitude,
      longitude: longitude ?? previous?.longitude,
      deviceType: deviceType.isNotEmpty
          ? deviceType
          : previous?.deviceType ?? 'Unspecified',
      geoFenceName:
          geoFenceName.isNotEmpty ? geoFenceName : previous?.geoFenceName ?? '',
      geoIndex: geoIndex != 0 ? geoIndex : previous?.geoIndex ?? 0,
      sleeping: sleeping,
    );
  }

  factory EdgezMeshNode.fromMap(Map<Object?, Object?> map) {
    return EdgezMeshNode(
      nodeNum: map['nodeNum'] as int? ?? 0,
      userUuid: map['userUuid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      route: map['route'] as String? ?? '',
      lastSeenMs: map['lastSeenMs'] as int? ?? 0,
      marker: map['marker'] as String? ?? 'blue',
      publicKey: map['publicKey'] is List
          ? List<int>.from(map['publicKey'] as List)
          : const <int>[],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      deviceType: map['deviceType'] as String? ?? '',
      geoFenceName: map['geoFenceName'] as String? ?? '',
      geoIndex: map['geoIndex'] as int? ?? 0,
      sleeping: map['sleeping'] == true,
    );
  }
}

class EdgezConversationMessage {
  const EdgezConversationMessage({
    required this.nodeNum,
    required this.text,
    required this.mine,
    required this.timestampMs,
    this.messageUuid = '',
    this.status = '',
    this.voiceBytes = const <int>[],
    this.voiceCodec = 0,
    this.durationMs = 0,
  });

  final int nodeNum;
  final String text;
  final bool mine;
  final int timestampMs;
  final String messageUuid;
  final String status;
  final List<int> voiceBytes;
  final int voiceCodec;
  final int durationMs;

  bool get isVoice =>
      voiceBytes.isNotEmpty || voiceCodec != 0 || durationMs > 0;

  factory EdgezConversationMessage.fromMap(Map<Object?, Object?> map) {
    return EdgezConversationMessage(
      nodeNum: map['nodeNum'] as int? ?? 0,
      text: map['text'] as String? ?? '',
      mine: map['mine'] == true,
      timestampMs: map['timestampMs'] as int? ?? 0,
      messageUuid: map['messageUuid'] as String? ?? '',
      status: map['status'] as String? ?? '',
      voiceBytes: map['voiceBytes'] is List
          ? List<int>.from(map['voiceBytes'] as List)
          : const <int>[],
      voiceCodec: map['voiceCodec'] as int? ?? 0,
      durationMs: map['durationMs'] as int? ?? 0,
    );
  }
}

class EdgezVoiceChunk {
  const EdgezVoiceChunk({
    required this.groupId,
    required this.durationMs,
    required this.totalChunks,
    required this.index,
    required this.codec,
    required this.audio,
  });

  final int groupId;
  final int durationMs;
  final int totalChunks;
  final int index;
  final int codec;
  final List<int> audio;
}

class EdgezVoiceRecording {
  const EdgezVoiceRecording({
    required this.bytes,
    required this.durationMs,
    required this.codec,
  });

  final List<int> bytes;
  final int durationMs;
  final int codec;
}

class EdgezMeshEvent {
  const EdgezMeshEvent({
    required this.type,
    this.connection = EdgezConnectionType.none,
    this.bleDevice,
    this.packet = const <int>[],
    this.status,
    this.node,
    this.message,
    this.log = '',
  });

  final EdgezMeshEventType type;
  final EdgezConnectionType connection;
  final EdgezBleDevice? bleDevice;
  final List<int> packet;
  final EdgezMeshStatus? status;
  final EdgezMeshNode? node;
  final EdgezConversationMessage? message;
  final String log;

  factory EdgezMeshEvent.fromMap(Map<Object?, Object?> map) {
    final type = EdgezMeshEventType.fromWire(map['type'] as String?);
    return EdgezMeshEvent(
      type: type,
      connection: EdgezConnectionType.fromWire(map['connection'] as String?),
      bleDevice: map['bleDevice'] is Map
          ? EdgezBleDevice.fromMap(
              map['bleDevice'] as Map<Object?, Object?>,
            )
          : null,
      packet: map['packet'] is List
          ? List<int>.from(map['packet'] as List)
          : const <int>[],
      status: map['status'] is Map
          ? EdgezMeshStatus.fromMap(map['status'] as Map<Object?, Object?>)
          : null,
      node: map['node'] is Map
          ? EdgezMeshNode.fromMap(map['node'] as Map<Object?, Object?>)
          : null,
      message: map['message'] is Map
          ? EdgezConversationMessage.fromMap(
              map['message'] as Map<Object?, Object?>)
          : null,
      log: map['log'] as String? ?? '',
    );
  }
}
