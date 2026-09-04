// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String settingsLanguageSemantics(String language) {
    return 'Current app language: $language';
  }
}
