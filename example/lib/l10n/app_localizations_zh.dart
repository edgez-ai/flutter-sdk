// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'EdgeZ';

  @override
  String get dashboard => '仪表盘';

  @override
  String get nodes => '节点';

  @override
  String get map => '地图';

  @override
  String get drivers => '驱动';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageDescription => '选择应用使用的语言';

  @override
  String get deviceConnection => '设备连接';

  @override
  String get select => '选择';

  @override
  String get connect => '连接';

  @override
  String get connecting => '正在连接……';

  @override
  String get disconnect => '断开连接';

  @override
  String get autoConnect => '自动连接';

  @override
  String get autoConnectDescription => '应用启动时连接已选 BLE 设备，断开后自动重连';

  @override
  String get user => '用户';

  @override
  String get meshNetwork => 'Mesh 网络';

  @override
  String get others => '其他';

  @override
  String get deviceUser => '设备用户';

  @override
  String get userName => '用户名';

  @override
  String get deviceUserName => '设备用户名';

  @override
  String get marker => '标记';

  @override
  String get location => '位置';

  @override
  String get deviceLocation => '设备位置';

  @override
  String get shareLocation => '共享位置';

  @override
  String get shareLocationDescription => '在 HaLow 广播中包含位置';

  @override
  String get country => '国家/地区';

  @override
  String get bandwidth => '带宽';

  @override
  String get channel => '信道';

  @override
  String get meshId => 'Mesh ID / SSID';

  @override
  String get passphrase => '密码';

  @override
  String get maxHop => '最大跳数';

  @override
  String get beaconInterval => '广播间隔（秒）';

  @override
  String get saveSettings => '保存设置';

  @override
  String get logging => '日志';

  @override
  String get logLevel => '日志级别';

  @override
  String get chat => '聊天';

  @override
  String get defaultTranslationLanguage => '默认翻译语言';

  @override
  String get autoReplayVoice => '自动播放收到的语音';

  @override
  String get autoReplayVoiceDescription => '自动播放新收到的语音消息';

  @override
  String get debug => '调试';

  @override
  String get back => '返回';

  @override
  String get deviceMode => '设备模式';

  @override
  String get phoneMode => '手机模式';

  @override
  String get checkForUpdate => '检查更新';

  @override
  String get checking => '正在检查……';

  @override
  String get update => '更新';

  @override
  String settingsLanguageSemantics(String language) {
    return '当前应用语言：$language';
  }
}
