// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => 'Panel';

  @override
  String get nodes => 'Nodos';

  @override
  String get map => 'Mapa';

  @override
  String get drivers => 'Controladores';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Elige el idioma de la aplicación';

  @override
  String get deviceConnection => 'Conexión del dispositivo';

  @override
  String get select => 'Seleccionar';

  @override
  String get connect => 'Conectar';

  @override
  String get connecting => 'Conectando…';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get autoConnect => 'Conexión automática';

  @override
  String get autoConnectDescription =>
      'Conecta el dispositivo BLE seleccionado al iniciar y vuelve a conectarlo si se desconecta';

  @override
  String get user => 'Usuario';

  @override
  String get meshNetwork => 'Red mallada';

  @override
  String get others => 'Otros';

  @override
  String get deviceUser => 'Usuario del dispositivo';

  @override
  String get userName => 'Nombre de usuario';

  @override
  String get deviceUserName => 'Nombre de usuario del dispositivo';

  @override
  String get marker => 'Marcador';

  @override
  String get location => 'Ubicación';

  @override
  String get deviceLocation => 'Ubicación del dispositivo';

  @override
  String get shareLocation => 'Compartir ubicación';

  @override
  String get shareLocationDescription =>
      'Incluir la ubicación en la baliza HaLow';

  @override
  String get country => 'País';

  @override
  String get bandwidth => 'Ancho de banda';

  @override
  String get channel => 'Canal';

  @override
  String get meshId => 'ID de malla / SSID';

  @override
  String get passphrase => 'Contraseña';

  @override
  String get maxHop => 'Saltos máximos';

  @override
  String get beaconInterval => 'Intervalo de baliza (segundos)';

  @override
  String get saveSettings => 'Guardar ajustes';

  @override
  String get logging => 'Registros';

  @override
  String get logLevel => 'Nivel de registro';

  @override
  String get chat => 'Chat';

  @override
  String get defaultTranslationLanguage =>
      'Idioma de traducción predeterminado';

  @override
  String get autoReplayVoice => 'Reproducir voz recibida automáticamente';

  @override
  String get autoReplayVoiceDescription =>
      'Reproducir automáticamente los mensajes de voz nuevos';

  @override
  String get debug => 'Depuración';

  @override
  String get back => 'Atrás';

  @override
  String get deviceMode => 'Modo dispositivo';

  @override
  String get phoneMode => 'Modo teléfono';

  @override
  String get checkForUpdate => 'Buscar actualización';

  @override
  String get checking => 'Comprobando…';

  @override
  String get update => 'Actualizar';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Idioma actual de la aplicación: $language';
  }
}
