// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectRelayWifi =>
      'Choose Upstream Wi-Fi or SoftAP before continuing.';

  @override
  String get relayWifi => 'Relay Wi-Fi';

  @override
  String get upstreamWifi => 'Upstream Wi-Fi';

  @override
  String get softapProvisioningDescription =>
      'SoftAP uses the mesh SSID and passphrase from the Network step. Leave the passphrase empty for an open network.';

  @override
  String get invalidRelayWifi =>
      'Use an SSID of 1–32 bytes and an empty password or 8–63 bytes. Upstream Wi-Fi also accepts a 64-digit hexadecimal PSK.';

  @override
  String get clearBleSelection => 'Clear';

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get nodes => 'Nodes';

  @override
  String get map => 'Map';

  @override
  String get drivers => 'Drivers';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Choose the language used by the app';

  @override
  String get deviceConnection => 'Device connection';

  @override
  String get select => 'Select';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting...';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get autoConnect => 'Auto connect';

  @override
  String get autoConnectDescription =>
      'Connect the selected BLE device on app start and reconnect if it drops';

  @override
  String get user => 'User';

  @override
  String get meshNetwork => 'Mesh Network';

  @override
  String get others => 'Others';

  @override
  String get deviceUser => 'Device user';

  @override
  String get userName => 'User name';

  @override
  String get deviceUserName => 'Device user name';

  @override
  String get marker => 'Marker';

  @override
  String get location => 'Location';

  @override
  String get deviceLocation => 'Device location';

  @override
  String get shareLocation => 'Share location';

  @override
  String get shareLocationDescription => 'Include location in HaLow beacon';

  @override
  String get country => 'Country';

  @override
  String get bandwidth => 'Bandwidth';

  @override
  String get channel => 'Channel';

  @override
  String get meshId => 'Mesh ID / SSID';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get maxHop => 'Max hop';

  @override
  String get beaconInterval => 'Beacon interval (seconds)';

  @override
  String get saveSettings => 'Save settings';

  @override
  String get logging => 'Logging';

  @override
  String get logLevel => 'Log level';

  @override
  String get chat => 'Chat';

  @override
  String get defaultTranslationLanguage => 'Default translation language';

  @override
  String get autoReplayVoice => 'Auto replay received voice';

  @override
  String get autoReplayVoiceDescription =>
      'Play new incoming voice messages automatically';

  @override
  String get debug => 'Debug';

  @override
  String get back => 'Back';

  @override
  String get deviceMode => 'Device mode';

  @override
  String get phoneMode => 'Phone mode';

  @override
  String get checkForUpdate => 'Check for update';

  @override
  String get checking => 'Checking...';

  @override
  String get update => 'Update';

  @override
  String get marketplace => 'Marketplace';

  @override
  String get cancel => 'Cancel';

  @override
  String get install => 'Install';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving';

  @override
  String get loading => 'Loading';

  @override
  String get next => 'Next';

  @override
  String get download => 'Download';

  @override
  String get notNow => 'Not now';

  @override
  String get refresh => 'Refresh';

  @override
  String get delete => 'Delete';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get device => 'Device';

  @override
  String get dashboardVisualization => 'Dashboard visualization';

  @override
  String get widget => 'Widget';

  @override
  String get range => 'Range';

  @override
  String get type => 'Type';

  @override
  String get sleeping => 'Sleeping';

  @override
  String get geoFence => 'Geo fence';

  @override
  String get none => 'None';

  @override
  String get sensor => 'Sensor';

  @override
  String get noSensorData => 'No sensor data received yet';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get pressure => 'Pressure';

  @override
  String get altitude => 'Altitude';

  @override
  String get sensorTimeSeries => 'Sensor time series';

  @override
  String get provisioning => 'Provisioning';

  @override
  String get selectBleDevice => 'Select BLE device';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get scanningDevices => 'Scanning for EdgeZ devices...';

  @override
  String get beacon => 'Beacon';

  @override
  String get relay => 'Relay';

  @override
  String get network => 'Network';

  @override
  String get frequency => 'Frequency';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get usePhoneLocation => 'Use phone location';

  @override
  String get enableGeoFence => 'Enable geo fence';

  @override
  String get geoFenceName => 'Geo fence name';

  @override
  String get geoIndex => 'Geo index';

  @override
  String get sensorDrivers => 'Sensor drivers';

  @override
  String get sleepMode => 'Sleep mode';

  @override
  String get enableSleepMode => 'Enable sleep mode';

  @override
  String get sleepModeDescription =>
      'Allow the device to enter low-power sleep.';

  @override
  String get answer => 'Answer';

  @override
  String get decline => 'Decline';

  @override
  String get end => 'End';

  @override
  String get holdToTalk => 'Hold to Talk';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get hop => 'Hop';

  @override
  String get routes => 'Routes';

  @override
  String get publicChannels => 'Public channels';

  @override
  String get system => 'System';

  @override
  String get deviceLogs => 'Device logs';

  @override
  String get transport => 'Transport';

  @override
  String get prune => 'Prune';

  @override
  String get open => 'Open';

  @override
  String get meshOverview => 'Mesh overview';

  @override
  String get interfaceLabel => 'Interface';

  @override
  String get knownNodes => 'Known nodes';

  @override
  String get license => 'License';

  @override
  String get visualizationWidgets => 'Visualization widgets';

  @override
  String get noDashboardDevices => 'No dashboard devices yet';

  @override
  String get temp => 'Temp';

  @override
  String get passByScore => 'Pass-by score';

  @override
  String get backToSettings => 'Back to settings';

  @override
  String get speedAndLoss => 'Speed and loss · last 30 minutes';

  @override
  String get movingSpeed => 'Moving speed';

  @override
  String get movingLoss => 'Moving loss';

  @override
  String get speed => 'Speed';

  @override
  String get loss => 'Loss';

  @override
  String get activeConnection => 'Active connection';

  @override
  String get status => 'Status';

  @override
  String get conversations => 'Conversations';

  @override
  String get database => 'Database';

  @override
  String get halowMesh => 'HaLow mesh';

  @override
  String get supported => 'Supported';

  @override
  String get initialized => 'Initialized';

  @override
  String get meshMode => 'Mesh mode';

  @override
  String get linkUp => 'Link up';

  @override
  String get routeReady => 'Route ready';

  @override
  String get readyForReport => 'Ready for report';

  @override
  String get gateway => 'Gateway';

  @override
  String get sdkEvents => 'SDK events';

  @override
  String get logStream => 'Log stream';

  @override
  String get links => 'Links';

  @override
  String get window => 'Window';

  @override
  String get direct => 'Direct';

  @override
  String get relayed => 'Relayed';

  @override
  String get refreshRouting => 'Refresh routing table';

  @override
  String get downloadOfflineMap => 'Download offline map';

  @override
  String get transcribeAgain => 'Transcribe again using the Settings language';

  @override
  String get speakTranslation => 'Speak translation';

  @override
  String get upstreamNetwork => 'Upstream network';

  @override
  String get refreshUsb => 'Refresh USB devices';

  @override
  String get uartConnector => 'UART / I2C connector';

  @override
  String get rs485Connector => 'RS485 connector';

  @override
  String get upstreamWifiSsid => 'Upstream Wi-Fi SSID';

  @override
  String get upstreamWifiPassphrase => 'Upstream Wi-Fi passphrase';

  @override
  String get beaconMulticast => 'Beacon multicast';

  @override
  String get loggingHelper => 'Applies to device output and app log storage';

  @override
  String incomingCallFrom(String name) {
    return 'Incoming call from $name';
  }

  @override
  String get selectedDevice => 'Selected device';

  @override
  String get noDeviceSelected => 'No device selected';

  @override
  String get usbConnected => 'USB connected; high-speed channel ready';

  @override
  String get bleControlReady => 'BLE connected; control channel ready';

  @override
  String get bleSettingUp => 'BLE connected; setting up control channel';

  @override
  String get blePairing => 'BLE pairing or connecting';

  @override
  String get disconnected => 'Disconnected';

  @override
  String firmwareVersion(String version) {
    return 'Firmware: $version';
  }

  @override
  String get waitingBle => 'Waiting for BLE connection';

  @override
  String get connectBleDevice => 'Connect a BLE device';

  @override
  String get waitingBleControl => 'Waiting for BLE control channel';

  @override
  String get waitingDeviceStatus => 'Waiting for device status';

  @override
  String updatingProgress(int percent) {
    return 'Updating $percent%';
  }

  @override
  String get otaUnsupported =>
      'This connected firmware does not expose BLE OTA yet.';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => 'Not loaded';

  @override
  String get useDeviceGps => 'Use device GPS (L76K)';

  @override
  String get deviceGpsDescription =>
      'Use periodic low-power device fixes instead of phone/static location';

  @override
  String deviceFix(String latitude, String longitude) {
    return 'Device fix: $latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => 'Refresh phone location';

  @override
  String get geofenceBeaconDescription =>
      'Include a geofence in device beacons';

  @override
  String get enableSensors => 'Enable sensors';

  @override
  String get sensorConnectorDescription => 'Configure device sensor connectors';

  @override
  String get enableUpstreamNetwork => 'Enable upstream network';

  @override
  String get upstreamDescription =>
      'Forward through Wi-Fi and send beacons to a multicast address.';

  @override
  String get notSet => 'Not set';

  @override
  String get translationLanguageDescription =>
      'Used as the initial target language in conversations. The spoken language is detected once and saved with the transcript on the message.';

  @override
  String get selectBleOrUsb => 'Select BLE or USB device';

  @override
  String get noUsbDevices =>
      'No USB devices attached. Connect with a USB OTG cable.';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get userIdentity => 'User identity';

  @override
  String get loadingIdentity => 'Loading identity';

  @override
  String get publicKey => 'X25519 public key';

  @override
  String get privateKey => 'X25519 private key';

  @override
  String get regenerateKeyPair => 'Regenerate key pair';

  @override
  String get recording => 'Recording';

  @override
  String get requestingMicrophone => 'Requesting microphone';

  @override
  String get microphoneDenied => 'Microphone permission denied';

  @override
  String get startingVoice => 'Starting voice';

  @override
  String get voiceCancelled => 'Voice cancelled';

  @override
  String get sendingVoice => 'Sending voice';

  @override
  String get voiceSent => 'Voice sent';

  @override
  String get sending => 'Sending';

  @override
  String get sentToDevice => 'Sent to device';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get waitingForKey => 'Waiting for key';

  @override
  String get joinTalkgroup => 'Join OpenMANET talkgroup';

  @override
  String get startVoiceCall => 'Start voice call';

  @override
  String get noSensorGps => 'No sensor GPS';

  @override
  String get connectToSendVoice => 'Connect to send voice';

  @override
  String get translateVoice => 'Translate voice';

  @override
  String get checkingTranslation => 'Checking offline translation…';

  @override
  String get offlineTranslation => 'Offline translation · 2.6 GB';

  @override
  String get installGemma => 'Install Gemma 4 to translate';

  @override
  String get noReplayData => 'No replay data';

  @override
  String get tapToReplay => 'Tap to replay';

  @override
  String get transcript => 'Transcript';

  @override
  String translationFailed(String error) {
    return 'Translation failed: $error';
  }

  @override
  String speechFailed(String error) {
    return 'Speech failed: $error';
  }

  @override
  String get delivered => 'Delivered';

  @override
  String get incomingVoiceCall => 'Incoming voice call';

  @override
  String get calling => 'Calling…';

  @override
  String get connected => 'Connected';

  @override
  String get callEnded => 'Call ended';

  @override
  String get meshUser => 'Mesh user';

  @override
  String get transmitting => 'Transmitting…';

  @override
  String callActionFailed(String error) {
    return 'Call action failed: $error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return 'Voice transmission failed: $error';
  }

  @override
  String get unspecified => 'Unspecified';

  @override
  String get gatewayType => 'Gateway';

  @override
  String get blue => 'Blue';

  @override
  String get red => 'Red';

  @override
  String get green => 'Green';

  @override
  String get orange => 'Orange';

  @override
  String get purple => 'Purple';

  @override
  String get teal => 'Teal';

  @override
  String get gray => 'Gray';

  @override
  String get tempHumidity => 'Temp & Humidity';

  @override
  String get latestValue => 'Latest value';

  @override
  String get imuOrientation => 'IMU orientation';

  @override
  String get binaryData => 'Binary data';

  @override
  String get timeSeries => 'Time series';

  @override
  String get last30Minutes => 'Last 30 min';

  @override
  String get lastHour => 'Last 1 hour';

  @override
  String get last6Hours => 'Last 6 hours';

  @override
  String get switchTo2d => 'Switch to 2D';

  @override
  String get switchTo3d => 'Switch to 3D';

  @override
  String get useDayMap => 'Use day map';

  @override
  String get useNightMap => 'Use night map';

  @override
  String get useStandardMap => 'Use standard map';

  @override
  String get useSatelliteImagery => 'Use satellite imagery';

  @override
  String downloadMapQuestion(String region) {
    return 'Download map: $region?';
  }

  @override
  String get mapCachedDescription => 'It will be cached for offline use.';

  @override
  String get noNodesSharingLocation => 'No mesh nodes are sharing a location';

  @override
  String get unableChangeMap => 'Unable to change map view';

  @override
  String get zoomForMap =>
      'Zoom in to an uncached region to download its detailed map.';

  @override
  String get deviceLicenseInvalid => 'Device license invalid';

  @override
  String get licenseNoResponse =>
      'The device did not return a valid license response.';

  @override
  String get provisioningCannotContinue =>
      'Provisioning cannot continue on this device.';

  @override
  String get ok => 'OK';

  @override
  String get selectDeviceMode => 'Select Beacon, Sensor, or Relay mode';

  @override
  String stepProgress(int current, int total, String title) {
    return 'Step $current of $total: $title';
  }

  @override
  String get provisioningUnavailable => 'Provisioning is unavailable.';

  @override
  String get beaconModeDescription =>
      'Advertises a device profile and location.';

  @override
  String get sensorModeDescription =>
      'Advertises a device profile and sensor readings.';

  @override
  String get relayModeDescription =>
      'Extends mesh coverage without a device profile.';

  @override
  String get chooseDeviceMode => 'Choose how this EdgeZ device will operate.';

  @override
  String get regenerateDeviceId => 'Regenerate device ID';

  @override
  String get deviceGpsWakeDescription =>
      'Wake for periodic fixes, then power the receiver down';

  @override
  String get dashboardEmptyDescription =>
      'Use the dashboard button on a node to add it, then choose its visualization from device details.';

  @override
  String get nearbyDevices => 'Nearby BLE devices will appear here.';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Current app language: $language';
  }
}
