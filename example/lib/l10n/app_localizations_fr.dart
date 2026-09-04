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
  String settingsLanguageSemantics(String language) {
    return 'Langue actuelle de l’application : $language';
  }
}
