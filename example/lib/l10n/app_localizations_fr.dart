// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get nodes => 'Nœuds';

  @override
  String get map => 'Carte';

  @override
  String get drivers => 'Pilotes';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get languageDescription =>
      'Choisissez la langue utilisée par l’application';

  @override
  String get deviceConnection => 'Connexion de l’appareil';

  @override
  String get select => 'Sélectionner';

  @override
  String get connect => 'Connecter';

  @override
  String get connecting => 'Connexion…';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get autoConnect => 'Connexion automatique';

  @override
  String get autoConnectDescription =>
      'Connecter l’appareil BLE sélectionné au démarrage et le reconnecter en cas de coupure';

  @override
  String get user => 'Utilisateur';

  @override
  String get meshNetwork => 'Réseau maillé';

  @override
  String get others => 'Autres';

  @override
  String get deviceUser => 'Utilisateur de l’appareil';

  @override
  String get userName => 'Nom d’utilisateur';

  @override
  String get deviceUserName => 'Nom d’utilisateur de l’appareil';

  @override
  String get marker => 'Marqueur';

  @override
  String get location => 'Localisation';

  @override
  String get deviceLocation => 'Localisation de l’appareil';

  @override
  String get shareLocation => 'Partager la localisation';

  @override
  String get shareLocationDescription =>
      'Inclure la localisation dans la balise HaLow';

  @override
  String get country => 'Pays';

  @override
  String get bandwidth => 'Bande passante';

  @override
  String get channel => 'Canal';

  @override
  String get meshId => 'ID Mesh / SSID';

  @override
  String get passphrase => 'Phrase secrète';

  @override
  String get maxHop => 'Nombre maximal de sauts';

  @override
  String get beaconInterval => 'Intervalle de balise (secondes)';

  @override
  String get saveSettings => 'Enregistrer les paramètres';

  @override
  String get logging => 'Journalisation';

  @override
  String get logLevel => 'Niveau de journal';

  @override
  String get chat => 'Discussion';

  @override
  String get defaultTranslationLanguage => 'Langue de traduction par défaut';

  @override
  String get autoReplayVoice => 'Relire automatiquement les messages vocaux';

  @override
  String get autoReplayVoiceDescription =>
      'Lire automatiquement les nouveaux messages vocaux reçus';

  @override
  String get debug => 'Débogage';

  @override
  String get back => 'Retour';

  @override
  String get deviceMode => 'Mode appareil';

  @override
  String get phoneMode => 'Mode téléphone';

  @override
  String get checkForUpdate => 'Rechercher une mise à jour';

  @override
  String get checking => 'Vérification…';

  @override
  String get update => 'Mettre à jour';

  @override
  String get marketplace => 'Marché';

  @override
  String get cancel => 'Annuler';

  @override
  String get install => 'Installer';

  @override
  String get close => 'Fermer';

  @override
  String get save => 'Enregistrer';

  @override
  String get saving => 'Enregistrement';

  @override
  String get loading => 'Chargement';

  @override
  String get next => 'Suivant';

  @override
  String get download => 'Télécharger';

  @override
  String get notNow => 'Plus tard';

  @override
  String get refresh => 'Actualiser';

  @override
  String get delete => 'Supprimer';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get device => 'Appareil';

  @override
  String get dashboardVisualization => 'Visualisation du tableau de bord';

  @override
  String get widget => 'Widget';

  @override
  String get range => 'Plage';

  @override
  String get type => 'Type';

  @override
  String get sleeping => 'En veille';

  @override
  String get geoFence => 'Zone géographique';

  @override
  String get none => 'Aucun';

  @override
  String get sensor => 'Capteur';

  @override
  String get noSensorData => 'Aucune donnée de capteur reçue';

  @override
  String get temperature => 'Température';

  @override
  String get humidity => 'Humidité';

  @override
  String get pressure => 'Pression';

  @override
  String get altitude => 'Altitude';

  @override
  String get sensorTimeSeries => 'Série temporelle du capteur';

  @override
  String get provisioning => 'Provisionnement';

  @override
  String get selectBleDevice => 'Sélectionner un appareil BLE';

  @override
  String get scanAgain => 'Relancer le scan';

  @override
  String get scanningDevices => 'Recherche d’appareils EdgeZ…';

  @override
  String get beacon => 'Balise';

  @override
  String get relay => 'Relais';

  @override
  String get network => 'Réseau';

  @override
  String get frequency => 'Fréquence';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get usePhoneLocation => 'Utiliser la position du téléphone';

  @override
  String get enableGeoFence => 'Activer la zone géographique';

  @override
  String get geoFenceName => 'Nom de la zone';

  @override
  String get geoIndex => 'Index géographique';

  @override
  String get sensorDrivers => 'Pilotes de capteur';

  @override
  String get sleepMode => 'Mode veille';

  @override
  String get enableSleepMode => 'Activer le mode veille';

  @override
  String get sleepModeDescription =>
      'Autoriser l’appareil à passer en veille basse consommation.';

  @override
  String get answer => 'Répondre';

  @override
  String get decline => 'Refuser';

  @override
  String get end => 'Terminer';

  @override
  String get holdToTalk => 'Maintenir pour parler';

  @override
  String get noMessages => 'Aucun message';

  @override
  String get message => 'Message';

  @override
  String get send => 'Envoyer';

  @override
  String get hop => 'Saut';

  @override
  String get routes => 'Routes';

  @override
  String get publicChannels => 'Canaux publics';

  @override
  String get system => 'Système';

  @override
  String get deviceLogs => 'Journaux de l’appareil';

  @override
  String get transport => 'Transport';

  @override
  String get prune => 'Purger';

  @override
  String get open => 'Ouvrir';

  @override
  String get meshOverview => 'Vue d’ensemble du maillage';

  @override
  String get interfaceLabel => 'Interface';

  @override
  String get knownNodes => 'Nœuds connus';

  @override
  String get license => 'Licence';

  @override
  String get visualizationWidgets => 'Widgets de visualisation';

  @override
  String get noDashboardDevices => 'Aucun appareil dans le tableau de bord';

  @override
  String get temp => 'Temp.';

  @override
  String get passByScore => 'Score de passage';

  @override
  String get backToSettings => 'Retour aux paramètres';

  @override
  String get speedAndLoss => 'Débit et pertes · 30 dernières minutes';

  @override
  String get movingSpeed => 'Débit moyen';

  @override
  String get movingLoss => 'Perte moyenne';

  @override
  String get speed => 'Débit';

  @override
  String get loss => 'Perte';

  @override
  String get activeConnection => 'Connexion active';

  @override
  String get status => 'État';

  @override
  String get conversations => 'Conversations';

  @override
  String get database => 'Base de données';

  @override
  String get halowMesh => 'Maillage HaLow';

  @override
  String get supported => 'Pris en charge';

  @override
  String get initialized => 'Initialisé';

  @override
  String get meshMode => 'Mode maillé';

  @override
  String get linkUp => 'Lien actif';

  @override
  String get routeReady => 'Route prête';

  @override
  String get readyForReport => 'Prêt pour le rapport';

  @override
  String get gateway => 'Passerelle';

  @override
  String get sdkEvents => 'Événements SDK';

  @override
  String get logStream => 'Flux de journaux';

  @override
  String get links => 'Liens';

  @override
  String get window => 'Fenêtre';

  @override
  String get direct => 'Direct';

  @override
  String get relayed => 'Relayé';

  @override
  String get refreshRouting => 'Actualiser la table de routage';

  @override
  String get downloadOfflineMap => 'Télécharger la carte hors ligne';

  @override
  String get transcribeAgain => 'Retranscrire avec la langue des paramètres';

  @override
  String get speakTranslation => 'Lire la traduction';

  @override
  String get upstreamNetwork => 'Réseau amont';

  @override
  String get refreshUsb => 'Actualiser les appareils USB';

  @override
  String get uartConnector => 'Connecteur UART / I2C';

  @override
  String get rs485Connector => 'Connecteur RS485';

  @override
  String get upstreamWifiSsid => 'SSID Wi-Fi amont';

  @override
  String get upstreamWifiPassphrase => 'Phrase secrète Wi-Fi amont';

  @override
  String get beaconMulticast => 'Multidiffusion de balise';

  @override
  String get loggingHelper =>
      'S’applique à la sortie de l’appareil et au stockage des journaux';

  @override
  String incomingCallFrom(String name) {
    return 'Appel entrant de $name';
  }

  @override
  String get dashboardEmptyDescription =>
      'Utilisez le bouton de tableau de bord d’un nœud pour l’ajouter, puis choisissez sa visualisation dans les détails de l’appareil.';

  @override
  String get nearbyDevices => 'Les appareils BLE à proximité apparaîtront ici.';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Langue actuelle de l’application : $language';
  }
}
