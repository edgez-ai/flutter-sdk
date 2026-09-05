// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get selectRelayWifi =>
      'Seleccione Wi-Fi de enlace o SoftAP para continuar.';

  @override
  String get relayWifi => 'Wi-Fi del repetidor';

  @override
  String get upstreamWifi => 'Wi-Fi de enlace';

  @override
  String get softapProvisioningDescription =>
      'SoftAP usa el SSID y la contraseña de la malla del paso Red. Deje la contraseña vacía para una red abierta.';

  @override
  String get invalidRelayWifi =>
      'SSID: 1–32 bytes. Contraseña: vacía o 8–63 bytes. El Wi-Fi de enlace también admite una PSK de 64 dígitos hexadecimales.';

  @override
  String get clearBleSelection => 'Borrar';

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
  String get marketplace => 'Mercado';

  @override
  String get cancel => 'Cancelar';

  @override
  String get install => 'Instalar';

  @override
  String get close => 'Cerrar';

  @override
  String get save => 'Guardar';

  @override
  String get saving => 'Guardando';

  @override
  String get loading => 'Cargando';

  @override
  String get next => 'Siguiente';

  @override
  String get download => 'Descargar';

  @override
  String get notNow => 'Ahora no';

  @override
  String get refresh => 'Actualizar';

  @override
  String get delete => 'Eliminar';

  @override
  String get enabled => 'Activado';

  @override
  String get disabled => 'Desactivado';

  @override
  String get device => 'Dispositivo';

  @override
  String get dashboardVisualization => 'Visualización del panel';

  @override
  String get widget => 'Widget';

  @override
  String get range => 'Rango';

  @override
  String get type => 'Tipo';

  @override
  String get sleeping => 'En reposo';

  @override
  String get geoFence => 'Geocerca';

  @override
  String get none => 'Ninguno';

  @override
  String get sensor => 'Sensor';

  @override
  String get noSensorData => 'Aún no se han recibido datos del sensor';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Humedad';

  @override
  String get pressure => 'Presión';

  @override
  String get altitude => 'Altitud';

  @override
  String get sensorTimeSeries => 'Serie temporal del sensor';

  @override
  String get provisioning => 'Aprovisionamiento';

  @override
  String get selectBleDevice => 'Seleccionar dispositivo BLE';

  @override
  String get scanAgain => 'Buscar de nuevo';

  @override
  String get scanningDevices => 'Buscando dispositivos EdgeZ…';

  @override
  String get beacon => 'Baliza';

  @override
  String get relay => 'Repetidor';

  @override
  String get network => 'Red';

  @override
  String get frequency => 'Frecuencia';

  @override
  String get latitude => 'Latitud';

  @override
  String get longitude => 'Longitud';

  @override
  String get usePhoneLocation => 'Usar ubicación del teléfono';

  @override
  String get enableGeoFence => 'Activar geocerca';

  @override
  String get geoFenceName => 'Nombre de geocerca';

  @override
  String get geoIndex => 'Índice geográfico';

  @override
  String get sensorDrivers => 'Controladores de sensores';

  @override
  String get sleepMode => 'Modo de reposo';

  @override
  String get enableSleepMode => 'Activar modo de reposo';

  @override
  String get sleepModeDescription =>
      'Permitir que el dispositivo entre en reposo de bajo consumo.';

  @override
  String get answer => 'Responder';

  @override
  String get decline => 'Rechazar';

  @override
  String get end => 'Finalizar';

  @override
  String get holdToTalk => 'Mantener para hablar';

  @override
  String get noMessages => 'Aún no hay mensajes';

  @override
  String get message => 'Mensaje';

  @override
  String get send => 'Enviar';

  @override
  String get hop => 'Salto';

  @override
  String get routes => 'Rutas';

  @override
  String get publicChannels => 'Canales públicos';

  @override
  String get system => 'Sistema';

  @override
  String get deviceLogs => 'Registros del dispositivo';

  @override
  String get transport => 'Transporte';

  @override
  String get prune => 'Purgar';

  @override
  String get open => 'Abrir';

  @override
  String get meshOverview => 'Resumen de la malla';

  @override
  String get interfaceLabel => 'Interfaz';

  @override
  String get knownNodes => 'Nodos conocidos';

  @override
  String get license => 'Licencia';

  @override
  String get visualizationWidgets => 'Widgets de visualización';

  @override
  String get noDashboardDevices => 'Aún no hay dispositivos en el panel';

  @override
  String get temp => 'Temp.';

  @override
  String get passByScore => 'Puntuación de paso';

  @override
  String get backToSettings => 'Volver a ajustes';

  @override
  String get speedAndLoss => 'Velocidad y pérdida · últimos 30 minutos';

  @override
  String get movingSpeed => 'Velocidad media';

  @override
  String get movingLoss => 'Pérdida media';

  @override
  String get speed => 'Velocidad';

  @override
  String get loss => 'Pérdida';

  @override
  String get activeConnection => 'Conexión activa';

  @override
  String get status => 'Estado';

  @override
  String get conversations => 'Conversaciones';

  @override
  String get database => 'Base de datos';

  @override
  String get halowMesh => 'Malla HaLow';

  @override
  String get supported => 'Compatible';

  @override
  String get initialized => 'Inicializado';

  @override
  String get meshMode => 'Modo malla';

  @override
  String get linkUp => 'Enlace activo';

  @override
  String get routeReady => 'Ruta lista';

  @override
  String get readyForReport => 'Listo para informar';

  @override
  String get gateway => 'Puerta de enlace';

  @override
  String get sdkEvents => 'Eventos del SDK';

  @override
  String get logStream => 'Flujo de registros';

  @override
  String get links => 'Enlaces';

  @override
  String get window => 'Ventana';

  @override
  String get direct => 'Directo';

  @override
  String get relayed => 'Retransmitido';

  @override
  String get refreshRouting => 'Actualizar tabla de rutas';

  @override
  String get downloadOfflineMap => 'Descargar mapa sin conexión';

  @override
  String get transcribeAgain => 'Volver a transcribir con el idioma de Ajustes';

  @override
  String get speakTranslation => 'Reproducir traducción';

  @override
  String get upstreamNetwork => 'Red ascendente';

  @override
  String get refreshUsb => 'Actualizar dispositivos USB';

  @override
  String get uartConnector => 'Conector UART / I2C';

  @override
  String get rs485Connector => 'Conector RS485';

  @override
  String get upstreamWifiSsid => 'SSID Wi-Fi ascendente';

  @override
  String get upstreamWifiPassphrase => 'Contraseña Wi-Fi ascendente';

  @override
  String get beaconMulticast => 'Multidifusión de baliza';

  @override
  String get loggingHelper =>
      'Se aplica a la salida del dispositivo y al almacenamiento de registros';

  @override
  String incomingCallFrom(String name) {
    return 'Llamada entrante de $name';
  }

  @override
  String get selectedDevice => 'Dispositivo seleccionado';

  @override
  String get noDeviceSelected => 'Ningún dispositivo seleccionado';

  @override
  String get usbConnected => 'USB conectado; canal de alta velocidad listo';

  @override
  String get bleControlReady => 'BLE conectado; canal de control listo';

  @override
  String get bleSettingUp => 'BLE conectado; configurando canal de control';

  @override
  String get blePairing => 'Emparejando o conectando BLE';

  @override
  String get disconnected => 'Desconectado';

  @override
  String firmwareVersion(String version) {
    return 'Firmware: $version';
  }

  @override
  String get waitingBle => 'Esperando conexión BLE';

  @override
  String get connectBleDevice => 'Conectar un dispositivo BLE';

  @override
  String get waitingBleControl => 'Esperando canal de control BLE';

  @override
  String get waitingDeviceStatus => 'Esperando estado del dispositivo';

  @override
  String updatingProgress(int percent) {
    return 'Actualizando $percent%';
  }

  @override
  String get otaUnsupported => 'El firmware conectado aún no ofrece BLE OTA.';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => 'No cargado';

  @override
  String get useDeviceGps => 'Usar GPS del dispositivo (L76K)';

  @override
  String get deviceGpsDescription =>
      'Usar posiciones periódicas de bajo consumo en vez de la ubicación del teléfono/estática';

  @override
  String deviceFix(String latitude, String longitude) {
    return 'Posición del dispositivo: $latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => 'Actualizar ubicación del teléfono';

  @override
  String get geofenceBeaconDescription =>
      'Incluir una geocerca en las balizas del dispositivo';

  @override
  String get enableSensors => 'Activar sensores';

  @override
  String get sensorConnectorDescription => 'Configurar conectores de sensores';

  @override
  String get enableUpstreamNetwork => 'Activar red ascendente';

  @override
  String get upstreamDescription =>
      'Reenviar por Wi-Fi y enviar balizas a una dirección multidifusión.';

  @override
  String get notSet => 'Sin configurar';

  @override
  String get translationLanguageDescription =>
      'Se usa como idioma de destino inicial en conversaciones. El idioma hablado se detecta una vez y se guarda con la transcripción.';

  @override
  String get selectBleOrUsb => 'Seleccionar dispositivo BLE o USB';

  @override
  String get noUsbDevices =>
      'No hay dispositivos USB conectados. Conecta mediante un cable USB OTG.';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get userIdentity => 'Identidad de usuario';

  @override
  String get loadingIdentity => 'Cargando identidad';

  @override
  String get publicKey => 'Clave pública X25519';

  @override
  String get privateKey => 'Clave privada X25519';

  @override
  String get regenerateKeyPair => 'Regenerar par de claves';

  @override
  String get recording => 'Grabando';

  @override
  String get requestingMicrophone => 'Solicitando micrófono';

  @override
  String get microphoneDenied => 'Permiso de micrófono denegado';

  @override
  String get startingVoice => 'Iniciando voz';

  @override
  String get voiceCancelled => 'Voz cancelada';

  @override
  String get sendingVoice => 'Enviando voz';

  @override
  String get voiceSent => 'Voz enviada';

  @override
  String get sending => 'Enviando';

  @override
  String get sentToDevice => 'Enviado al dispositivo';

  @override
  String get encrypted => 'Cifrado';

  @override
  String get waitingForKey => 'Esperando clave';

  @override
  String get joinTalkgroup => 'Unirse al grupo OpenMANET';

  @override
  String get startVoiceCall => 'Iniciar llamada de voz';

  @override
  String get noSensorGps => 'Sin GPS del sensor';

  @override
  String get connectToSendVoice => 'Conéctate para enviar voz';

  @override
  String get translateVoice => 'Traducir voz';

  @override
  String get checkingTranslation => 'Comprobando traducción sin conexión…';

  @override
  String get offlineTranslation => 'Traducción sin conexión · 2,6 GB';

  @override
  String get installGemma => 'Instala Gemma 4 para traducir';

  @override
  String get noReplayData => 'No hay datos para reproducir';

  @override
  String get tapToReplay => 'Toca para reproducir';

  @override
  String get transcript => 'Transcripción';

  @override
  String translationFailed(String error) {
    return 'Error de traducción: $error';
  }

  @override
  String speechFailed(String error) {
    return 'Error de voz: $error';
  }

  @override
  String get delivered => 'Entregado';

  @override
  String get incomingVoiceCall => 'Llamada de voz entrante';

  @override
  String get calling => 'Llamando…';

  @override
  String get connected => 'Conectado';

  @override
  String get callEnded => 'Llamada finalizada';

  @override
  String get meshUser => 'Usuario de malla';

  @override
  String get transmitting => 'Transmitiendo…';

  @override
  String callActionFailed(String error) {
    return 'Error en la llamada: $error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return 'Error de transmisión de voz: $error';
  }

  @override
  String get unspecified => 'Sin especificar';

  @override
  String get gatewayType => 'Puerta de enlace';

  @override
  String get blue => 'Azul';

  @override
  String get red => 'Rojo';

  @override
  String get green => 'Verde';

  @override
  String get orange => 'Naranja';

  @override
  String get purple => 'Morado';

  @override
  String get teal => 'Verde azulado';

  @override
  String get gray => 'Gris';

  @override
  String get tempHumidity => 'Temp. y humedad';

  @override
  String get latestValue => 'Valor más reciente';

  @override
  String get imuOrientation => 'Orientación IMU';

  @override
  String get binaryData => 'Datos binarios';

  @override
  String get timeSeries => 'Serie temporal';

  @override
  String get last30Minutes => 'Últimos 30 min';

  @override
  String get lastHour => 'Última hora';

  @override
  String get last6Hours => 'Últimas 6 horas';

  @override
  String get switchTo2d => 'Cambiar a 2D';

  @override
  String get switchTo3d => 'Cambiar a 3D';

  @override
  String get useDayMap => 'Usar mapa diurno';

  @override
  String get useNightMap => 'Usar mapa nocturno';

  @override
  String get useStandardMap => 'Usar mapa estándar';

  @override
  String get useSatelliteImagery => 'Usar imágenes satelitales';

  @override
  String downloadMapQuestion(String region) {
    return '¿Descargar mapa: $region?';
  }

  @override
  String get mapCachedDescription =>
      'Se almacenará en caché para usarlo sin conexión.';

  @override
  String get noNodesSharingLocation =>
      'Ningún nodo de malla comparte su ubicación';

  @override
  String get unableChangeMap => 'No se puede cambiar la vista del mapa';

  @override
  String get zoomForMap =>
      'Amplía una región no almacenada para descargar su mapa detallado.';

  @override
  String get deviceLicenseInvalid => 'Licencia del dispositivo no válida';

  @override
  String get licenseNoResponse =>
      'El dispositivo no devolvió una respuesta de licencia válida.';

  @override
  String get provisioningCannotContinue =>
      'No se puede continuar el aprovisionamiento en este dispositivo.';

  @override
  String get ok => 'Aceptar';

  @override
  String get selectDeviceMode =>
      'Selecciona el modo Baliza, Sensor o Repetidor';

  @override
  String stepProgress(int current, int total, String title) {
    return 'Paso $current de $total: $title';
  }

  @override
  String get provisioningUnavailable =>
      'El aprovisionamiento no está disponible.';

  @override
  String get beaconModeDescription =>
      'Anuncia un perfil de dispositivo y su ubicación.';

  @override
  String get sensorModeDescription =>
      'Anuncia un perfil de dispositivo y lecturas del sensor.';

  @override
  String get relayModeDescription =>
      'Amplía la cobertura de malla sin perfil de dispositivo.';

  @override
  String get chooseDeviceMode =>
      'Elige cómo funcionará este dispositivo EdgeZ.';

  @override
  String get regenerateDeviceId => 'Regenerar ID del dispositivo';

  @override
  String get deviceGpsWakeDescription =>
      'Activar periódicamente para obtener la posición y apagar el receptor';

  @override
  String get dashboardEmptyDescription =>
      'Usa el botón del panel de un nodo para añadirlo y elige su visualización en los detalles del dispositivo.';

  @override
  String get nearbyDevices => 'Los dispositivos BLE cercanos aparecerán aquí.';

  @override
  String settingsLanguageSemantics(String language) {
    return 'Idioma actual de la aplicación: $language';
  }
}
