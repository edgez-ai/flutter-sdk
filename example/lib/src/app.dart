import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'conversation_screen.dart';
import 'dashboard_tab.dart';
import 'debug_tab.dart';
import 'device_detail_screen.dart';
import 'driver_catalog.dart';
import 'drivers_tab.dart';
import 'example_database.dart';
import 'models.dart';
import 'marketplace_driver_install.dart';
import 'nodes_tab.dart';
import 'provisioning_screen.dart';
import 'settings_tab.dart';
import 'topology_screen.dart';
import 'voice_call_screen.dart';

enum AppDestination {
  dashboard('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  nodes('Nodes', Icons.hub_outlined, Icons.hub),
  drivers('Drivers', Icons.usb_outlined, Icons.usb),
  settings('Settings', Icons.bluetooth_connected_outlined,
      Icons.bluetooth_connected);

  const AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _otaManifestUrl = 'https://www.edgez.ai/api/ota/firmware';
const _speedHistoryWindow = Duration(minutes: 30);
const _downloadsChannel = MethodChannel(
  'ai.edgez.flutter_sdk_example/downloads',
);

class EdgezExampleApp extends StatefulWidget {
  const EdgezExampleApp({super.key});

  @override
  State<EdgezExampleApp> createState() => _EdgezExampleAppState();
}

class _EdgezExampleAppState extends State<EdgezExampleApp>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late final EdgezMeshSession session;
  late final ExampleDatabase database;
  late final EdgezIdentityStore identityStore;
  late final EdgezBleConfigurationStore bleConfigurationStore;
  late final EdgezDriverStore driverStore;
  late final EdgezDeviceLogStore deviceLogStore;
  late final AppLinks appLinks;
  StreamSubscription<Uri>? driverLinkSubscription;
  AppDestination destination = AppDestination.dashboard;
  int? selectedNodeNum;
  bool showTopology = false;
  bool showDebug = false;
  EdgezDeviceLogLevel deviceLogLevel = EdgezDeviceLogLevel.warning;
  EdgezUserIdentity? userIdentity;
  bool databaseReady = false;
  bool persistenceEnabled = false;
  bool hydrationComplete = false;
  Map<String, ExampleDashboardDisplay> dashboardDisplays =
      const <String, ExampleDashboardDisplay>{};
  List<ExampleSpeedMetric> speedMetrics = const <ExampleSpeedMetric>[];
  int lastPersistedSpeedMetricMs = 0;
  Timer? persistDebounce;
  bool persistInFlight = false;
  bool persistAgain = false;
  String lastPersistSignature = '';
  bool shareLocation = false;
  bool autoReplayReceivedVoice = false;
  bool deviceModeEnabled = false;
  bool provisionMode = false;
  List<ExampleDriver> drivers = ExampleDriverCatalog.bundled;
  MarketplaceDriverInstallRequest? pendingDriverInstall;
  bool bleAutoConnect = false;
  EdgezPreferredTransport preferredTransport = EdgezPreferredTransport.ble;
  EdgezBleDevice? selectedBleDevice;
  List<EdgezUsbDevice> usbDevices = const <EdgezUsbDevice>[];
  EdgezUsbDevice? selectedUsbDevice;
  EdgezOtaRelease? otaRelease;
  bool otaCheckInProgress = false;
  bool otaInstallInProgress = false;
  String otaMessage = '';
  String locationMessage = '';

  String meshCountry = 'US';
  String meshId = 'edgez';
  String passphrase = 'edgez123';
  String maxHop = '4';
  int meshBandwidthMhz = 1;
  int meshFrequencyKhz = 902500;
  String beaconIntervalSeconds = '10';
  String userName = 'Flutter Demo';
  ExampleMarker userMarker = ExampleMarker.blue;

  String deviceUserName = 'EdgeZ Device';
  ExampleMarker deviceMarker = ExampleMarker.green;
  String deviceMeshId = 'edgez';
  String deviceMaxHop = '4';
  String deviceBeaconIntervalSeconds = '10';
  bool deviceShareLocation = false;
  bool deviceGpsEnabled = false;
  EdgezDeviceSettings? observedDeviceSettings;
  EdgezLocation? observedSelfLocation;
  String deviceLatitude = '';
  String deviceLongitude = '';
  String deviceGeoFenceName = '';
  int deviceGeoIndex = 0;
  String uartI2cSensorType = '';
  String rs485SensorType = '';
  String deviceType = 'relay';
  String devicePassphrase = '';
  bool deviceUpstreamEnabled = false;
  String deviceUpstreamWifiSsid = '';
  String deviceUpstreamWifiPassphrase = '';
  String deviceBeaconMulticast = '';
  bool deviceSleepModeEnabled = false;
  EdgezVoiceCallPhase lastVoiceCallPhase = EdgezVoiceCallPhase.idle;
  AppLifecycleState appLifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    deviceLogStore = EdgezDeviceLogStore();
    session = EdgezMeshSession(
      onIncomingMessage: _showIncomingMessage,
      onIncomingCall: _showIncomingCall,
      deviceLogStore: deviceLogStore,
    );
    database = ExampleDatabase();
    identityStore = EdgezIdentityStore();
    bleConfigurationStore = EdgezBleConfigurationStore();
    driverStore = EdgezDriverStore();
    appLinks = AppLinks();
    session.addListener(_persistSessionSnapshot);
    session.addListener(_handleCallNotificationState);
    session.addListener(_handleDeviceGpsState);
    unawaited(session.restoreDeviceLogs());
    unawaited(_loadIdentityAndBleConfiguration());
    unawaited(_hydrateFromDatabase());
    unawaited(_loadInstalledDrivers());
    _listenForAppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appLifecycleState = state;
  }

  void _showIncomingMessage(
    EdgezConversationMessage message,
    EdgezMeshNode sender,
  ) {
    unawaited(_notifyIncomingMessage(message, sender));
  }

  void _showIncomingCall(EdgezVoiceCallState call, EdgezMeshNode caller) {
    unawaited(_notifyIncomingCall(call, caller));
  }

  Future<void> _notifyIncomingMessage(
    EdgezConversationMessage message,
    EdgezMeshNode sender,
  ) async {
    var shown = false;
    try {
      shown = await session.sdk
          .showIncomingMessageNotification(message: message, sender: sender);
    } on MissingPluginException {
      // A full rebuild is required after adding the native notification API.
    } on PlatformException {
      // Fall back to an in-app notice if Android rejects the notification.
    }
    if (!shown) {
      _showForegroundFallback(
        title: sender.resolvedDisplayName,
        detail: message.voiceBytes.isNotEmpty ? 'Voice message' : message.text,
        nodeNum: sender.nodeNum,
      );
    }
  }

  Future<void> _notifyIncomingCall(
    EdgezVoiceCallState call,
    EdgezMeshNode caller,
  ) async {
    // The dedicated Flutter call screen is already visible in the foreground.
    // Native CallStyle is needed only to bring a background/locked app forward.
    if (appLifecycleState == AppLifecycleState.resumed) return;
    var shown = false;
    try {
      shown = await session.sdk
          .showIncomingCallNotification(call: call, caller: caller);
    } on MissingPluginException {
      // A full rebuild is required after adding the native notification API.
    } on PlatformException {
      // Fall back to an in-app notice if Android rejects the notification.
    }
    if (!shown) {
      _showForegroundFallback(
        title: 'Incoming call from ${caller.resolvedDisplayName}',
        detail: 'Open the conversation to answer or decline.',
        nodeNum: caller.nodeNum,
        duration: const Duration(seconds: 30),
      );
    }
  }

  void _showForegroundFallback({
    required String title,
    required String detail,
    required int nodeNum,
    Duration duration = const Duration(seconds: 8),
  }) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = scaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: duration,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => _openIncomingConversation(nodeNum),
            ),
          ),
        );
    });
  }

  void _handleCallNotificationState() {
    final next = session.state.voiceCall.phase;
    if (lastVoiceCallPhase == EdgezVoiceCallPhase.incoming &&
        next != EdgezVoiceCallPhase.incoming) {
      unawaited(session.sdk.cancelIncomingCallNotification());
    }
    if (lastVoiceCallPhase != EdgezVoiceCallPhase.idle &&
        next == EdgezVoiceCallPhase.idle) {
      unawaited(session.sdk.clearCallLockScreenPresentation());
    }
    lastVoiceCallPhase = next;
  }

  Future<void> _answerCall() async {
    await session.sdk.cancelIncomingCallNotification();
    await session.acceptVoiceCall();
  }

  Future<void> _endCall() async {
    await session.endVoiceCall();
  }

  void _openIncomingConversation(int nodeNum) {
    if (!mounted) return;
    setState(() {
      provisionMode = false;
      destination = AppDestination.nodes;
      showTopology = false;
      selectedNodeNum = nodeNum;
    });
  }

  Future<void> _loadInstalledDrivers() async {
    try {
      final installed = await driverStore.load();
      final byKey = <String, ExampleDriver>{
        for (final driver in ExampleDriverCatalog.bundled) driver.key: driver,
        for (final bundle in installed)
          bundle.key: ExampleDriver.fromInstalled(bundle),
      };
      if (mounted) setState(() => drivers = byKey.values.toList());
    } catch (_) {
      // Driver storage is optional; bundled drivers remain available.
    }
  }

  void _listenForAppLinks() {
    try {
      unawaited(appLinks.getInitialLink().then((uri) {
        if (uri != null) _handleAppLink(uri);
      }));
      driverLinkSubscription = appLinks.uriLinkStream.listen(
        _handleAppLink,
        onError: (_) {},
      );
    } catch (_) {
      // Deep-link services are unavailable in widget tests and some hosts.
    }
  }

  void _handleAppLink(Uri uri) {
    if (uri.scheme == 'edgez' &&
        (uri.host == 'message' || uri.host == 'call')) {
      _handleNotificationLink(uri);
      return;
    }
    final request = MarketplaceDriverInstallRequest.fromUri(uri);
    if (request == null || !mounted) return;
    setState(() {
      pendingDriverInstall = request;
      destination = AppDestination.drivers;
      provisionMode = false;
    });
  }

  void _handleNotificationLink(Uri uri) {
    final nodeNum = int.tryParse(uri.queryParameters['node'] ?? '');
    if (nodeNum == null) return;
    _openIncomingConversation(nodeNum);
    if (uri.host != 'call') return;
    // Once the full-screen activity is visible, remove the system call banner;
    // the dedicated Flutter screen becomes the single call interface.
    unawaited(session.sdk.cancelIncomingCallNotification());
    final action = uri.queryParameters['action'];
    if (action == 'answer' || action == 'decline') {
      final callId = int.tryParse(uri.queryParameters['call'] ?? '');
      if (callId != null) {
        unawaited(_handleIncomingCallAction(nodeNum, callId, action!));
      }
    }
  }

  Future<void> _handleIncomingCallAction(
    int nodeNum,
    int callId,
    String action,
  ) async {
    await session.sdk.cancelIncomingCallNotification();
    final call = session.state.voiceCall;
    if (call.phase != EdgezVoiceCallPhase.incoming ||
        call.peerNodeNum != nodeNum ||
        call.callId != callId) {
      await session.sdk.clearCallLockScreenPresentation();
      return;
    }
    if (action == 'answer') {
      await _answerCall();
    } else {
      await _endCall();
    }
  }

  void _driverInstallHandled() {
    setState(() => pendingDriverInstall = null);
  }

  Future<void> _openProvisioning() async {
    if (session.state.connection != EdgezConnectionType.none) {
      await session.disconnect();
    }
    session.beginProvisioning();
    if (mounted) setState(() => provisionMode = true);
  }

  void _closeProvisioning() {
    session.endProvisioning();
    setState(() {
      provisionMode = false;
      destination = AppDestination.nodes;
    });
    final selected = selectedBleDevice;
    if (bleAutoConnect && selected != null) {
      unawaited(_connectBleDevice(selected.id));
    }
  }

  Future<void> _loadIdentityAndBleConfiguration() async {
    final identity = await identityStore.getOrCreate();
    final bleConfiguration = await bleConfigurationStore.load();
    var attachedUsbDevices = const <EdgezUsbDevice>[];
    if (bleConfiguration.preferredTransport == EdgezPreferredTransport.usb) {
      try {
        attachedUsbDevices = await session.sdk.listUsbDevices();
      } on MissingPluginException {
        // USB support requires a full Android rebuild after native changes.
      }
    }
    final restoredUsbDevice =
        attachedUsbDevices.cast<EdgezUsbDevice?>().firstWhere(
              (device) =>
                  device?.vendorId == bleConfiguration.usbVendorId &&
                  device?.productId == bleConfiguration.usbProductId,
              orElse: () => null,
            );
    if (!mounted) return;
    setState(() {
      userIdentity = identity;
      userName = identity.name;
      preferredTransport = bleConfiguration.preferredTransport;
      selectedBleDevice = preferredTransport == EdgezPreferredTransport.ble
          ? bleConfiguration.selectedDevice
          : null;
      usbDevices = attachedUsbDevices;
      selectedUsbDevice = restoredUsbDevice;
      bleAutoConnect = bleConfiguration.autoConnect;
      shareLocation = bleConfiguration.shareLocation;
      deviceLogLevel = bleConfiguration.logLevel;
    });
    await session.configureLogLevel(bleConfiguration.logLevel);
    if (bleConfiguration.preferredTransport == EdgezPreferredTransport.ble &&
        bleConfiguration.autoConnect &&
        bleConfiguration.hasSelectedDevice) {
      await _connectBleDevice(bleConfiguration.deviceId);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(driverLinkSubscription?.cancel());
    persistDebounce?.cancel();
    persistenceEnabled = false;
    session.removeListener(_persistSessionSnapshot);
    session.removeListener(_handleCallNotificationState);
    session.removeListener(_handleDeviceGpsState);
    session.dispose();
    unawaited(database.close());
    super.dispose();
  }

  Future<void> _hydrateFromDatabase() async {
    try {
      await database.open();
      final nodes = await database.loadNodes();
      final savedDashboardDisplays = await database.loadDashboardDisplays();
      final conversations = await database.loadConversations();
      final loadedSpeedMetrics = await database.loadSpeedMetrics(
        sinceMs:
            DateTime.now().subtract(_speedHistoryWindow).millisecondsSinceEpoch,
      );
      final samples = <int, List<EdgezSensorSample>>{};
      for (final nodeNum in nodes.keys) {
        samples[nodeNum] = await database.loadSensorSamples(nodeNum);
      }
      session.restoreCachedMeshData(
        nodes: nodes,
        conversations: conversations,
        sensorSamples: samples,
      );
      lastPersistSignature = _persistenceSignature(session.state);
      if (!mounted) return;
      setState(() {
        databaseReady = true;
        persistenceEnabled = true;
        hydrationComplete = true;
        dashboardDisplays = savedDashboardDisplays;
        speedMetrics = loadedSpeedMetrics;
        lastPersistedSpeedMetricMs = loadedSpeedMetrics.isEmpty
            ? 0
            : loadedSpeedMetrics.last.timestampMs;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        databaseReady = false;
        persistenceEnabled = false;
        hydrationComplete = true;
      });
    }
  }

  void _persistSessionSnapshot() {
    if (!hydrationComplete || !persistenceEnabled) return;
    final state = session.state;
    final signature = _persistenceSignature(state);
    final metricNeedsPersistence =
        (state.sharedLinkStats?.updatedAtMs ?? 0) > lastPersistedSpeedMetricMs;
    if (signature == lastPersistSignature && !metricNeedsPersistence) return;
    persistDebounce?.cancel();
    persistDebounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_persistLatestSessionSnapshot()),
    );
  }

  Future<void> _persistLatestSessionSnapshot() async {
    if (!hydrationComplete || !persistenceEnabled) return;
    if (persistInFlight) {
      persistAgain = true;
      return;
    }

    persistInFlight = true;
    try {
      do {
        persistAgain = false;
        final state = session.state;
        final signature = _persistenceSignature(state);
        final metric = state.sharedLinkStats;
        if (metric != null && metric.updatedAtMs > lastPersistedSpeedMetricMs) {
          await database.insertSpeedMetric(metric);
          lastPersistedSpeedMetricMs = metric.updatedAtMs;
          final cutoff = DateTime.now()
              .subtract(_speedHistoryWindow)
              .millisecondsSinceEpoch;
          final updatedMetrics = <ExampleSpeedMetric>[
            ...speedMetrics.where((item) => item.timestampMs >= cutoff),
            ExampleSpeedMetric(
              timestampMs: metric.updatedAtMs,
              bitsPerSecond: metric.bitsPerSecond,
              packetLossPercent: metric.packetLossPercent,
              receivedPackets: metric.receivedPackets,
              expectedPackets: metric.expectedPackets,
            ),
          ];
          if (mounted) {
            setState(() => speedMetrics = updatedMetrics);
          } else {
            speedMetrics = updatedMetrics;
          }
        }
        if (signature != lastPersistSignature) {
          await database.persistStateSnapshot(state);
          lastPersistSignature = signature;
        }
      } while (persistAgain && persistenceEnabled);
    } catch (_) {
      if (mounted) {
        setState(() => databaseReady = false);
      }
    } finally {
      persistInFlight = false;
    }
  }

  String _persistenceSignature(EdgezMeshState state) {
    final buffer = StringBuffer();
    final nodes = state.nodes.values.toList()
      ..sort((a, b) => a.nodeNum.compareTo(b.nodeNum));
    for (final node in nodes) {
      buffer
        ..write(node.nodeNum)
        ..write('|')
        ..write(node.userUuid)
        ..write('|')
        ..write(node.displayName)
        ..write('|')
        ..write(node.route)
        ..write('|')
        ..write(node.lastSeenMs)
        ..write('|')
        ..write(node.marker)
        ..write('|')
        ..write(node.publicKey)
        ..write('|')
        ..write(node.latitude)
        ..write('|')
        ..write(node.longitude)
        ..write('|')
        ..write(node.deviceType)
        ..write('|')
        ..write(node.geoFenceName)
        ..write('|')
        ..write(node.geoIndex)
        ..write('|')
        ..write(node.sleeping)
        ..write(';');
    }
    final conversations = state.conversations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in conversations) {
      buffer
        ..write('c')
        ..write(entry.key)
        ..write(':');
      for (final message in entry.value) {
        buffer
          ..write(message.timestampMs)
          ..write('|')
          ..write(message.mine)
          ..write('|')
          ..write(message.text)
          ..write('|')
          ..write(message.status)
          ..write('|')
          ..write(message.messageUuid)
          ..write(';');
      }
    }
    final sensorSamples = state.sensorSamples.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in sensorSamples) {
      buffer
        ..write('s')
        ..write(entry.key)
        ..write(':');
      for (final sample in entry.value) {
        final data = sample.data;
        buffer
          ..write(sample.timestampMs)
          ..write('|')
          ..write(data.latitude)
          ..write('|')
          ..write(data.longitude)
          ..write('|')
          ..write(data.altitude)
          ..write('|')
          ..write(data.temperature)
          ..write('|')
          ..write(data.humidity)
          ..write('|')
          ..write(data.pressure)
          ..write('|')
          ..write(data.vibrationAverage)
          ..write('|')
          ..write(data.accelX)
          ..write('|')
          ..write(data.accelY)
          ..write('|')
          ..write(data.accelZ)
          ..write('|')
          ..write(data.gyroX)
          ..write('|')
          ..write(data.gyroY)
          ..write('|')
          ..write(data.gyroZ)
          ..write('|')
          ..write(data.binaryLengthBytes)
          ..write(';');
      }
    }
    return buffer.toString();
  }

  Future<void> _connectBle() async {
    if (session.state.connection == EdgezConnectionType.usb) {
      await session.disconnect();
    }
    preferredTransport = EdgezPreferredTransport.ble;
    selectedUsbDevice = null;
    await bleConfigurationStore
        .setPreferredTransport(EdgezPreferredTransport.ble);
    if (mounted) setState(() {});
    await session.startBleScan();
  }

  Future<void> _stopBleScan() async {
    await session.stopBleScan();
  }

  Future<void> _connectBleDevice(String deviceId) async {
    // Match the Android flow: make the current mesh configuration available
    // before BLE service discovery emits its ready event.
    await _saveAppSettings();
    preferredTransport = EdgezPreferredTransport.ble;
    selectedUsbDevice = null;
    final device = session.state.bleDevices[deviceId] ?? selectedBleDevice;
    if (device != null && device.id == deviceId) {
      selectedBleDevice = device;
      await bleConfigurationStore.saveSelectedDevice(device);
    } else {
      await bleConfigurationStore
          .setPreferredTransport(EdgezPreferredTransport.ble);
    }
    if (mounted) setState(() {});
    try {
      await session.sdk.requestNotificationPermission();
    } on MissingPluginException {
      // Notification support requires a full rebuild after native changes.
    }
    await session.connectBle(deviceId);
  }

  Future<void> _refreshUsbDevices() async {
    try {
      final devices = await session.sdk.listUsbDevices();
      final current = selectedUsbDevice;
      final restored = current == null
          ? null
          : devices.cast<EdgezUsbDevice?>().firstWhere(
                (device) =>
                    device?.vendorId == current.vendorId &&
                    device?.productId == current.productId,
                orElse: () => null,
              );
      if (mounted) {
        setState(() {
          usbDevices = devices;
          if (preferredTransport == EdgezPreferredTransport.usb) {
            selectedUsbDevice = restored;
          }
        });
      }
    } on MissingPluginException {
      // USB support requires a full Android rebuild after native changes.
    }
  }

  Future<void> _connectUsbDevice(EdgezUsbDevice device) async {
    await _saveAppSettings();
    await bleConfigurationStore.saveSelectedUsbDevice(device);
    await bleConfigurationStore.setAutoConnect(false);
    if (mounted) {
      setState(() {
        preferredTransport = EdgezPreferredTransport.usb;
        bleAutoConnect = false;
        selectedBleDevice = null;
        selectedUsbDevice = device;
      });
    }
    try {
      await session.connectUsb(device);
    } catch (error) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('USB connection failed: $error')),
      );
    }
  }

  Future<void> _disconnect() async {
    await session.disconnect();
    setState(() {
      selectedNodeNum = null;
      showTopology = false;
    });
  }

  Future<void> _setDeviceLogLevel(EdgezDeviceLogLevel level) async {
    try {
      await session.configureLogLevel(level);
      if (session.state.connection != EdgezConnectionType.none) {
        await session.setDeviceLogLevel(level);
      }
      await bleConfigurationStore.setLogLevel(level);
      if (mounted) setState(() => deviceLogLevel = level);
    } catch (error) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Unable to set device log level: $error')),
      );
    }
  }

  Future<void> _exportDeviceLogs() async {
    File? stagedFile;
    try {
      stagedFile = await deviceLogStore.export();
      final fileName = stagedFile.uri.pathSegments.last;
      final downloadedName = await _downloadsChannel.invokeMethod<String>(
        'saveToDownloads',
        <String, String>{
          'sourcePath': stagedFile.path,
          'fileName': fileName,
        },
      );
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded to Downloads/${downloadedName ?? fileName}',
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Public Downloads write failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Unable to download logs: $error')),
      );
    } finally {
      if (stagedFile != null && await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  Future<void> _pruneDeviceLogs() async {
    try {
      await session.pruneDeviceLogs();
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Logs pruned')),
      );
    } catch (error) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Unable to prune logs: $error')),
      );
    }
  }

  Future<void> _saveAppSettings() async {
    final parsedMaxHop = int.tryParse(maxHop) ?? 0;
    final identity = await identityStore.updateName(userName);
    final location = shareLocation && !deviceGpsEnabled
        ? await _getBestKnownLocation()
        : null;
    if (mounted) {
      setState(() {
        userIdentity = identity;
        userName = identity.name;
      });
    }
    await session.initializeMesh(
      EdgezMeshConfig(
        countryCode: meshCountry,
        meshId: meshId.trim(),
        passphrase: passphrase,
        maxHop: parsedMaxHop,
        meshBandwidthMhz: meshBandwidthMhz,
        meshFrequencyKhz: meshFrequencyKhz,
        beacon: EdgezBeaconConfig(
          intervalSeconds: int.tryParse(beaconIntervalSeconds) ?? 10,
          marker: userMarker.name,
          shareLocation: shareLocation,
          useDeviceGps: deviceGpsEnabled,
          latitude: location?.latitude,
          longitude: location?.longitude,
          locationTimestampMs: location?.timestampMs ?? 0,
        ),
        identity: EdgezUserIdentity(
          userUuid: identity.userUuid,
          userIdHigh: identity.userIdHigh,
          userIdLow: identity.userIdLow,
          name: identity.name,
          privateKey: identity.privateKey,
          publicKey: identity.publicKey,
        ),
      ),
    );
    final currentSettings = session.state.deviceSettings;
    if (currentSettings != null &&
        currentSettings.deviceGpsEnabled != deviceGpsEnabled) {
      await session.setDeviceGpsEnabled(deviceGpsEnabled);
    }
  }

  Future<void> _regenerateUserKeyPair() async {
    final identity = await identityStore.regenerateKeyPair();
    if (!mounted) return;
    setState(() => userIdentity = identity);
  }

  Future<void> _saveDeviceSettings() async {
    if (deviceShareLocation && !deviceGpsEnabled) {
      await _refreshDeviceLocation();
    }
    final latitude = double.tryParse(deviceLatitude);
    final longitude = double.tryParse(deviceLongitude);
    if (deviceShareLocation &&
        !deviceGpsEnabled &&
        (latitude == null || longitude == null)) {
      throw StateError('No phone location is available for the device');
    }
    final scripts = <EdgezSensorScriptConfig>[];
    for (final key in <String>[uartI2cSensorType, rs485SensorType]) {
      if (key.isEmpty) continue;
      final driver = drivers.where((item) => item.key == key).firstOrNull;
      if (driver != null) scripts.add(await driver.loadScript());
    }
    await session.sendDeviceSettings(
      EdgezDeviceSettings(
        deviceModeEnabled: deviceModeEnabled,
        meshId: deviceMeshId.trim(),
        shareLocation: deviceShareLocation,
        userName: deviceUserName.trim(),
        marker: deviceMarker.name,
        beaconIntervalSeconds: int.tryParse(deviceBeaconIntervalSeconds) ?? 10,
        maxHop: int.tryParse(deviceMaxHop) ?? 0,
        latitude: deviceShareLocation && !deviceGpsEnabled ? latitude : null,
        longitude: deviceShareLocation && !deviceGpsEnabled ? longitude : null,
        geoFenceName: deviceGeoFenceName.trim(),
        geoIndex: deviceGeoIndex,
        uartI2cSensorType: uartI2cSensorType,
        rs485SensorType: rs485SensorType,
        passphrase: devicePassphrase,
        upstreamWifiSsid:
            deviceUpstreamEnabled ? deviceUpstreamWifiSsid.trim() : '',
        upstreamWifiPassphrase:
            deviceUpstreamEnabled ? deviceUpstreamWifiPassphrase : '',
        beaconUnicast: deviceUpstreamEnabled
            ? _parseIpv4Address(deviceBeaconMulticast)
            : 0,
        deviceType: deviceType,
        sleepModeEnabled: deviceSleepModeEnabled,
        deviceGpsEnabled: deviceGpsEnabled,
        meshFrequencyKhz: meshFrequencyKhz,
        meshBandwidthMhz: meshBandwidthMhz,
      ),
      scripts: scripts,
    );
  }

  Future<void> _refreshDeviceLocation() async {
    final location = await _getBestKnownLocation();
    if (location == null || !mounted) return;
    setState(() {
      deviceLatitude = location.latitude.toStringAsFixed(6);
      deviceLongitude = location.longitude.toStringAsFixed(6);
    });
  }

  Future<EdgezLocation?> _getBestKnownLocation() async {
    try {
      final location = await session.sdk.getBestKnownLocation();
      if (mounted) {
        setState(() {
          locationMessage = location == null
              ? 'No phone location is available yet'
              : 'Phone location: ${location.latitude.toStringAsFixed(6)}, '
                  '${location.longitude.toStringAsFixed(6)}';
        });
      }
      return location;
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          locationMessage = 'Location support was added to the native plugin. '
              'Fully stop and run the app again (hot reload is not enough).';
        });
      }
      return null;
    } catch (error) {
      if (mounted) {
        setState(() => locationMessage = 'Location unavailable: $error');
      }
      return null;
    }
  }

  void _setShareLocation(bool value) {
    setState(() => shareLocation = value);
    unawaited(bleConfigurationStore.setShareLocation(value));
    if (value && !deviceGpsEnabled) unawaited(_getBestKnownLocation());
  }

  void _setDeviceShareLocation(bool value) {
    setState(() => deviceShareLocation = value);
    if (value && !deviceGpsEnabled) unawaited(_refreshDeviceLocation());
  }

  void _setDeviceGpsEnabled(bool value) {
    setState(() => deviceGpsEnabled = value);
    if (!value) {
      if (deviceModeEnabled && deviceShareLocation) {
        unawaited(_refreshDeviceLocation());
      } else if (!deviceModeEnabled && shareLocation) {
        unawaited(_getBestKnownLocation());
      }
    }
  }

  void _handleDeviceGpsState() {
    final settings = session.state.deviceSettings;
    final selfLocation = session.state.selfLocation;
    if (identical(settings, observedDeviceSettings) &&
        identical(selfLocation, observedSelfLocation)) {
      return;
    }
    observedDeviceSettings = settings;
    observedSelfLocation = selfLocation;
    if (!mounted) return;
    setState(() {
      if (settings != null) {
        deviceGpsEnabled = settings.deviceGpsEnabled;
      }
      if (selfLocation != null) {
        locationMessage = 'Device GPS: '
            '${selfLocation.latitude.toStringAsFixed(6)}, '
            '${selfLocation.longitude.toStringAsFixed(6)}';
      }
    });
  }

  Future<void> _checkForOtaUpdate() async {
    if (otaCheckInProgress ||
        otaInstallInProgress ||
        session.state.otaInProgress) {
      return;
    }
    setState(() {
      otaCheckInProgress = true;
      otaMessage = 'Checking for firmware updates...';
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(Uri.parse(_otaManifestUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Firmware check failed: HTTP ${response.statusCode}');
      }
      final json = jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>;
      final release = EdgezOtaRelease.fromJson(json);
      if (!mounted) return;
      setState(() {
        otaRelease = release;
        otaMessage = release.isNewerThan(
          session.state.status?.firmwareVersion ?? '',
        )
            ? 'Update available: ${release.version}'
            : 'Your firmware is up to date';
      });
    } catch (error) {
      if (mounted) setState(() => otaMessage = '$error');
    } finally {
      client.close(force: true);
      if (mounted) setState(() => otaCheckInProgress = false);
    }
  }

  Future<void> _installOtaUpdate() async {
    final release = otaRelease;
    if (release == null ||
        otaInstallInProgress ||
        session.state.otaInProgress) {
      return;
    }
    if (!session.state.otaReady) {
      setState(() => otaMessage = 'Reconnect to a device with BLE OTA support');
      return;
    }
    setState(() {
      otaInstallInProgress = true;
      otaMessage = 'Downloading ${release.version}...';
    });
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(release.url));
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
            'Firmware download failed: HTTP ${response.statusCode}');
      }
      final image =
          await response.timeout(const Duration(seconds: 30)).fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      if (image.length != release.size) {
        throw StateError(
          'Firmware size mismatch: ${image.length}/${release.size}',
        );
      }
      await session.performOta(image);
      if (mounted) {
        setState(
            () => otaMessage = 'Firmware uploaded. The device is restarting.');
      }
    } catch (error) {
      if (mounted) setState(() => otaMessage = '$error');
    } finally {
      client.close(force: true);
      if (mounted) setState(() => otaInstallInProgress = false);
    }
  }

  void _openNode(EdgezMeshNode node) {
    setState(() => selectedNodeNum = node.nodeNum);
  }

  ExampleDashboardDisplay _dashboardDisplayFor(EdgezMeshNode node) {
    return dashboardDisplays[node.exampleUserId] ??
        ExampleDashboardDisplay(deviceKey: node.exampleUserId);
  }

  Future<void> _setDashboardDisplay(ExampleDashboardDisplay display) async {
    if (persistenceEnabled) {
      await database.setDashboardDisplay(display);
    }
    if (!mounted) return;
    setState(() {
      dashboardDisplays = <String, ExampleDashboardDisplay>{
        ...dashboardDisplays,
        display.deviceKey: display,
      };
    });
  }

  void _toggleDashboard(EdgezMeshNode node) {
    final current = _dashboardDisplayFor(node);
    unawaited(_setDashboardDisplay(
        current.copyWith(showOnDashboard: !current.showOnDashboard)));
  }

  void _removeNode(EdgezMeshNode node) {
    session.removeNode(node.nodeNum);
    if (persistenceEnabled) {
      unawaited(_deletePersistedNode(node.nodeNum));
    }
    if (selectedNodeNum == node.nodeNum) {
      setState(() => selectedNodeNum = null);
    }
  }

  Future<void> _deletePersistedNode(int nodeNum) async {
    persistDebounce?.cancel();
    while (persistInFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!persistenceEnabled) return;
    await database.deleteNode(nodeNum);
    lastPersistSignature = _persistenceSignature(session.state);
  }

  Future<void> _sendMessage(String text) async {
    final nodeNum = selectedNodeNum;
    if (nodeNum == null) return;
    await session.sendTextMessage(
      toNode: nodeNum,
      text: text,
      maxHop: int.tryParse(maxHop) ?? 0,
    );
  }

  Future<bool> _startVoiceMessage() {
    return session.startVoiceMessage();
  }

  Future<void> _startSpeedTest(
    int hop,
    void Function(int sentBytes, int totalBytes) onProgress,
  ) async {
    final nodeNum = selectedNodeNum;
    if (nodeNum == null) return;
    await session.sendSpeedTest(
      toNode: nodeNum,
      hop: hop,
      onProgress: onProgress,
    );
  }

  Future<void> _stopVoiceMessage(bool send) async {
    final nodeNum = selectedNodeNum;
    if (!send || nodeNum == null) {
      await session.cancelVoiceMessage();
      return;
    }
    await session.finishVoiceMessage(
      toNode: nodeNum,
      send: send,
      maxHop: int.tryParse(maxHop) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final meshState = session.state;
        final callPeerNodeNum = meshState.voiceCall.peerNodeNum;
        final callPeer =
            callPeerNodeNum == null ? null : meshState.nodes[callPeerNodeNum];
        final selected =
            selectedNodeNum == null ? null : meshState.nodes[selectedNodeNum!];
        final body = switch (destination) {
          AppDestination.dashboard => selected == null
              ? DashboardScreen(
                  activeConnection: meshState.connection,
                  status: meshState.status,
                  users: meshState.sortedNodes,
                  sensorSamples: meshState.sensorSamples,
                  dashboardDisplays: dashboardDisplays,
                  onOpenProvisioning: _openProvisioning,
                  onOpenNode: _openNode,
                )
              : selected.opensConversation
                  ? ConversationScreen(
                      activeConnection: meshState.connection,
                      user: selected,
                      messages: meshState.conversations[selected.nodeNum] ??
                          const <EdgezConversationMessage>[],
                      sensorSamples:
                          meshState.sensorSamples[selected.nodeNum] ??
                              const <EdgezSensorSample>[],
                      linkStats: meshState.linkStats[selected.nodeNum],
                      onBack: () => setState(() => selectedNodeNum = null),
                      onSendMessage: _sendMessage,
                      onStartVoiceMessage: _startVoiceMessage,
                      onStopVoiceMessage: _stopVoiceMessage,
                      onReplayVoiceMessage: session.playVoiceMessage,
                      onStartSpeedTest: _startSpeedTest,
                      callState: meshState.voiceCall,
                      onStartCall: () =>
                          session.startVoiceCall(selected.nodeNum),
                    )
                  : DeviceDetailScreen(
                      user: selected,
                      samples: meshState.sensorSamples[selected.nodeNum] ??
                          const <EdgezSensorSample>[],
                      dashboardDisplay: _dashboardDisplayFor(selected),
                      onDashboardDisplayChanged: (display) =>
                          unawaited(_setDashboardDisplay(display)),
                      onBack: () => setState(() => selectedNodeNum = null),
                    ),
          AppDestination.nodes => showTopology
              ? TopologyScreen(
                  users: meshState.sortedNodes,
                  links: meshState.topologyLinks,
                  onBack: () => setState(() => showTopology = false),
                )
              : selected == null
                  ? NodesScreen(
                      activeConnection: meshState.connection,
                      status: meshState.status,
                      users: meshState.sortedNodes,
                      sensorSamples: meshState.sensorSamples,
                      dashboardDisplays: dashboardDisplays,
                      onOpenTopology: () => setState(() => showTopology = true),
                      onRemoveNode: _removeNode,
                      onToggleDashboard: _toggleDashboard,
                      onOpenNode: _openNode,
                    )
                  : selected.opensConversation
                      ? ConversationScreen(
                          activeConnection: meshState.connection,
                          user: selected,
                          messages: meshState.conversations[selected.nodeNum] ??
                              const <EdgezConversationMessage>[],
                          sensorSamples:
                              meshState.sensorSamples[selected.nodeNum] ??
                                  const <EdgezSensorSample>[],
                          linkStats: meshState.linkStats[selected.nodeNum],
                          onBack: () => setState(() => selectedNodeNum = null),
                          onSendMessage: _sendMessage,
                          onStartVoiceMessage: _startVoiceMessage,
                          onStopVoiceMessage: _stopVoiceMessage,
                          onReplayVoiceMessage: session.playVoiceMessage,
                          onStartSpeedTest: _startSpeedTest,
                          callState: meshState.voiceCall,
                          onStartCall: () =>
                              session.startVoiceCall(selected.nodeNum),
                        )
                      : DeviceDetailScreen(
                          user: selected,
                          samples: meshState.sensorSamples[selected.nodeNum] ??
                              const <EdgezSensorSample>[],
                          dashboardDisplay: _dashboardDisplayFor(selected),
                          onDashboardDisplayChanged: (display) =>
                              unawaited(_setDashboardDisplay(display)),
                          onBack: () => setState(() => selectedNodeNum = null),
                        ),
          AppDestination.drivers => DriversScreen(
              drivers: drivers,
              driverStore: driverStore,
              installRequest: pendingDriverInstall,
              onInstallHandled: _driverInstallHandled,
              onInstalled: _loadInstalledDrivers,
            ),
          AppDestination.settings => showDebug
              ? DebugScreen(
                  activeConnection: meshState.connection,
                  meshStatus: meshState.status,
                  statusLine: meshState.statusLine,
                  nodeCount: meshState.nodes.length,
                  conversationCount: meshState.conversations.length,
                  shareLocation: shareLocation,
                  deviceModeEnabled: deviceModeEnabled,
                  databaseReady: databaseReady,
                  speedMetrics: speedMetrics,
                  debugLogs: meshState.debugLogs,
                  onExportLogs: () => unawaited(_exportDeviceLogs()),
                  onPruneLogs: () => unawaited(_pruneDeviceLogs()),
                  onClose: () => setState(() => showDebug = false),
                )
              : SettingsScreen(
                  activeConnection: meshState.connection,
                  bleConnecting: meshState.bleConnecting,
                  bleReady: meshState.bleReady,
                  shareLocation: shareLocation,
                  autoReplayReceivedVoice: autoReplayReceivedVoice,
                  deviceModeEnabled: deviceModeEnabled,
                  bleDevices: meshState.sortedBleDevices,
                  usbDevices: usbDevices,
                  drivers: drivers,
                  selectedBleDevice: selectedBleDevice,
                  selectedUsbDevice: selectedUsbDevice,
                  usbLinkStats: meshState.usbLinkStats,
                  meshStatus: meshState.status,
                  bleAutoConnect: bleAutoConnect,
                  statusLine: meshState.statusLine,
                  otaUpdateAvailable: otaRelease?.isNewerThan(
                        meshState.status?.firmwareVersion ?? '',
                      ) ??
                      false,
                  otaReady: meshState.otaReady,
                  otaCheckInProgress: otaCheckInProgress,
                  otaInProgress:
                      otaInstallInProgress || meshState.otaInProgress,
                  otaProgress:
                      meshState.otaInProgress ? meshState.otaProgress : 0,
                  otaMessage: meshState.otaInProgress && otaRelease != null
                      ? 'Installing ${otaRelease!.version}: '
                          '${(meshState.otaProgress * 100).floor()}%'
                      : otaMessage,
                  locationMessage: locationMessage,
                  meshCountry: meshCountry,
                  meshId: meshId,
                  passphrase: passphrase,
                  maxHop: maxHop,
                  meshBandwidthMhz: meshBandwidthMhz,
                  meshFrequencyKhz: meshFrequencyKhz,
                  beaconIntervalSeconds: beaconIntervalSeconds,
                  userName: userName,
                  userIdentity: userIdentity,
                  userMarker: userMarker,
                  deviceUserName: deviceUserName,
                  deviceMarker: deviceMarker,
                  deviceMeshId: deviceMeshId,
                  deviceMaxHop: deviceMaxHop,
                  deviceBeaconIntervalSeconds: deviceBeaconIntervalSeconds,
                  deviceShareLocation: deviceShareLocation,
                  deviceGpsEnabled: deviceGpsEnabled,
                  deviceGpsLocation: meshState.selfLocation,
                  deviceLatitude: deviceLatitude,
                  deviceLongitude: deviceLongitude,
                  deviceGeoFenceName: deviceGeoFenceName,
                  deviceGeoIndex: deviceGeoIndex,
                  uartI2cSensorType: uartI2cSensorType,
                  rs485SensorType: rs485SensorType,
                  deviceType: deviceType,
                  devicePassphrase: devicePassphrase,
                  deviceUpstreamEnabled: deviceUpstreamEnabled,
                  deviceUpstreamWifiSsid: deviceUpstreamWifiSsid,
                  deviceUpstreamWifiPassphrase: deviceUpstreamWifiPassphrase,
                  deviceBeaconMulticast: deviceBeaconMulticast,
                  deviceSleepModeEnabled: deviceSleepModeEnabled,
                  logLevel: deviceLogLevel,
                  onConnectBle: _connectBle,
                  onStopBleScan: _stopBleScan,
                  onConnectBleDevice: _connectBleDevice,
                  onSelectBleDevice: (device) {
                    setState(() {
                      preferredTransport = EdgezPreferredTransport.ble;
                      selectedBleDevice = device;
                      selectedUsbDevice = null;
                    });
                    unawaited(bleConfigurationStore.saveSelectedDevice(device));
                  },
                  onRefreshUsbDevices: _refreshUsbDevices,
                  onConnectUsbDevice: (device) =>
                      unawaited(_connectUsbDevice(device)),
                  onBleAutoConnectChanged: (value) {
                    setState(() => bleAutoConnect = value);
                    unawaited(bleConfigurationStore.setAutoConnect(value));
                  },
                  onDisconnect: _disconnect,
                  onOpenDebug: () => setState(() => showDebug = true),
                  onCheckForOtaUpdate: _checkForOtaUpdate,
                  onInstallOtaUpdate: _installOtaUpdate,
                  onSaveAppSettings: _saveAppSettings,
                  onRegenerateUserKeyPair: _regenerateUserKeyPair,
                  onSaveDeviceSettings: _saveDeviceSettings,
                  onShareLocationChanged: _setShareLocation,
                  onAutoReplayChanged: (value) =>
                      setState(() => autoReplayReceivedVoice = value),
                  onDeviceModeChanged: (value) =>
                      setState(() => deviceModeEnabled = value),
                  onMeshCountryChanged: (value) => setState(() {
                    meshCountry = value;
                    final bandwidths = halowBandwidthOptions(value);
                    if (!bandwidths.contains(meshBandwidthMhz)) {
                      meshBandwidthMhz = bandwidths.first;
                    }
                    final frequencies =
                        halowFrequenciesKhz(value, meshBandwidthMhz);
                    if (!frequencies.contains(meshFrequencyKhz)) {
                      meshFrequencyKhz = frequencies.first;
                    }
                  }),
                  onMeshBandwidthChanged: (value) => setState(() {
                    meshBandwidthMhz = value;
                    final frequencies = halowFrequenciesKhz(meshCountry, value);
                    if (!frequencies.contains(meshFrequencyKhz)) {
                      meshFrequencyKhz = frequencies.first;
                    }
                  }),
                  onMeshFrequencyChanged: (value) =>
                      setState(() => meshFrequencyKhz = value),
                  onMeshIdChanged: (value) => setState(() => meshId = value),
                  onPassphraseChanged: (value) =>
                      setState(() => passphrase = value),
                  onMaxHopChanged: (value) => setState(() => maxHop = value),
                  onBeaconIntervalChanged: (value) =>
                      setState(() => beaconIntervalSeconds = value),
                  onUserNameChanged: (value) =>
                      setState(() => userName = value),
                  onUserMarkerChanged: (value) =>
                      setState(() => userMarker = value),
                  onDeviceUserNameChanged: (value) =>
                      setState(() => deviceUserName = value),
                  onDeviceMarkerChanged: (value) =>
                      setState(() => deviceMarker = value),
                  onDeviceMeshIdChanged: (value) =>
                      setState(() => deviceMeshId = value),
                  onDeviceMaxHopChanged: (value) =>
                      setState(() => deviceMaxHop = value),
                  onDeviceBeaconIntervalChanged: (value) =>
                      setState(() => deviceBeaconIntervalSeconds = value),
                  onDeviceShareLocationChanged: _setDeviceShareLocation,
                  onDeviceGpsEnabledChanged: _setDeviceGpsEnabled,
                  onRefreshDeviceLocation: _refreshDeviceLocation,
                  onDeviceLatitudeChanged: (value) =>
                      setState(() => deviceLatitude = value),
                  onDeviceLongitudeChanged: (value) =>
                      setState(() => deviceLongitude = value),
                  onDeviceGeoFenceNameChanged: (value) =>
                      setState(() => deviceGeoFenceName = value),
                  onDeviceGeoIndexChanged: (value) =>
                      setState(() => deviceGeoIndex = value),
                  onUartI2cSensorChanged: (value) =>
                      setState(() => uartI2cSensorType = value),
                  onRs485SensorChanged: (value) =>
                      setState(() => rs485SensorType = value),
                  onDeviceTypeChanged: (value) =>
                      setState(() => deviceType = value),
                  onDevicePassphraseChanged: (value) =>
                      setState(() => devicePassphrase = value),
                  onDeviceUpstreamEnabledChanged: (value) =>
                      setState(() => deviceUpstreamEnabled = value),
                  onDeviceUpstreamWifiSsidChanged: (value) =>
                      setState(() => deviceUpstreamWifiSsid = value),
                  onDeviceUpstreamWifiPassphraseChanged: (value) =>
                      setState(() => deviceUpstreamWifiPassphrase = value),
                  onDeviceBeaconMulticastChanged: (value) =>
                      setState(() => deviceBeaconMulticast = value),
                  onDeviceSleepModeChanged: (value) =>
                      setState(() => deviceSleepModeEnabled = value),
                  onLogLevelChanged: (level) =>
                      unawaited(_setDeviceLogLevel(level)),
                ),
        };

        return MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
            cardTheme: const CardThemeData(margin: EdgeInsets.zero),
          ),
          home: !meshState.voiceCall.isIdle
              ? VoiceCallScreen(
                  call: meshState.voiceCall,
                  peer: callPeer,
                  onAnswer: _answerCall,
                  onEnd: _endCall,
                )
              : provisionMode
                  ? ProvisioningScreen(
                      session: session,
                      drivers: drivers,
                      excludedBleDeviceId: selectedBleDevice?.id,
                      defaultMeshId: meshId,
                      defaultPassphrase: passphrase,
                      defaultMaxHop: maxHop,
                      defaultBeaconInterval: beaconIntervalSeconds,
                      defaultMeshCountry: meshCountry,
                      defaultMeshFrequencyKhz: meshFrequencyKhz,
                      defaultMeshBandwidthMhz: meshBandwidthMhz,
                      onCancel: _closeProvisioning,
                      onComplete: _closeProvisioning,
                    )
                  : Scaffold(
                      body: body,
                      bottomNavigationBar: NavigationBar(
                        selectedIndex:
                            AppDestination.values.indexOf(destination),
                        onDestinationSelected: (index) => setState(() {
                          destination = AppDestination.values[index];
                          showDebug = false;
                          if (destination != AppDestination.nodes) {
                            selectedNodeNum = null;
                            showTopology = false;
                          }
                        }),
                        destinations: AppDestination.values.map((item) {
                          return NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          );
                        }).toList(),
                      ),
                    ),
        );
      },
    );
  }

  int _parseIpv4Address(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return 0;
    var result = 0;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return 0;
      result = (result << 8) | octet;
    }
    return result;
  }
}
