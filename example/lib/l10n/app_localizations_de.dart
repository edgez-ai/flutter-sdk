// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get nodes => 'Knoten';

  @override
  String get map => 'Karte';

  @override
  String get drivers => 'Treiber';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get languageDescription => 'Wähle die Sprache der App';

  @override
  String get deviceConnection => 'Geräteverbindung';

  @override
  String get select => 'Auswählen';

  @override
  String get connect => 'Verbinden';

  @override
  String get connecting => 'Verbindung wird hergestellt…';

  @override
  String get disconnect => 'Trennen';

  @override
  String get autoConnect => 'Automatisch verbinden';

  @override
  String get autoConnectDescription =>
      'Das ausgewählte BLE-Gerät beim App-Start verbinden und nach Abbruch erneut verbinden';

  @override
  String get user => 'Benutzer';

  @override
  String get meshNetwork => 'Mesh-Netzwerk';

  @override
  String get others => 'Sonstiges';

  @override
  String get deviceUser => 'Gerätebenutzer';

  @override
  String get userName => 'Benutzername';

  @override
  String get deviceUserName => 'Gerätebenutzername';

  @override
  String get marker => 'Markierung';

  @override
  String get location => 'Standort';

  @override
  String get deviceLocation => 'Gerätestandort';

  @override
  String get shareLocation => 'Standort teilen';

  @override
  String get shareLocationDescription => 'Standort in HaLow-Beacon aufnehmen';

  @override
  String get country => 'Land';

  @override
  String get bandwidth => 'Bandbreite';

  @override
  String get channel => 'Kanal';

  @override
  String get meshId => 'Mesh-ID / SSID';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get maxHop => 'Maximale Hops';

  @override
  String get beaconInterval => 'Beacon-Intervall (Sekunden)';

  @override
  String get saveSettings => 'Einstellungen speichern';

  @override
  String get logging => 'Protokollierung';

  @override
  String get logLevel => 'Protokollstufe';

  @override
  String get chat => 'Chat';

  @override
  String get defaultTranslationLanguage => 'Standard-Übersetzungssprache';

  @override
  String get autoReplayVoice =>
      'Empfangene Sprachnachrichten automatisch abspielen';

  @override
  String get autoReplayVoiceDescription =>
      'Neue eingehende Sprachnachrichten automatisch abspielen';

  @override
  String get debug => 'Debug';

  @override
  String get back => 'Zurück';

  @override
  String get deviceMode => 'Gerätemodus';

  @override
  String get phoneMode => 'Telefonmodus';

  @override
  String get checkForUpdate => 'Nach Update suchen';

  @override
  String get checking => 'Prüfung…';

  @override
  String get update => 'Aktualisieren';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Aktuelle App-Sprache: $language';
  }
}
