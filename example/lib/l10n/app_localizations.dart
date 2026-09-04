import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EdgeZ'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @nodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get nodes;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by the app'**
  String get languageDescription;

  /// No description provided for @deviceConnection.
  ///
  /// In en, this message translates to:
  /// **'Device connection'**
  String get deviceConnection;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @autoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto connect'**
  String get autoConnect;

  /// No description provided for @autoConnectDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect the selected BLE device on app start and reconnect if it drops'**
  String get autoConnectDescription;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @meshNetwork.
  ///
  /// In en, this message translates to:
  /// **'Mesh Network'**
  String get meshNetwork;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @deviceUser.
  ///
  /// In en, this message translates to:
  /// **'Device user'**
  String get deviceUser;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get userName;

  /// No description provided for @deviceUserName.
  ///
  /// In en, this message translates to:
  /// **'Device user name'**
  String get deviceUserName;

  /// No description provided for @marker.
  ///
  /// In en, this message translates to:
  /// **'Marker'**
  String get marker;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @deviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Device location'**
  String get deviceLocation;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// No description provided for @shareLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Include location in HaLow beacon'**
  String get shareLocationDescription;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @bandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get bandwidth;

  /// No description provided for @channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channel;

  /// No description provided for @meshId.
  ///
  /// In en, this message translates to:
  /// **'Mesh ID / SSID'**
  String get meshId;

  /// No description provided for @passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphrase;

  /// No description provided for @maxHop.
  ///
  /// In en, this message translates to:
  /// **'Max hop'**
  String get maxHop;

  /// No description provided for @beaconInterval.
  ///
  /// In en, this message translates to:
  /// **'Beacon interval (seconds)'**
  String get beaconInterval;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get saveSettings;

  /// No description provided for @logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get logging;

  /// No description provided for @logLevel.
  ///
  /// In en, this message translates to:
  /// **'Log level'**
  String get logLevel;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @defaultTranslationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default translation language'**
  String get defaultTranslationLanguage;

  /// No description provided for @autoReplayVoice.
  ///
  /// In en, this message translates to:
  /// **'Auto replay received voice'**
  String get autoReplayVoice;

  /// No description provided for @autoReplayVoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Play new incoming voice messages automatically'**
  String get autoReplayVoiceDescription;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @deviceMode.
  ///
  /// In en, this message translates to:
  /// **'Device mode'**
  String get deviceMode;

  /// No description provided for @phoneMode.
  ///
  /// In en, this message translates to:
  /// **'Phone mode'**
  String get phoneMode;

  /// No description provided for @checkForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for update'**
  String get checkForUpdate;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @install.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get install;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get saving;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @dashboardVisualization.
  ///
  /// In en, this message translates to:
  /// **'Dashboard visualization'**
  String get dashboardVisualization;

  /// No description provided for @widget.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get widget;

  /// No description provided for @range.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get range;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @sleeping.
  ///
  /// In en, this message translates to:
  /// **'Sleeping'**
  String get sleeping;

  /// No description provided for @geoFence.
  ///
  /// In en, this message translates to:
  /// **'Geo fence'**
  String get geoFence;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @sensor.
  ///
  /// In en, this message translates to:
  /// **'Sensor'**
  String get sensor;

  /// No description provided for @noSensorData.
  ///
  /// In en, this message translates to:
  /// **'No sensor data received yet'**
  String get noSensorData;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @sensorTimeSeries.
  ///
  /// In en, this message translates to:
  /// **'Sensor time series'**
  String get sensorTimeSeries;

  /// No description provided for @provisioning.
  ///
  /// In en, this message translates to:
  /// **'Provisioning'**
  String get provisioning;

  /// No description provided for @selectBleDevice.
  ///
  /// In en, this message translates to:
  /// **'Select BLE device'**
  String get selectBleDevice;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @scanningDevices.
  ///
  /// In en, this message translates to:
  /// **'Scanning for EdgeZ devices...'**
  String get scanningDevices;

  /// No description provided for @beacon.
  ///
  /// In en, this message translates to:
  /// **'Beacon'**
  String get beacon;

  /// No description provided for @relay.
  ///
  /// In en, this message translates to:
  /// **'Relay'**
  String get relay;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @usePhoneLocation.
  ///
  /// In en, this message translates to:
  /// **'Use phone location'**
  String get usePhoneLocation;

  /// No description provided for @enableGeoFence.
  ///
  /// In en, this message translates to:
  /// **'Enable geo fence'**
  String get enableGeoFence;

  /// No description provided for @geoFenceName.
  ///
  /// In en, this message translates to:
  /// **'Geo fence name'**
  String get geoFenceName;

  /// No description provided for @geoIndex.
  ///
  /// In en, this message translates to:
  /// **'Geo index'**
  String get geoIndex;

  /// No description provided for @sensorDrivers.
  ///
  /// In en, this message translates to:
  /// **'Sensor drivers'**
  String get sensorDrivers;

  /// No description provided for @sleepMode.
  ///
  /// In en, this message translates to:
  /// **'Sleep mode'**
  String get sleepMode;

  /// No description provided for @enableSleepMode.
  ///
  /// In en, this message translates to:
  /// **'Enable sleep mode'**
  String get enableSleepMode;

  /// No description provided for @sleepModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow the device to enter low-power sleep.'**
  String get sleepModeDescription;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @holdToTalk.
  ///
  /// In en, this message translates to:
  /// **'Hold to Talk'**
  String get holdToTalk;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @hop.
  ///
  /// In en, this message translates to:
  /// **'Hop'**
  String get hop;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @publicChannels.
  ///
  /// In en, this message translates to:
  /// **'Public channels'**
  String get publicChannels;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @deviceLogs.
  ///
  /// In en, this message translates to:
  /// **'Device logs'**
  String get deviceLogs;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @prune.
  ///
  /// In en, this message translates to:
  /// **'Prune'**
  String get prune;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @meshOverview.
  ///
  /// In en, this message translates to:
  /// **'Mesh overview'**
  String get meshOverview;

  /// No description provided for @interfaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interfaceLabel;

  /// No description provided for @knownNodes.
  ///
  /// In en, this message translates to:
  /// **'Known nodes'**
  String get knownNodes;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @visualizationWidgets.
  ///
  /// In en, this message translates to:
  /// **'Visualization widgets'**
  String get visualizationWidgets;

  /// No description provided for @noDashboardDevices.
  ///
  /// In en, this message translates to:
  /// **'No dashboard devices yet'**
  String get noDashboardDevices;

  /// No description provided for @temp.
  ///
  /// In en, this message translates to:
  /// **'Temp'**
  String get temp;

  /// No description provided for @passByScore.
  ///
  /// In en, this message translates to:
  /// **'Pass-by score'**
  String get passByScore;

  /// No description provided for @backToSettings.
  ///
  /// In en, this message translates to:
  /// **'Back to settings'**
  String get backToSettings;

  /// No description provided for @speedAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Speed and loss · last 30 minutes'**
  String get speedAndLoss;

  /// No description provided for @movingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Moving speed'**
  String get movingSpeed;

  /// No description provided for @movingLoss.
  ///
  /// In en, this message translates to:
  /// **'Moving loss'**
  String get movingLoss;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @activeConnection.
  ///
  /// In en, this message translates to:
  /// **'Active connection'**
  String get activeConnection;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @halowMesh.
  ///
  /// In en, this message translates to:
  /// **'HaLow mesh'**
  String get halowMesh;

  /// No description provided for @supported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get supported;

  /// No description provided for @initialized.
  ///
  /// In en, this message translates to:
  /// **'Initialized'**
  String get initialized;

  /// No description provided for @meshMode.
  ///
  /// In en, this message translates to:
  /// **'Mesh mode'**
  String get meshMode;

  /// No description provided for @linkUp.
  ///
  /// In en, this message translates to:
  /// **'Link up'**
  String get linkUp;

  /// No description provided for @routeReady.
  ///
  /// In en, this message translates to:
  /// **'Route ready'**
  String get routeReady;

  /// No description provided for @readyForReport.
  ///
  /// In en, this message translates to:
  /// **'Ready for report'**
  String get readyForReport;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gateway;

  /// No description provided for @sdkEvents.
  ///
  /// In en, this message translates to:
  /// **'SDK events'**
  String get sdkEvents;

  /// No description provided for @logStream.
  ///
  /// In en, this message translates to:
  /// **'Log stream'**
  String get logStream;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @window.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get window;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @relayed.
  ///
  /// In en, this message translates to:
  /// **'Relayed'**
  String get relayed;

  /// No description provided for @refreshRouting.
  ///
  /// In en, this message translates to:
  /// **'Refresh routing table'**
  String get refreshRouting;

  /// No description provided for @downloadOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Download offline map'**
  String get downloadOfflineMap;

  /// No description provided for @transcribeAgain.
  ///
  /// In en, this message translates to:
  /// **'Transcribe again using the Settings language'**
  String get transcribeAgain;

  /// No description provided for @speakTranslation.
  ///
  /// In en, this message translates to:
  /// **'Speak translation'**
  String get speakTranslation;

  /// No description provided for @upstreamNetwork.
  ///
  /// In en, this message translates to:
  /// **'Upstream network'**
  String get upstreamNetwork;

  /// No description provided for @refreshUsb.
  ///
  /// In en, this message translates to:
  /// **'Refresh USB devices'**
  String get refreshUsb;

  /// No description provided for @uartConnector.
  ///
  /// In en, this message translates to:
  /// **'UART / I2C connector'**
  String get uartConnector;

  /// No description provided for @rs485Connector.
  ///
  /// In en, this message translates to:
  /// **'RS485 connector'**
  String get rs485Connector;

  /// No description provided for @upstreamWifiSsid.
  ///
  /// In en, this message translates to:
  /// **'Upstream Wi-Fi SSID'**
  String get upstreamWifiSsid;

  /// No description provided for @upstreamWifiPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Upstream Wi-Fi passphrase'**
  String get upstreamWifiPassphrase;

  /// No description provided for @beaconMulticast.
  ///
  /// In en, this message translates to:
  /// **'Beacon multicast'**
  String get beaconMulticast;

  /// No description provided for @loggingHelper.
  ///
  /// In en, this message translates to:
  /// **'Applies to device output and app log storage'**
  String get loggingHelper;

  /// No description provided for @incomingCallFrom.
  ///
  /// In en, this message translates to:
  /// **'Incoming call from {name}'**
  String incomingCallFrom(String name);

  /// No description provided for @dashboardEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the dashboard button on a node to add it, then choose its visualization from device details.'**
  String get dashboardEmptyDescription;

  /// No description provided for @nearbyDevices.
  ///
  /// In en, this message translates to:
  /// **'Nearby BLE devices will appear here.'**
  String get nearbyDevices;

  /// No description provided for @settingsLanguageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current app language: {language}'**
  String settingsLanguageSemantics(String language);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'ja',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
