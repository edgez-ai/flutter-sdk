// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

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
  String settingsLanguageSemantics(String language) {
    return '現在のアプリ言語: $language';
  }
}
