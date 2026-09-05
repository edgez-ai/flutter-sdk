// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get selectRelayWifi => '続行するには上流 Wi-Fi または SoftAP を選択してください。';

  @override
  String get relayWifi => 'リレー Wi-Fi';

  @override
  String get upstreamWifi => '上流 Wi-Fi';

  @override
  String get softapProvisioningDescription =>
      'SoftAP はネットワーク手順のメッシュ SSID とパスフレーズを使用します。空のパスフレーズでオープンネットワークになります。';

  @override
  String get invalidRelayWifi =>
      'SSID は 1～32 バイト、パスワードは空または 8～63 バイトにしてください。上流 Wi-Fi は 64 桁の16進数 PSK も使用できます。';

  @override
  String get clearBleSelection => 'クリア';

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => 'ダッシュボード';

  @override
  String get nodes => 'ノード';

  @override
  String get map => 'マップ';

  @override
  String get drivers => 'ドライバー';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageDescription => 'アプリで使用する言語を選択';

  @override
  String get deviceConnection => 'デバイス接続';

  @override
  String get select => '選択';

  @override
  String get connect => '接続';

  @override
  String get connecting => '接続中…';

  @override
  String get disconnect => '切断';

  @override
  String get autoConnect => '自動接続';

  @override
  String get autoConnectDescription => 'アプリ起動時に選択済みの BLE デバイスに接続し、切断時は再接続します';

  @override
  String get user => 'ユーザー';

  @override
  String get meshNetwork => 'メッシュネットワーク';

  @override
  String get others => 'その他';

  @override
  String get deviceUser => 'デバイスユーザー';

  @override
  String get userName => 'ユーザー名';

  @override
  String get deviceUserName => 'デバイスユーザー名';

  @override
  String get marker => 'マーカー';

  @override
  String get location => '位置';

  @override
  String get deviceLocation => 'デバイスの位置';

  @override
  String get shareLocation => '位置を共有';

  @override
  String get shareLocationDescription => 'HaLow ビーコンに位置を含める';

  @override
  String get country => '国/地域';

  @override
  String get bandwidth => '帯域幅';

  @override
  String get channel => 'チャンネル';

  @override
  String get meshId => 'Mesh ID / SSID';

  @override
  String get passphrase => 'パスフレーズ';

  @override
  String get maxHop => '最大ホップ数';

  @override
  String get beaconInterval => 'ビーコン間隔（秒）';

  @override
  String get saveSettings => '設定を保存';

  @override
  String get logging => 'ログ';

  @override
  String get logLevel => 'ログレベル';

  @override
  String get chat => 'チャット';

  @override
  String get defaultTranslationLanguage => '既定の翻訳言語';

  @override
  String get autoReplayVoice => '受信音声を自動再生';

  @override
  String get autoReplayVoiceDescription => '新しい受信音声メッセージを自動再生';

  @override
  String get debug => 'デバッグ';

  @override
  String get back => '戻る';

  @override
  String get deviceMode => 'デバイスモード';

  @override
  String get phoneMode => 'スマートフォンモード';

  @override
  String get checkForUpdate => '更新を確認';

  @override
  String get checking => '確認中…';

  @override
  String get update => '更新';

  @override
  String get marketplace => 'マーケット';

  @override
  String get cancel => 'キャンセル';

  @override
  String get install => 'インストール';

  @override
  String get close => '閉じる';

  @override
  String get save => '保存';

  @override
  String get saving => '保存中';

  @override
  String get loading => '読み込み中';

  @override
  String get next => '次へ';

  @override
  String get download => 'ダウンロード';

  @override
  String get notNow => '後で';

  @override
  String get refresh => '更新';

  @override
  String get delete => '削除';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String get device => 'デバイス';

  @override
  String get dashboardVisualization => 'ダッシュボード表示';

  @override
  String get widget => 'ウィジェット';

  @override
  String get range => '範囲';

  @override
  String get type => '種類';

  @override
  String get sleeping => 'スリープ中';

  @override
  String get geoFence => 'ジオフェンス';

  @override
  String get none => 'なし';

  @override
  String get sensor => 'センサー';

  @override
  String get noSensorData => 'センサーデータはまだありません';

  @override
  String get temperature => '温度';

  @override
  String get humidity => '湿度';

  @override
  String get pressure => '気圧';

  @override
  String get altitude => '高度';

  @override
  String get sensorTimeSeries => 'センサー時系列';

  @override
  String get provisioning => 'プロビジョニング';

  @override
  String get selectBleDevice => 'BLE デバイスを選択';

  @override
  String get scanAgain => '再スキャン';

  @override
  String get scanningDevices => 'EdgeZ デバイスを検索中…';

  @override
  String get beacon => 'ビーコン';

  @override
  String get relay => 'リレー';

  @override
  String get network => 'ネットワーク';

  @override
  String get frequency => '周波数';

  @override
  String get latitude => '緯度';

  @override
  String get longitude => '経度';

  @override
  String get usePhoneLocation => 'スマートフォンの位置を使用';

  @override
  String get enableGeoFence => 'ジオフェンスを有効化';

  @override
  String get geoFenceName => 'ジオフェンス名';

  @override
  String get geoIndex => 'ジオインデックス';

  @override
  String get sensorDrivers => 'センサードライバー';

  @override
  String get sleepMode => 'スリープモード';

  @override
  String get enableSleepMode => 'スリープモードを有効化';

  @override
  String get sleepModeDescription => 'デバイスの低電力スリープを許可します。';

  @override
  String get answer => '応答';

  @override
  String get decline => '拒否';

  @override
  String get end => '終了';

  @override
  String get holdToTalk => '押して話す';

  @override
  String get noMessages => 'メッセージはまだありません';

  @override
  String get message => 'メッセージ';

  @override
  String get send => '送信';

  @override
  String get hop => 'ホップ';

  @override
  String get routes => 'ルート';

  @override
  String get publicChannels => '公開チャンネル';

  @override
  String get system => 'システム';

  @override
  String get deviceLogs => 'デバイスログ';

  @override
  String get transport => 'トランスポート';

  @override
  String get prune => '消去';

  @override
  String get open => '開く';

  @override
  String get meshOverview => 'メッシュの概要';

  @override
  String get interfaceLabel => 'インターフェース';

  @override
  String get knownNodes => '既知のノード';

  @override
  String get license => 'ライセンス';

  @override
  String get visualizationWidgets => '可視化ウィジェット';

  @override
  String get noDashboardDevices => 'ダッシュボードデバイスはまだありません';

  @override
  String get temp => '温度';

  @override
  String get passByScore => '通過スコア';

  @override
  String get backToSettings => '設定に戻る';

  @override
  String get speedAndLoss => '速度とロス · 過去30分';

  @override
  String get movingSpeed => '移動平均速度';

  @override
  String get movingLoss => '移動平均ロス';

  @override
  String get speed => '速度';

  @override
  String get loss => 'ロス';

  @override
  String get activeConnection => 'アクティブな接続';

  @override
  String get status => '状態';

  @override
  String get conversations => '会話';

  @override
  String get database => 'データベース';

  @override
  String get halowMesh => 'HaLow メッシュ';

  @override
  String get supported => '対応';

  @override
  String get initialized => '初期化済み';

  @override
  String get meshMode => 'メッシュモード';

  @override
  String get linkUp => 'リンク有効';

  @override
  String get routeReady => 'ルート準備完了';

  @override
  String get readyForReport => 'レポート準備完了';

  @override
  String get gateway => 'ゲートウェイ';

  @override
  String get sdkEvents => 'SDK イベント';

  @override
  String get logStream => 'ログストリーム';

  @override
  String get links => 'リンク';

  @override
  String get window => '期間';

  @override
  String get direct => '直接';

  @override
  String get relayed => '中継';

  @override
  String get refreshRouting => 'ルーティングテーブルを更新';

  @override
  String get downloadOfflineMap => 'オフラインマップをダウンロード';

  @override
  String get transcribeAgain => '設定の言語で再文字起こし';

  @override
  String get speakTranslation => '翻訳を読み上げ';

  @override
  String get upstreamNetwork => 'アップストリームネットワーク';

  @override
  String get refreshUsb => 'USB デバイスを更新';

  @override
  String get uartConnector => 'UART / I2C コネクタ';

  @override
  String get rs485Connector => 'RS485 コネクタ';

  @override
  String get upstreamWifiSsid => 'アップストリーム Wi-Fi SSID';

  @override
  String get upstreamWifiPassphrase => 'アップストリーム Wi-Fi パスフレーズ';

  @override
  String get beaconMulticast => 'ビーコンマルチキャスト';

  @override
  String get loggingHelper => 'デバイス出力とアプリログ保存に適用';

  @override
  String incomingCallFrom(String name) {
    return '$name からの着信';
  }

  @override
  String get selectedDevice => '選択済みのデバイス';

  @override
  String get noDeviceSelected => 'デバイスが選択されていません';

  @override
  String get usbConnected => 'USB 接続済み、高速チャネル準備完了';

  @override
  String get bleControlReady => 'BLE 接続済み、制御チャネル準備完了';

  @override
  String get bleSettingUp => 'BLE 接続済み、制御チャネルを設定中';

  @override
  String get blePairing => 'BLE ペアリングまたは接続中';

  @override
  String get disconnected => '切断済み';

  @override
  String firmwareVersion(String version) {
    return 'ファームウェア: $version';
  }

  @override
  String get waitingBle => 'BLE 接続待ち';

  @override
  String get connectBleDevice => 'BLE デバイスを接続';

  @override
  String get waitingBleControl => 'BLE 制御チャネル待ち';

  @override
  String get waitingDeviceStatus => 'デバイス状態待ち';

  @override
  String updatingProgress(int percent) {
    return '更新中 $percent%';
  }

  @override
  String get otaUnsupported => '接続中のファームウェアはまだ BLE OTA を提供していません。';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => '未読み込み';

  @override
  String get useDeviceGps => 'デバイス GPS (L76K) を使用';

  @override
  String get deviceGpsDescription => 'スマートフォン/固定位置の代わりに定期的な低電力位置を使用';

  @override
  String deviceFix(String latitude, String longitude) {
    return 'デバイス位置: $latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => 'スマートフォンの位置を更新';

  @override
  String get geofenceBeaconDescription => 'デバイスビーコンにジオフェンスを含める';

  @override
  String get enableSensors => 'センサーを有効化';

  @override
  String get sensorConnectorDescription => 'センサーコネクタを設定';

  @override
  String get enableUpstreamNetwork => 'アップストリームネットワークを有効化';

  @override
  String get upstreamDescription => 'Wi-Fi 経由で転送し、ビーコンをマルチキャストアドレスに送信します。';

  @override
  String get notSet => '未設定';

  @override
  String get translationLanguageDescription =>
      '会話の初期翻訳先言語として使用されます。音声言語は一度検出され、文字起こしとともに保存されます。';

  @override
  String get selectBleOrUsb => 'BLE または USB デバイスを選択';

  @override
  String get noUsbDevices => 'USB デバイスが接続されていません。USB OTG ケーブルで接続してください。';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get userIdentity => 'ユーザー ID';

  @override
  String get loadingIdentity => 'ID を読み込み中';

  @override
  String get publicKey => 'X25519 公開鍵';

  @override
  String get privateKey => 'X25519 秘密鍵';

  @override
  String get regenerateKeyPair => '鍵ペアを再生成';

  @override
  String get recording => '録音中';

  @override
  String get requestingMicrophone => 'マイクをリクエスト中';

  @override
  String get microphoneDenied => 'マイクの権限が拒否されました';

  @override
  String get startingVoice => '音声を開始中';

  @override
  String get voiceCancelled => '音声をキャンセルしました';

  @override
  String get sendingVoice => '音声を送信中';

  @override
  String get voiceSent => '音声を送信しました';

  @override
  String get sending => '送信中';

  @override
  String get sentToDevice => 'デバイスに送信済み';

  @override
  String get encrypted => '暗号化済み';

  @override
  String get waitingForKey => '鍵待ち';

  @override
  String get joinTalkgroup => 'OpenMANET トークグループに参加';

  @override
  String get startVoiceCall => '音声通話を開始';

  @override
  String get noSensorGps => 'センサー GPS なし';

  @override
  String get connectToSendVoice => '接続して音声を送信';

  @override
  String get translateVoice => '音声を翻訳';

  @override
  String get checkingTranslation => 'オフライン翻訳を確認中…';

  @override
  String get offlineTranslation => 'オフライン翻訳 · 2.6 GB';

  @override
  String get installGemma => '翻訳用に Gemma 4 をインストール';

  @override
  String get noReplayData => '再生データなし';

  @override
  String get tapToReplay => 'タップして再生';

  @override
  String get transcript => '文字起こし';

  @override
  String translationFailed(String error) {
    return '翻訳失敗: $error';
  }

  @override
  String speechFailed(String error) {
    return '音声失敗: $error';
  }

  @override
  String get delivered => '配達済み';

  @override
  String get incomingVoiceCall => '音声着信';

  @override
  String get calling => '発信中…';

  @override
  String get connected => '接続済み';

  @override
  String get callEnded => '通話終了';

  @override
  String get meshUser => 'メッシュユーザー';

  @override
  String get transmitting => '送信中…';

  @override
  String callActionFailed(String error) {
    return '通話操作失敗: $error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return '音声送信失敗: $error';
  }

  @override
  String get unspecified => '未指定';

  @override
  String get gatewayType => 'ゲートウェイ';

  @override
  String get blue => '青';

  @override
  String get red => '赤';

  @override
  String get green => '緑';

  @override
  String get orange => 'オレンジ';

  @override
  String get purple => '紫';

  @override
  String get teal => '青緑';

  @override
  String get gray => 'グレー';

  @override
  String get tempHumidity => '温度と湿度';

  @override
  String get latestValue => '最新値';

  @override
  String get imuOrientation => 'IMU 姿勢';

  @override
  String get binaryData => 'バイナリデータ';

  @override
  String get timeSeries => '時系列';

  @override
  String get last30Minutes => '過去30分';

  @override
  String get lastHour => '過去1時間';

  @override
  String get last6Hours => '過去6時間';

  @override
  String get switchTo2d => '2D に切り替え';

  @override
  String get switchTo3d => '3D に切り替え';

  @override
  String get useDayMap => '昼間マップを使用';

  @override
  String get useNightMap => '夜間マップを使用';

  @override
  String get useStandardMap => '標準マップを使用';

  @override
  String get useSatelliteImagery => '衛星画像を使用';

  @override
  String downloadMapQuestion(String region) {
    return 'マップをダウンロード: $region?';
  }

  @override
  String get mapCachedDescription => 'オフライン使用のためにキャッシュされます。';

  @override
  String get noNodesSharingLocation => '位置を共有しているメッシュノードはありません';

  @override
  String get unableChangeMap => 'マップ表示を変更できません';

  @override
  String get zoomForMap => '未キャッシュの地域を拡大して詳細マップをダウンロードします。';

  @override
  String get deviceLicenseInvalid => 'デバイスライセンスが無効です';

  @override
  String get licenseNoResponse => 'デバイスから有効なライセンス応答がありません。';

  @override
  String get provisioningCannotContinue => 'このデバイスでプロビジョニングを続行できません。';

  @override
  String get ok => 'OK';

  @override
  String get selectDeviceMode => 'ビーコン、センサー、またはリレーモードを選択';

  @override
  String stepProgress(int current, int total, String title) {
    return '$total ステップ中 $current: $title';
  }

  @override
  String get provisioningUnavailable => 'プロビジョニングは利用できません。';

  @override
  String get beaconModeDescription => 'デバイスプロファイルと位置を配信します。';

  @override
  String get sensorModeDescription => 'デバイスプロファイルとセンサー値を配信します。';

  @override
  String get relayModeDescription => 'デバイスプロファイルなしでメッシュ範囲を拡張します。';

  @override
  String get chooseDeviceMode => 'この EdgeZ デバイスの動作を選択します。';

  @override
  String get regenerateDeviceId => 'デバイス ID を再生成';

  @override
  String get deviceGpsWakeDescription => '定期的な位置取得のために起動し、受信機を停止';

  @override
  String get dashboardEmptyDescription =>
      'ノードのダッシュボードボタンで追加し、デバイス詳細で表示方法を選択します。';

  @override
  String get nearbyDevices => '近くの BLE デバイスがここに表示されます。';

  @override
  String settingsLanguageSemantics(String language) {
    return '現在のアプリ言語: $language';
  }
}
