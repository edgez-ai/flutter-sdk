// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get selectRelayWifi => '请选择上游 Wi-Fi 或 SoftAP 后继续。';

  @override
  String get relayWifi => '中继 Wi-Fi';

  @override
  String get upstreamWifi => '上游 Wi-Fi';

  @override
  String get softapProvisioningDescription =>
      'SoftAP 使用“网络”步骤中的 Mesh SSID 和密码。密码留空则为开放网络。';

  @override
  String get invalidRelayWifi =>
      'SSID 须为 1–32 字节，密码留空或为 8–63 字节。上游 Wi-Fi 也支持 64 位十六进制 PSK。';

  @override
  String get clearBleSelection => '清除';

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
  String get marketplace => '市场';

  @override
  String get cancel => '取消';

  @override
  String get install => '安装';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get saving => '正在保存';

  @override
  String get loading => '正在加载';

  @override
  String get next => '下一步';

  @override
  String get download => '下载';

  @override
  String get notNow => '暂不';

  @override
  String get refresh => '刷新';

  @override
  String get delete => '删除';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get device => '设备';

  @override
  String get dashboardVisualization => '仪表盘可视化';

  @override
  String get widget => '组件';

  @override
  String get range => '范围';

  @override
  String get type => '类型';

  @override
  String get sleeping => '休眠中';

  @override
  String get geoFence => '地理围栏';

  @override
  String get none => '无';

  @override
  String get sensor => '传感器';

  @override
  String get noSensorData => '尚未收到传感器数据';

  @override
  String get temperature => '温度';

  @override
  String get humidity => '湿度';

  @override
  String get pressure => '气压';

  @override
  String get altitude => '海拔';

  @override
  String get sensorTimeSeries => '传感器时序';

  @override
  String get provisioning => '配置';

  @override
  String get selectBleDevice => '选择 BLE 设备';

  @override
  String get scanAgain => '重新扫描';

  @override
  String get scanningDevices => '正在扫描 EdgeZ 设备……';

  @override
  String get beacon => '信标';

  @override
  String get relay => '中继';

  @override
  String get network => '网络';

  @override
  String get frequency => '频率';

  @override
  String get latitude => '纬度';

  @override
  String get longitude => '经度';

  @override
  String get usePhoneLocation => '使用手机位置';

  @override
  String get enableGeoFence => '启用地理围栏';

  @override
  String get geoFenceName => '地理围栏名称';

  @override
  String get geoIndex => '地理索引';

  @override
  String get sensorDrivers => '传感器驱动';

  @override
  String get sleepMode => '休眠模式';

  @override
  String get enableSleepMode => '启用休眠模式';

  @override
  String get sleepModeDescription => '允许设备进入低功耗休眠。';

  @override
  String get answer => '接听';

  @override
  String get decline => '拒绝';

  @override
  String get end => '结束';

  @override
  String get holdToTalk => '按住说话';

  @override
  String get noMessages => '暂无消息';

  @override
  String get message => '消息';

  @override
  String get send => '发送';

  @override
  String get hop => '跳数';

  @override
  String get routes => '路由';

  @override
  String get publicChannels => '公开频道';

  @override
  String get system => '系统';

  @override
  String get deviceLogs => '设备日志';

  @override
  String get transport => '传输';

  @override
  String get prune => '清理';

  @override
  String get open => '打开';

  @override
  String get meshOverview => 'Mesh 概览';

  @override
  String get interfaceLabel => '接口';

  @override
  String get knownNodes => '已知节点';

  @override
  String get license => '许可证';

  @override
  String get visualizationWidgets => '可视化组件';

  @override
  String get noDashboardDevices => '仪表盘中暂无设备';

  @override
  String get temp => '温度';

  @override
  String get passByScore => '通过评分';

  @override
  String get backToSettings => '返回设置';

  @override
  String get speedAndLoss => '速度和丢包 · 过去 30 分钟';

  @override
  String get movingSpeed => '移动平均速度';

  @override
  String get movingLoss => '移动平均丢包';

  @override
  String get speed => '速度';

  @override
  String get loss => '丢包';

  @override
  String get activeConnection => '当前连接';

  @override
  String get status => '状态';

  @override
  String get conversations => '会话';

  @override
  String get database => '数据库';

  @override
  String get halowMesh => 'HaLow Mesh';

  @override
  String get supported => '支持';

  @override
  String get initialized => '已初始化';

  @override
  String get meshMode => 'Mesh 模式';

  @override
  String get linkUp => '链路已连接';

  @override
  String get routeReady => '路由就绪';

  @override
  String get readyForReport => '可上报';

  @override
  String get gateway => '网关';

  @override
  String get sdkEvents => 'SDK 事件';

  @override
  String get logStream => '日志流';

  @override
  String get links => '链路';

  @override
  String get window => '时间窗';

  @override
  String get direct => '直连';

  @override
  String get relayed => '中继';

  @override
  String get refreshRouting => '刷新路由表';

  @override
  String get downloadOfflineMap => '下载离线地图';

  @override
  String get transcribeAgain => '使用设置中的语言重新转录';

  @override
  String get speakTranslation => '朗读译文';

  @override
  String get upstreamNetwork => '上游网络';

  @override
  String get refreshUsb => '刷新 USB 设备';

  @override
  String get uartConnector => 'UART / I2C 连接器';

  @override
  String get rs485Connector => 'RS485 连接器';

  @override
  String get upstreamWifiSsid => '上游 Wi-Fi SSID';

  @override
  String get upstreamWifiPassphrase => '上游 Wi-Fi 密码';

  @override
  String get beaconMulticast => '信标多播';

  @override
  String get loggingHelper => '应用于设备输出和应用日志存储';

  @override
  String incomingCallFrom(String name) {
    return '来自 $name 的呼叫';
  }

  @override
  String get selectedDevice => '已选设备';

  @override
  String get noDeviceSelected => '未选择设备';

  @override
  String get usbConnected => 'USB 已连接；高速通道就绪';

  @override
  String get bleControlReady => 'BLE 已连接；控制通道就绪';

  @override
  String get bleSettingUp => 'BLE 已连接；正在设置控制通道';

  @override
  String get blePairing => 'BLE 正在配对或连接';

  @override
  String get disconnected => '已断开';

  @override
  String firmwareVersion(String version) {
    return '固件：$version';
  }

  @override
  String get waitingBle => '正在等待 BLE 连接';

  @override
  String get connectBleDevice => '连接 BLE 设备';

  @override
  String get waitingBleControl => '正在等待 BLE 控制通道';

  @override
  String get waitingDeviceStatus => '正在等待设备状态';

  @override
  String updatingProgress(int percent) {
    return '正在更新 $percent%';
  }

  @override
  String get otaUnsupported => '当前连接的固件尚不支持 OTA。';

  @override
  String identifier(String value) {
    return 'ID $value';
  }

  @override
  String get notLoaded => '未加载';

  @override
  String get useDeviceGps => '使用设备 GPS (L76K)';

  @override
  String get deviceGpsDescription => '使用周期性低功耗设备定位，而非手机/静态位置';

  @override
  String deviceFix(String latitude, String longitude) {
    return '设备定位：$latitude, $longitude';
  }

  @override
  String get refreshPhoneLocation => '刷新手机位置';

  @override
  String get geofenceBeaconDescription => '在设备广播中包含地理围栏';

  @override
  String get enableSensors => '启用传感器';

  @override
  String get sensorConnectorDescription => '配置设备传感器连接器';

  @override
  String get enableUpstreamNetwork => '启用上游网络';

  @override
  String get upstreamDescription => '通过 Wi-Fi 转发并将信标发送到多播地址。';

  @override
  String get notSet => '未设置';

  @override
  String get translationLanguageDescription =>
      '作为会话的初始目标语言。系统会检测一次口语语言，并将其与转录一起保存。';

  @override
  String get selectBleOrUsb => '选择 BLE 或 USB 设备';

  @override
  String get noUsbDevices => '未连接 USB 设备。请使用 USB OTG 线连接。';

  @override
  String get bluetooth => '蓝牙';

  @override
  String get userIdentity => '用户身份';

  @override
  String get loadingIdentity => '正在加载身份';

  @override
  String get publicKey => 'X25519 公钥';

  @override
  String get privateKey => 'X25519 私钥';

  @override
  String get regenerateKeyPair => '重新生成密钥对';

  @override
  String get recording => '正在录音';

  @override
  String get requestingMicrophone => '正在请求麦克风权限';

  @override
  String get microphoneDenied => '麦克风权限已拒绝';

  @override
  String get startingVoice => '正在启动语音';

  @override
  String get voiceCancelled => '语音已取消';

  @override
  String get sendingVoice => '正在发送语音';

  @override
  String get voiceSent => '语音已发送';

  @override
  String get sending => '正在发送';

  @override
  String get sentToDevice => '已发送到设备';

  @override
  String get encrypted => '已加密';

  @override
  String get waitingForKey => '正在等待密钥';

  @override
  String get joinTalkgroup => '加入 OpenMANET 通话组';

  @override
  String get startVoiceCall => '开始语音通话';

  @override
  String get noSensorGps => '无传感器 GPS';

  @override
  String get connectToSendVoice => '连接后可发送语音';

  @override
  String get translateVoice => '翻译语音';

  @override
  String get checkingTranslation => '正在检查离线翻译……';

  @override
  String get offlineTranslation => '离线翻译 · 2.6 GB';

  @override
  String get installGemma => '安装 Gemma 4 以进行翻译';

  @override
  String get noReplayData => '无可回放数据';

  @override
  String get tapToReplay => '点击回放';

  @override
  String get transcript => '转录';

  @override
  String translationFailed(String error) {
    return '翻译失败：$error';
  }

  @override
  String speechFailed(String error) {
    return '语音失败：$error';
  }

  @override
  String get delivered => '已送达';

  @override
  String get incomingVoiceCall => '语音来电';

  @override
  String get calling => '正在呼叫……';

  @override
  String get connected => '已连接';

  @override
  String get callEnded => '通话已结束';

  @override
  String get meshUser => 'Mesh 用户';

  @override
  String get transmitting => '正在传输……';

  @override
  String callActionFailed(String error) {
    return '通话操作失败：$error';
  }

  @override
  String voiceTransmissionFailed(String error) {
    return '语音传输失败：$error';
  }

  @override
  String get unspecified => '未指定';

  @override
  String get gatewayType => '网关';

  @override
  String get blue => '蓝色';

  @override
  String get red => '红色';

  @override
  String get green => '绿色';

  @override
  String get orange => '橙色';

  @override
  String get purple => '紫色';

  @override
  String get teal => '青色';

  @override
  String get gray => '灰色';

  @override
  String get tempHumidity => '温度和湿度';

  @override
  String get latestValue => '最新值';

  @override
  String get imuOrientation => 'IMU 姿态';

  @override
  String get binaryData => '二进制数据';

  @override
  String get timeSeries => '时间序列';

  @override
  String get last30Minutes => '过去 30 分钟';

  @override
  String get lastHour => '过去 1 小时';

  @override
  String get last6Hours => '过去 6 小时';

  @override
  String get switchTo2d => '切换到 2D';

  @override
  String get switchTo3d => '切换到 3D';

  @override
  String get useDayMap => '使用日间地图';

  @override
  String get useNightMap => '使用夜间地图';

  @override
  String get useStandardMap => '使用标准地图';

  @override
  String get useSatelliteImagery => '使用卫星影像';

  @override
  String downloadMapQuestion(String region) {
    return '下载地图：$region？';
  }

  @override
  String get mapCachedDescription => '地图将被缓存以供离线使用。';

  @override
  String get noNodesSharingLocation => '没有 Mesh 节点正在共享位置';

  @override
  String get unableChangeMap => '无法更改地图视图';

  @override
  String get zoomForMap => '放大到未缓存的区域以下载详细地图。';

  @override
  String get deviceLicenseInvalid => '设备许可证无效';

  @override
  String get licenseNoResponse => '设备未返回有效的许可证响应。';

  @override
  String get provisioningCannotContinue => '无法在此设备上继续配置。';

  @override
  String get ok => '确定';

  @override
  String get selectDeviceMode => '请选择信标、传感器或中继模式';

  @override
  String stepProgress(int current, int total, String title) {
    return '第 $current/$total 步：$title';
  }

  @override
  String get provisioningUnavailable => '无法进行配置。';

  @override
  String get beaconModeDescription => '广播设备配置和位置。';

  @override
  String get sensorModeDescription => '广播设备配置和传感器读数。';

  @override
  String get relayModeDescription => '在不使用设备配置的情况下扩展 Mesh 覆盖。';

  @override
  String get chooseDeviceMode => '选择此 EdgeZ 设备的运行方式。';

  @override
  String get regenerateDeviceId => '重新生成设备 ID';

  @override
  String get deviceGpsWakeDescription => '周期性唤醒定位，然后关闭接收器';

  @override
  String get dashboardEmptyDescription => '使用节点上的仪盘按钮添加设备，然后在设备详情中选择可视化方式。';

  @override
  String get nearbyDevices => '附近的 BLE 设备将显示在此。';

  @override
  String settingsLanguageSemantics(String language) {
    return '当前应用语言：$language';
  }
}
