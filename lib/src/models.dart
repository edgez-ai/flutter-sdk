enum EdgezConnectionType {
  none,
  ble,
  usb;

  static EdgezConnectionType fromWire(String? value) {
    return EdgezConnectionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => EdgezConnectionType.none,
    );
  }
}

enum EdgezDeviceLogLevel {
  none(0, 'None'),
  error(1, 'Error'),
  warning(2, 'Warn'),
  info(3, 'Info'),
  debug(4, 'Debug'),
  verbose(5, 'Verbose');

  const EdgezDeviceLogLevel(this.wireValue, this.label);

  final int wireValue;
  final String label;
}

enum EdgezMeshEventType {
  connection,
  bleDevice,
  ready,
  packet,
  status,
  node,
  message,
  voiceFrame,
  speedTestFrame,
  usbLinkStats,
  voiceAudio,
  openManetComms,
  otaProgress,
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
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.binaryLengthBytes,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? temperature;
  final double? humidity;
  final double? pressure;
  final double? vibrationAverage;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final int? binaryLengthBytes;

  bool get hasAnyValue {
    return latitude != null ||
        longitude != null ||
        altitude != null ||
        temperature != null ||
        humidity != null ||
        pressure != null ||
        vibrationAverage != null ||
        accelX != null ||
        accelY != null ||
        accelZ != null ||
        gyroX != null ||
        gyroY != null ||
        gyroZ != null ||
        binaryLengthBytes != null;
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

class EdgezTopologyLink {
  const EdgezTopologyLink({
    required this.reporterNodeNum,
    required this.peerNodeNum,
    required this.encodedRssi,
    required this.lastSeenMs,
    this.routeTq = 0,
    this.routeHops = 0,
  });

  final int reporterNodeNum;
  final int peerNodeNum;
  final int encodedRssi;
  final int lastSeenMs;
  final int routeTq;
  final int routeHops;

  int? get rssiDbm => encodedRssi == 1000 ? null : encodedRssi - 1000;

  String get undirectedKey {
    final low = reporterNodeNum < peerNodeNum ? reporterNodeNum : peerNodeNum;
    final high = reporterNodeNum < peerNodeNum ? peerNodeNum : reporterNodeNum;
    return '$low:$high';
  }
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

class EdgezUsbDevice {
  const EdgezUsbDevice({
    required this.id,
    required this.name,
    required this.vendorId,
    required this.productId,
    this.transport = 'generic-usb',
  });

  final int id;
  final String name;
  final int vendorId;
  final int productId;

  /// Native transport exposed by the Android USB plugin, for example
  /// `tinyusb-cdc-uart` or `cp2102-uart`.
  final String transport;

  String get label => '$name (${vendorId.toRadixString(16).padLeft(4, '0')}:'
      '${productId.toRadixString(16).padLeft(4, '0')})';

  factory EdgezUsbDevice.fromMap(Map<Object?, Object?> map) => EdgezUsbDevice(
        id: map['id'] as int? ?? 0,
        name: map['name'] as String? ?? 'ESP32-S3 USB',
        vendorId: map['vendorId'] as int? ?? 0,
        productId: map['productId'] as int? ?? 0,
        transport: map['transport'] as String? ?? 'generic-usb',
      );
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
    this.meshBandwidthMhz = 0,
    this.meshFrequencyKhz = 0,
    this.beacon = const EdgezBeaconConfig(),
  });

  final String countryCode;
  final String meshId;
  final String passphrase;
  final int maxHop;
  final int meshBandwidthMhz;
  final int meshFrequencyKhz;
  final EdgezUserIdentity identity;
  final EdgezBeaconConfig beacon;

  Map<String, Object?> toMap() => {
        'countryCode': countryCode,
        'meshId': meshId,
        'passphrase': passphrase,
        'maxHop': maxHop,
        'meshBandwidthMhz': meshBandwidthMhz,
        'meshFrequencyKhz': meshFrequencyKhz,
        'identity': identity.toMap(),
        'beacon': beacon.toMap(),
      };
}

class EdgezBeaconConfig {
  const EdgezBeaconConfig({
    this.intervalSeconds = 30,
    this.marker = 'blue',
    this.shareLocation = false,
    this.useDeviceGps = false,
    this.latitude,
    this.longitude,
    this.locationTimestampMs = 0,
  });

  final int intervalSeconds;
  final String marker;
  final bool shareLocation;
  final bool useDeviceGps;
  final double? latitude;
  final double? longitude;
  final int locationTimestampMs;

  int get normalizedIntervalSeconds => intervalSeconds.clamp(5, 3600);

  Map<String, Object?> toMap() => {
        'intervalSeconds': intervalSeconds,
        'marker': marker,
        'shareLocation': shareLocation,
        'useDeviceGps': useDeviceGps,
        'latitude': latitude,
        'longitude': longitude,
        'locationTimestampMs': locationTimestampMs,
      };
}

class EdgezLocation {
  const EdgezLocation({
    required this.latitude,
    required this.longitude,
    required this.timestampMs,
  });

  factory EdgezLocation.fromMap(Map<Object?, Object?> map) {
    return EdgezLocation(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestampMs: (map['timestampMs'] as num?)?.toInt() ?? 0,
    );
  }

  final double latitude;
  final double longitude;
  final int timestampMs;
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
    this.passphrase = '',
    this.upstreamWifiSsid = '',
    this.upstreamWifiPassphrase = '',
    this.beaconUnicast = 0,
    this.deviceType = 'relay',
    this.sleepModeEnabled = false,
    this.deviceGpsEnabled = false,
    this.meshFrequencyKhz = 0,
    this.meshBandwidthMhz = 0,
    this.userIdHigh = 0,
    this.userIdLow = 0,
    this.userPublicKey = const <int>[],
    this.userPrivateKey = const <int>[],
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
  final String passphrase;
  final String upstreamWifiSsid;
  final String upstreamWifiPassphrase;
  final int beaconUnicast;
  final String deviceType;
  final bool sleepModeEnabled;
  final bool deviceGpsEnabled;
  final int meshFrequencyKhz;
  final int meshBandwidthMhz;
  final int userIdHigh;
  final int userIdLow;
  final List<int> userPublicKey;
  final List<int> userPrivateKey;

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
        'passphrase': passphrase,
        'upstreamWifiSsid': upstreamWifiSsid,
        'upstreamWifiPassphrase': upstreamWifiPassphrase,
        'beaconUnicast': beaconUnicast,
        'deviceType': deviceType,
        'sleepModeEnabled': sleepModeEnabled,
        'deviceGpsEnabled': deviceGpsEnabled,
        'meshFrequencyKhz': meshFrequencyKhz,
        'meshBandwidthMhz': meshBandwidthMhz,
        'userIdHigh': userIdHigh,
        'userIdLow': userIdLow,
        'userPublicKey': userPublicKey,
        'userPrivateKey': userPrivateKey,
      };

  EdgezDeviceSettings copyWith({bool? deviceGpsEnabled}) {
    return EdgezDeviceSettings(
      deviceModeEnabled: deviceModeEnabled,
      meshId: meshId,
      shareLocation: shareLocation,
      userName: userName,
      marker: marker,
      beaconIntervalSeconds: beaconIntervalSeconds,
      maxHop: maxHop,
      latitude: latitude,
      longitude: longitude,
      geoFenceName: geoFenceName,
      geoIndex: geoIndex,
      uartI2cSensorType: uartI2cSensorType,
      rs485SensorType: rs485SensorType,
      passphrase: passphrase,
      upstreamWifiSsid: upstreamWifiSsid,
      upstreamWifiPassphrase: upstreamWifiPassphrase,
      beaconUnicast: beaconUnicast,
      deviceType: deviceType,
      sleepModeEnabled: sleepModeEnabled,
      deviceGpsEnabled: deviceGpsEnabled ?? this.deviceGpsEnabled,
      meshFrequencyKhz: meshFrequencyKhz,
      meshBandwidthMhz: meshBandwidthMhz,
      userIdHigh: userIdHigh,
      userIdLow: userIdLow,
      userPublicKey: userPublicKey,
      userPrivateKey: userPrivateKey,
    );
  }
}

enum EdgezSensorConnector { uartI2c, rs485 }

enum EdgezSensorScriptAction { upload, delete }

/// A device-side Lua driver transferred with ScriptConfig packets.
class EdgezSensorScriptConfig {
  const EdgezSensorScriptConfig({
    required this.scriptId,
    required this.version,
    required this.name,
    required this.sensorType,
    required this.connector,
    required this.script,
    this.globalBufferSize = 4096,
    this.mimeType = 'application/x-lua',
    this.action = EdgezSensorScriptAction.upload,
  });

  final int scriptId;
  final int version;
  final String name;
  final String sensorType;
  final EdgezSensorConnector connector;
  final String script;
  final int globalBufferSize;
  final String mimeType;
  final EdgezSensorScriptAction action;
}

enum EdgezLicenseStatus {
  unspecified,
  authorized,
  deviceNotLicensed,
  sdkReleaseRequired,
  sdkVersionIncompatible,
  sdkReleaseInvalid;

  bool get isAuthorized => this == EdgezLicenseStatus.authorized;

  String get label => switch (this) {
        EdgezLicenseStatus.unspecified => 'License status unknown',
        EdgezLicenseStatus.authorized => 'Licensed',
        EdgezLicenseStatus.deviceNotLicensed => 'Device not licensed',
        EdgezLicenseStatus.sdkReleaseRequired => 'SDK release required',
        EdgezLicenseStatus.sdkVersionIncompatible => 'SDK version incompatible',
        EdgezLicenseStatus.sdkReleaseInvalid => 'SDK release invalid',
      };

  static EdgezLicenseStatus fromWire(Object? value) {
    if (value is int && value >= 0 && value < values.length) {
      return values[value];
    }
    if (value is String) {
      return values.firstWhere(
        (status) => status.name == value,
        orElse: () => EdgezLicenseStatus.unspecified,
      );
    }
    return EdgezLicenseStatus.unspecified;
  }
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
    this.licenseStatus = EdgezLicenseStatus.unspecified,
    this.firmwareVersion = '',
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
  final EdgezLicenseStatus licenseStatus;
  final String firmwareVersion;

  bool get licensed => licenseStatus.isAuthorized;

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
      licenseStatus: EdgezLicenseStatus.fromWire(
        map['licenseStatus'] ??
            (map['licensed'] == true
                ? EdgezLicenseStatus.authorized.index
                : null),
      ),
      firmwareVersion: map['firmwareVersion'] as String? ?? '',
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
    if (isPublicChannel) return true;
    final normalized = deviceType.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'unspecified' ||
        normalized == 'user' ||
        normalized == 'device_type_user';
  }

  bool get isPublicChannel => EdgezPublicChannels.isChannelNodeNum(nodeNum);

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

/// Five OpenMANET-compatible public channels represented as synthetic users.
///
/// The node/user ID is the OpenMANET RTP talkgroup port. Using the port as the
/// canonical ID avoids maintaining a separate channel mapping in the SDK,
/// firmware, and UI.
class EdgezPublicChannels {
  const EdgezPublicChannels._();

  static const List<int> talkgroupPorts = <int>[
    38801,
    38803,
    38805,
    38807,
    38809,
  ];
  static const int count = 5;

  static bool isChannelNodeNum(int nodeNum) => talkgroupPorts.contains(nodeNum);

  static int indexForNodeNum(int nodeNum) {
    final index = talkgroupPorts.indexOf(nodeNum);
    return index < 0 ? 0 : index + 1;
  }

  static String username(int channel) => 'channel$channel';

  static EdgezMeshNode node(int channel) {
    if (channel < 1 || channel > count) {
      throw RangeError.range(channel, 1, count, 'channel');
    }
    final name = username(channel);
    final talkgroupPort = talkgroupPorts[channel - 1];
    return EdgezMeshNode(
      nodeNum: talkgroupPort,
      userUuid: talkgroupPort.toString(),
      displayName: name,
      route: 'PUBLIC',
      lastSeenMs: 0,
      marker: 'cyan',
      deviceType: 'PublicChannel',
    );
  }

  static List<EdgezMeshNode> get nodes => List<EdgezMeshNode>.unmodifiable(
        List<EdgezMeshNode>.generate(count, (index) => node(index + 1)),
      );

  static EdgezMeshNode? nodeForNodeNum(int nodeNum) {
    final channel = indexForNodeNum(nodeNum);
    return channel == 0 ? null : node(channel);
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
    this.transcript = '',
    this.transcriptLanguage = '',
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
  final String transcript;
  final String transcriptLanguage;

  bool get isVoice =>
      voiceBytes.isNotEmpty || voiceCodec != 0 || durationMs > 0;

  EdgezConversationMessage copyWith({
    String? messageUuid,
    String? status,
    String? transcript,
    String? transcriptLanguage,
  }) {
    return EdgezConversationMessage(
      nodeNum: nodeNum,
      text: text,
      mine: mine,
      timestampMs: timestampMs,
      messageUuid: messageUuid ?? this.messageUuid,
      status: status ?? this.status,
      voiceBytes: voiceBytes,
      voiceCodec: voiceCodec,
      durationMs: durationMs,
      transcript: transcript ?? this.transcript,
      transcriptLanguage: transcriptLanguage ?? this.transcriptLanguage,
    );
  }

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
      transcript: map['transcript'] as String? ?? '',
      transcriptLanguage: map['transcriptLanguage'] as String? ?? '',
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

enum EdgezVoiceCallPhase { idle, outgoing, incoming, active }

class EdgezVoiceCallState {
  const EdgezVoiceCallState({
    this.peerNodeNum,
    this.callId = 0,
    this.phase = EdgezVoiceCallPhase.idle,
  });

  final int? peerNodeNum;
  final int callId;
  final EdgezVoiceCallPhase phase;

  bool get isIdle => phase == EdgezVoiceCallPhase.idle;
  bool get isActive => phase == EdgezVoiceCallPhase.active;
}

class EdgezVoiceCallEnvelope {
  const EdgezVoiceCallEnvelope({
    required this.fromNode,
    required this.sequence,
    required this.plaintext,
  });

  final int fromNode;
  final int sequence;
  final List<int> plaintext;
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
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.usbSentPings = 0,
    this.usbReceivedPings = 0,
    this.usbReceivedPongs = 0,
    this.usbTimeouts = 0,
    this.usbRttMs = 0,
    this.receivedAtUs = 0,
    this.talkgroupPort = 0,
    this.log = '',
  });

  final EdgezMeshEventType type;
  final EdgezConnectionType connection;
  final EdgezBleDevice? bleDevice;
  final List<int> packet;
  final EdgezMeshStatus? status;
  final EdgezMeshNode? node;
  final EdgezConversationMessage? message;
  final int sentBytes;
  final int totalBytes;
  final int usbSentPings;
  final int usbReceivedPings;
  final int usbReceivedPongs;
  final int usbTimeouts;
  final int usbRttMs;
  final int receivedAtUs;
  final int talkgroupPort;
  final String log;

  double get progress => totalBytes <= 0 ? 0 : sentBytes / totalBytes;

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
      sentBytes: map['sentBytes'] as int? ?? 0,
      totalBytes: map['totalBytes'] as int? ?? 0,
      usbSentPings: map['sentPings'] as int? ?? 0,
      usbReceivedPings: map['receivedPings'] as int? ?? 0,
      usbReceivedPongs: map['receivedPongs'] as int? ?? 0,
      usbTimeouts: map['timeouts'] as int? ?? 0,
      usbRttMs: map['rttMs'] as int? ?? 0,
      receivedAtUs: (map['receivedAtUs'] as num?)?.toInt() ?? 0,
      talkgroupPort: map['talkgroupPort'] as int? ?? 0,
      log: map['log'] as String? ?? '',
    );
  }
}
