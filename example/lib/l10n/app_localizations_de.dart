// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get selectRelayWifi =>
      'Wählen Sie zum Fortfahren Upstream-WLAN oder SoftAP.';

  @override
  String get relayWifi => 'Relais-WLAN';

  @override
  String get upstreamWifi => 'Upstream-WLAN';

  @override
  String get softapProvisioningDescription =>
      'SoftAP verwendet die Mesh-SSID und Passphrase aus dem Netzwerkschritt. Eine leere Passphrase erstellt ein offenes Netzwerk.';

  @override
  String get invalidRelayWifi =>
      'SSID: 1–32 Bytes. Passwort: leer oder 8–63 Bytes. Upstream-WLAN akzeptiert auch einen PSK mit 64 Hexadezimalziffern.';

  @override
  String get clearBleSelection => 'Löschen';

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
  String get marketplace => 'Marktplatz';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get install => 'Installieren';

  @override
  String get close => 'Schließen';

  @override
  String get save => 'Speichern';

  @override
  String get saving => 'Speichern';

  @override
  String get loading => 'Laden';

  @override
  String get next => 'Weiter';

  @override
  String get download => 'Herunterladen';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get delete => 'Löschen';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get device => 'Gerät';

  @override
  String get dashboardVisualization => 'Dashboard-Visualisierung';

  @override
  String get widget => 'Widget';

  @override
  String get range => 'Bereich';

  @override
  String get type => 'Typ';

  @override
  String get sleeping => 'Im Ruhezustand';

  @override
  String get geoFence => 'Geofence';

  @override
  String get none => 'Keine';

  @override
  String get sensor => 'Sensor';

  @override
  String get noSensorData => 'Noch keine Sensordaten empfangen';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get pressure => 'Druck';

  @override
  String get altitude => 'Höhe';

  @override
  String get sensorTimeSeries => 'Sensor-Zeitreihe';

  @override
  String get provisioning => 'Bereitstellung';

  @override
  String get selectBleDevice => 'BLE-Gerät auswählen';

  @override
  String get scanAgain => 'Erneut suchen';

  @override
  String get scanningDevices => 'EdgeZ-Geräte werden gesucht…';

  @override
  String get beacon => 'Beacon';

  @override
  String get relay => 'Relay';

  @override
  String get network => 'Netzwerk';

  @override
  String get frequency => 'Frequenz';

  @override
  String get latitude => 'Breitengrad';

  @override
  String get longitude => 'Längengrad';

  @override
  String get usePhoneLocation => 'Telefonstandort verwenden';

  @override
  String get enableGeoFence => 'Geofence aktivieren';

  @override
  String get geoFenceName => 'Geofence-Name';

  @override
  String get geoIndex => 'Geo-Index';

  @override
  String get sensorDrivers => 'Sensortreiber';

  @override
  String get sleepMode => 'Ruhemodus';

  @override
  String get enableSleepMode => 'Ruhemodus aktivieren';

  @override
  String get sleepModeDescription =>
      'Das Gerät darf in den energiesparenden Ruhemodus wechseln.';

  @override
  String get answer => 'Annehmen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get end => 'Beenden';

  @override
  String get holdToTalk => 'Zum Sprechen halten';

  @override
  String get noMessages => 'Noch keine Nachrichten';

  @override
  String get message => 'Nachricht';

  @override
  String get send => 'Senden';

  @override
  String get hop => 'Hop';

  @override
  String get routes => 'Routen';

  @override
  String get publicChannels => 'Öffentliche Kanäle';

  @override
  String get system => 'System';

  @override
  String get deviceLogs => 'Geräteprotokolle';

  @override
  String get transport => 'Transport';

  @override
  String get prune => 'Bereinigen';

  @override
  String get open => 'Öffnen';

  @override
  String get meshOverview => 'Mesh-Übersicht';

  @override
  String get interfaceLabel => 'Schnittstelle';

  @override
  String get knownNodes => 'Bekannte Knoten';

  @override
  String get license => 'Lizenz';

  @override
  String get visualizationWidgets => 'Visualisierungs-Widgets';

  @override
  String get noDashboardDevices => 'Noch keine Dashboard-Geräte';

  @override
  String get temp => 'Temp.';

  @override
  String get passByScore => 'Vorbeifahrtwert';

  @override
  String get backToSettings => 'Zurück zu Einstellungen';

  @override
  String get speedAndLoss => 'Geschwindigkeit und Verlust · letzte 30 Minuten';

  @override
  String get movingSpeed => 'Gleitende Geschwindigkeit';

  @override
  String get movingLoss => 'Gleitender Verlust';

  @override
  String get speed => 'Geschwindigkeit';

  @override
  String get loss => 'Verlust';

  @override
  String get activeConnection => 'Aktive Verbindung';

  @override
  String get status => 'Status';

  @override
  String get conversations => 'Unterhaltungen';

  @override
  String get database => 'Datenbank';

  @override
  String get halowMesh => 'HaLow-Mesh';

  @override
  String get supported => 'Unterstützt';

  @override
  String get initialized => 'Initialisiert';

  @override
  String get meshMode => 'Mesh-Modus';

  @override
  String get linkUp => 'Verbindung aktiv';

  @override
  String get routeReady => 'Route bereit';

  @override
  String get readyForReport => 'Berichtsbereit';

  @override
  String get gateway => 'Gateway';

  @override
  String get sdkEvents => 'SDK-Ereignisse';

  @override
  String get logStream => 'Protokollstream';

  @override
  String get links => 'Verbindungen';

  @override
  String get window => 'Fenster';

  @override
  String get direct => 'Direkt';

  @override
  String get relayed => 'Weitergeleitet';

  @override
  String get refreshRouting => 'Routingtabelle aktualisieren';

  @override
  String get downloadOfflineMap => 'Offline-Karte herunterladen';

  @override
  String get transcribeAgain =>
      'Mit der Sprache aus Einstellungen erneut transkribieren';

  @override
  String get speakTranslation => 'Übersetzung vorlesen';

  @override
  String get upstreamNetwork => 'Upstream-Netzwerk';

  @override
  String get refreshUsb => 'USB-Geräte aktualisieren';

  @override
  String get uartConnector => 'UART-/I2C-Anschluss';

  @override
  String get rs485Connector => 'RS485-Anschluss';

  @override
  String get upstreamWifiSsid => 'Upstream-WLAN-SSID';

  @override
  String get upstreamWifiPassphrase => 'Upstream-WLAN-Passphrase';

  @override
  String get beaconMulticast => 'Beacon-Multicast';

  @override
  String get loggingHelper =>
      'Gilt für Geräteausgabe und App-Protokollspeicher';

  @override
  String incomingCallFrom(String name) {
    return 'Eingehender Anruf von $name';
  }

  @override
  String get selectedDevice => 'Ausgewähltes Gerät';

  @override
  String get noDeviceSelected => 'Kein Gerät ausgewählt';

  @override
  String get usbConnected => 'USB verbunden; Hochgeschwindigkeitskanal bereit';

  @override
  String get bleControlReady => 'BLE verbunden; Steuerkanal bereit';

  @override
  String get bleSettingUp => 'BLE verbunden; Steuerkanal wird eingerichtet';

  @override
  String get blePairing => 'BLE-Kopplung oder Verbindung';

  @override
  String get disconnected => 'Getrennt';

  @override
  String firmwareVersion(String version) {
    return 'Firmware: $version';
  }

  @override
  String get waitingBle => 'Warten auf BLE-Verbindung';

  @override
  String get connectBleDevice => 'BLE-Gerät verbinden';

  @override
  String get waitingBleControl => 'Warten auf BLE-Steuerkanal';

  @override
  String get waitingDeviceStatus => 'Warten auf Gerätestatus';

  @override
  String updatingProgress(int percent) {
    return 'Aktualisierung $percent%';
  }

  @override
  String get otaUnsupported => 'Die verbundene Firmware bietet noch kein OTA.';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => 'Nicht geladen';

  @override
  String get useDeviceGps => 'Geräte-GPS (L76K) verwenden';

  @override
  String get deviceGpsDescription =>
      'Regelmäßige energiesparende Gerätepositionen statt Telefon-/statischer Position verwenden';

  @override
  String deviceFix(String latitude, String longitude) {
    return 'Geräteposition: $latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => 'Telefonstandort aktualisieren';

  @override
  String get geofenceBeaconDescription =>
      'Geofence in Geräte-Beacons aufnehmen';

  @override
  String get enableSensors => 'Sensoren aktivieren';

  @override
  String get sensorConnectorDescription => 'Sensoranschlüsse konfigurieren';

  @override
  String get enableUpstreamNetwork => 'Upstream-Netzwerk aktivieren';

  @override
  String get upstreamDescription =>
      'Über WLAN weiterleiten und Beacons an eine Multicast-Adresse senden.';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get translationLanguageDescription =>
      'Wird als anfängliche Zielsprache in Unterhaltungen verwendet. Die gesprochene Sprache wird einmal erkannt und mit dem Transkript gespeichert.';

  @override
  String get selectBleOrUsb => 'BLE- oder USB-Gerät auswählen';

  @override
  String get noUsbDevices =>
      'Keine USB-Geräte angeschlossen. Mit einem USB-OTG-Kabel verbinden.';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get userIdentity => 'Benutzeridentität';

  @override
  String get loadingIdentity => 'Identität wird geladen';

  @override
  String get publicKey => 'Öffentlicher X25519-Schlüssel';

  @override
  String get privateKey => 'Privater X25519-Schlüssel';

  @override
  String get regenerateKeyPair => 'Schlüsselpaar neu erzeugen';

  @override
  String get recording => 'Aufnahme';

  @override
  String get requestingMicrophone => 'Mikrofon wird angefordert';

  @override
  String get microphoneDenied => 'Mikrofonberechtigung verweigert';

  @override
  String get startingVoice => 'Sprachnachricht wird gestartet';

  @override
  String get voiceCancelled => 'Sprachnachricht abgebrochen';

  @override
  String get sendingVoice => 'Sprachnachricht wird gesendet';

  @override
  String get voiceSent => 'Sprachnachricht gesendet';

  @override
  String get sending => 'Wird gesendet';

  @override
  String get sentToDevice => 'An Gerät gesendet';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get waitingForKey => 'Warten auf Schlüssel';

  @override
  String get joinTalkgroup => 'OpenMANET-Sprechgruppe beitreten';

  @override
  String get startVoiceCall => 'Sprachanruf starten';

  @override
  String get noSensorGps => 'Kein Sensor-GPS';

  @override
  String get connectToSendVoice => 'Zum Senden von Sprache verbinden';

  @override
  String get translateVoice => 'Sprachnachricht übersetzen';

  @override
  String get checkingTranslation => 'Offline-Übersetzung wird geprüft…';

  @override
  String get offlineTranslation => 'Offline-Übersetzung · 2,6 GB';

  @override
  String get installGemma => 'Gemma 4 zum Übersetzen installieren';

  @override
  String get noReplayData => 'Keine Wiedergabedaten';

  @override
  String get tapToReplay => 'Zum Abspielen tippen';

  @override
  String get transcript => 'Transkript';

  @override
  String translationFailed(String error) {
    return 'Übersetzung fehlgeschlagen: $error';
  }

  @override
  String speechFailed(String error) {
    return 'Sprachausgabe fehlgeschlagen: $error';
  }

  @override
  String get delivered => 'Zugestellt';

  @override
  String get incomingVoiceCall => 'Eingehender Sprachanruf';

  @override
  String get calling => 'Anruf…';

  @override
  String get connected => 'Verbunden';

  @override
  String get callEnded => 'Anruf beendet';

  @override
  String get meshUser => 'Mesh-Benutzer';

  @override
  String get transmitting => 'Übertragung…';

  @override
  String callActionFailed(String error) {
    return 'Anrufaktion fehlgeschlagen: $error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return 'Sprachübertragung fehlgeschlagen: $error';
  }

  @override
  String get unspecified => 'Nicht angegeben';

  @override
  String get gatewayType => 'Gateway';

  @override
  String get blue => 'Blau';

  @override
  String get red => 'Rot';

  @override
  String get green => 'Grün';

  @override
  String get orange => 'Orange';

  @override
  String get purple => 'Violett';

  @override
  String get teal => 'Blaugrün';

  @override
  String get gray => 'Grau';

  @override
  String get tempHumidity => 'Temp. & Feuchtigkeit';

  @override
  String get latestValue => 'Neuester Wert';

  @override
  String get imuOrientation => 'IMU-Ausrichtung';

  @override
  String get binaryData => 'Binärdaten';

  @override
  String get timeSeries => 'Zeitreihe';

  @override
  String get last30Minutes => 'Letzte 30 Min.';

  @override
  String get lastHour => 'Letzte Stunde';

  @override
  String get last6Hours => 'Letzte 6 Stunden';

  @override
  String get switchTo2d => 'Zu 2D wechseln';

  @override
  String get switchTo3d => 'Zu 3D wechseln';

  @override
  String get useDayMap => 'Tageskarte verwenden';

  @override
  String get useNightMap => 'Nachtkarte verwenden';

  @override
  String get useStandardMap => 'Standardkarte verwenden';

  @override
  String get useSatelliteImagery => 'Satellitenbilder verwenden';

  @override
  String downloadMapQuestion(String region) {
    return 'Karte herunterladen: $region?';
  }

  @override
  String get mapCachedDescription =>
      'Sie wird für die Offline-Nutzung zwischengespeichert.';

  @override
  String get noNodesSharingLocation =>
      'Keine Mesh-Knoten teilen ihren Standort';

  @override
  String get unableChangeMap => 'Kartenansicht kann nicht geändert werden';

  @override
  String get zoomForMap =>
      'In eine nicht gespeicherte Region zoomen, um die Detailkarte herunterzuladen.';

  @override
  String get deviceLicenseInvalid => 'Gerätelizenz ungültig';

  @override
  String get licenseNoResponse =>
      'Das Gerät hat keine gültige Lizenzantwort geliefert.';

  @override
  String get provisioningCannotContinue =>
      'Die Bereitstellung kann auf diesem Gerät nicht fortgesetzt werden.';

  @override
  String get ok => 'OK';

  @override
  String get selectDeviceMode => 'Beacon-, Sensor- oder Relay-Modus auswählen';

  @override
  String stepProgress(int current, int total, String title) {
    return 'Schritt $current von $total: $title';
  }

  @override
  String get provisioningUnavailable => 'Bereitstellung ist nicht verfügbar.';

  @override
  String get beaconModeDescription =>
      'Sendet ein Geräteprofil und den Standort.';

  @override
  String get sensorModeDescription =>
      'Sendet ein Geräteprofil und Sensorwerte.';

  @override
  String get relayModeDescription =>
      'Erweitert die Mesh-Abdeckung ohne Geräteprofil.';

  @override
  String get chooseDeviceMode => 'Wähle, wie dieses EdgeZ-Gerät arbeitet.';

  @override
  String get regenerateDeviceId => 'Geräte-ID neu erzeugen';

  @override
  String get deviceGpsWakeDescription =>
      'Regelmäßig für Positionsbestimmung aufwachen und Empfänger ausschalten';

  @override
  String get dashboardEmptyDescription =>
      'Füge einen Knoten über seine Dashboard-Schaltfläche hinzu und wähle die Visualisierung in den Gerätedetails.';

  @override
  String get nearbyDevices => 'BLE-Geräte in der Nähe werden hier angezeigt.';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Aktuelle App-Sprache: $language';
  }
}
