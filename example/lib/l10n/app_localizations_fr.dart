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
  String get selectedDevice => 'Appareil sélectionné';

  @override
  String get noDeviceSelected => 'Aucun appareil sélectionné';

  @override
  String get usbConnected => 'USB connecté ; canal haut débit prêt';

  @override
  String get bleControlReady => 'BLE connecté ; canal de contrôle prêt';

  @override
  String get bleSettingUp =>
      'BLE connecté ; configuration du canal de contrôle';

  @override
  String get blePairing => 'Appairage ou connexion BLE';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String firmwareVersion(String version) {
    return 'Micrologiciel : $version';
  }

  @override
  String get waitingBle => 'En attente de la connexion BLE';

  @override
  String get connectBleDevice => 'Connecter un appareil BLE';

  @override
  String get waitingBleControl => 'En attente du canal de contrôle BLE';

  @override
  String get waitingDeviceStatus => 'En attente de l’état de l’appareil';

  @override
  String updatingProgress(int percent) {
    return 'Mise à jour $percent%';
  }

  @override
  String get otaUnsupported =>
      'Le micrologiciel connecté n’expose pas encore la mise à jour BLE OTA.';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => 'Non chargé';

  @override
  String get useDeviceGps => 'Utiliser le GPS de l’appareil (L76K)';

  @override
  String get deviceGpsDescription =>
      'Utiliser les positions périodiques basse consommation plutôt que la position du téléphone/statique';

  @override
  String deviceFix(String latitude, String longitude) {
    return 'Position de l’appareil : $latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => 'Actualiser la position du téléphone';

  @override
  String get geofenceBeaconDescription =>
      'Inclure une zone géographique dans les balises de l’appareil';

  @override
  String get enableSensors => 'Activer les capteurs';

  @override
  String get sensorConnectorDescription =>
      'Configurer les connecteurs de capteurs';

  @override
  String get enableUpstreamNetwork => 'Activer le réseau amont';

  @override
  String get upstreamDescription =>
      'Transmettre via Wi-Fi et envoyer les balises à une adresse multicast.';

  @override
  String get notSet => 'Non défini';

  @override
  String get translationLanguageDescription =>
      'Utilisée comme langue cible initiale des conversations. La langue parlée est détectée une fois et enregistrée avec la transcription.';

  @override
  String get selectBleOrUsb => 'Sélectionner un appareil BLE ou USB';

  @override
  String get noUsbDevices =>
      'Aucun appareil USB connecté. Utilisez un câble USB OTG.';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get userIdentity => 'Identité utilisateur';

  @override
  String get loadingIdentity => 'Chargement de l’identité';

  @override
  String get publicKey => 'Clé publique X25519';

  @override
  String get privateKey => 'Clé privée X25519';

  @override
  String get regenerateKeyPair => 'Régénérer la paire de clés';

  @override
  String get recording => 'Enregistrement';

  @override
  String get requestingMicrophone => 'Demande du microphone';

  @override
  String get microphoneDenied => 'Autorisation du microphone refusée';

  @override
  String get startingVoice => 'Démarrage vocal';

  @override
  String get voiceCancelled => 'Message vocal annulé';

  @override
  String get sendingVoice => 'Envoi du message vocal';

  @override
  String get voiceSent => 'Message vocal envoyé';

  @override
  String get sending => 'Envoi';

  @override
  String get sentToDevice => 'Envoyé à l’appareil';

  @override
  String get encrypted => 'Chiffré';

  @override
  String get waitingForKey => 'En attente de la clé';

  @override
  String get joinTalkgroup => 'Rejoindre le groupe OpenMANET';

  @override
  String get startVoiceCall => 'Démarrer un appel vocal';

  @override
  String get noSensorGps => 'Aucun GPS de capteur';

  @override
  String get connectToSendVoice =>
      'Connectez-vous pour envoyer un message vocal';

  @override
  String get translateVoice => 'Traduire le message vocal';

  @override
  String get checkingTranslation => 'Vérification de la traduction hors ligne…';

  @override
  String get offlineTranslation => 'Traduction hors ligne · 2,6 Go';

  @override
  String get installGemma => 'Installer Gemma 4 pour traduire';

  @override
  String get noReplayData => 'Aucune donnée à relire';

  @override
  String get tapToReplay => 'Appuyer pour relire';

  @override
  String get transcript => 'Transcription';

  @override
  String translationFailed(String error) {
    return 'Échec de la traduction : $error';
  }

  @override
  String speechFailed(String error) {
    return 'Échec de la parole : $error';
  }

  @override
  String get delivered => 'Livré';

  @override
  String get incomingVoiceCall => 'Appel vocal entrant';

  @override
  String get calling => 'Appel…';

  @override
  String get connected => 'Connecté';

  @override
  String get callEnded => 'Appel terminé';

  @override
  String get meshUser => 'Utilisateur Mesh';

  @override
  String get transmitting => 'Transmission…';

  @override
  String callActionFailed(String error) {
    return 'Échec de l’action d’appel : $error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return 'Échec de la transmission vocale : $error';
  }

  @override
  String get unspecified => 'Non spécifié';

  @override
  String get gatewayType => 'Passerelle';

  @override
  String get blue => 'Bleu';

  @override
  String get red => 'Rouge';

  @override
  String get green => 'Vert';

  @override
  String get orange => 'Orange';

  @override
  String get purple => 'Violet';

  @override
  String get teal => 'Sarcelle';

  @override
  String get gray => 'Gris';

  @override
  String get tempHumidity => 'Temp. et humidité';

  @override
  String get latestValue => 'Dernière valeur';

  @override
  String get imuOrientation => 'Orientation IMU';

  @override
  String get binaryData => 'Données binaires';

  @override
  String get timeSeries => 'Série temporelle';

  @override
  String get last30Minutes => '30 dernières min';

  @override
  String get lastHour => 'Dernière heure';

  @override
  String get last6Hours => '6 dernières heures';

  @override
  String get switchTo2d => 'Passer en 2D';

  @override
  String get switchTo3d => 'Passer en 3D';

  @override
  String get useDayMap => 'Utiliser la carte de jour';

  @override
  String get useNightMap => 'Utiliser la carte de nuit';

  @override
  String get useStandardMap => 'Utiliser la carte standard';

  @override
  String get useSatelliteImagery => 'Utiliser l’imagerie satellite';

  @override
  String downloadMapQuestion(String region) {
    return 'Télécharger la carte : $region ?';
  }

  @override
  String get mapCachedDescription =>
      'Elle sera mise en cache pour une utilisation hors ligne.';

  @override
  String get noNodesSharingLocation =>
      'Aucun nœud maillé ne partage sa position';

  @override
  String get unableChangeMap => 'Impossible de changer la vue de la carte';

  @override
  String get zoomForMap =>
      'Zoomez sur une zone non mise en cache pour télécharger sa carte détaillée.';

  @override
  String get deviceLicenseInvalid => 'Licence de l’appareil invalide';

  @override
  String get licenseNoResponse =>
      'L’appareil n’a pas renvoyé de licence valide.';

  @override
  String get provisioningCannotContinue =>
      'Le provisionnement ne peut pas continuer sur cet appareil.';

  @override
  String get ok => 'OK';

  @override
  String get selectDeviceMode =>
      'Sélectionnez le mode Balise, Capteur ou Relais';

  @override
  String stepProgress(int current, int total, String title) {
    return 'Étape $current sur $total : $title';
  }

  @override
  String get provisioningUnavailable => 'Le provisionnement est indisponible.';

  @override
  String get beaconModeDescription =>
      'Annonce un profil d’appareil et sa position.';

  @override
  String get sensorModeDescription =>
      'Annonce un profil d’appareil et les mesures du capteur.';

  @override
  String get relayModeDescription =>
      'Étend la couverture du maillage sans profil d’appareil.';

  @override
  String get chooseDeviceMode =>
      'Choisissez le fonctionnement de cet appareil EdgeZ.';

  @override
  String get regenerateDeviceId => 'Régénérer l’ID de l’appareil';

  @override
  String get deviceGpsWakeDescription =>
      'Réveil périodique pour la position, puis extinction du récepteur';

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
