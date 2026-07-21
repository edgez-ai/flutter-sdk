// This is a generated file - do not edit.
//
// Generated from edgez_mesh.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'edgez_mesh.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'edgez_mesh.pbenum.dart';

class MessageBody extends $pb.GeneratedMessage {
  factory MessageBody({
    $fixnum.Int64? messageIdHigh,
    $fixnum.Int64? messageIdLow,
    $core.int? sequence,
    Mime? mime,
    $core.List<$core.int>? payload,
    $fixnum.Int64? groupIdHigh,
    $fixnum.Int64? groupIdLow,
  }) {
    final result = create();
    if (messageIdHigh != null) result.messageIdHigh = messageIdHigh;
    if (messageIdLow != null) result.messageIdLow = messageIdLow;
    if (sequence != null) result.sequence = sequence;
    if (mime != null) result.mime = mime;
    if (payload != null) result.payload = payload;
    if (groupIdHigh != null) result.groupIdHigh = groupIdHigh;
    if (groupIdLow != null) result.groupIdLow = groupIdLow;
    return result;
  }

  MessageBody._();

  factory MessageBody.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MessageBody.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageBody',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'messageIdHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'messageIdLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(3, _omitFieldNames ? '' : 'sequence', fieldType: $pb.PbFieldType.OS3)
    ..aE<Mime>(4, _omitFieldNames ? '' : 'mime', enumValues: Mime.values)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'groupIdHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        7, _omitFieldNames ? '' : 'groupIdLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageBody clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageBody copyWith(void Function(MessageBody) updates) =>
      super.copyWith((message) => updates(message as MessageBody))
          as MessageBody;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MessageBody create() => MessageBody._();
  @$core.override
  MessageBody createEmptyInstance() => create();
  static $pb.PbList<MessageBody> createRepeated() => $pb.PbList<MessageBody>();
  @$core.pragma('dart2js:noInline')
  static MessageBody getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MessageBody>(create);
  static MessageBody? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get messageIdHigh => $_getI64(0);
  @$pb.TagNumber(1)
  set messageIdHigh($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageIdHigh() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageIdHigh() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get messageIdLow => $_getI64(1);
  @$pb.TagNumber(2)
  set messageIdLow($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageIdLow() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageIdLow() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sequence => $_getIZ(2);
  @$pb.TagNumber(3)
  set sequence($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearSequence() => $_clearField(3);

  @$pb.TagNumber(4)
  Mime get mime => $_getN(3);
  @$pb.TagNumber(4)
  set mime(Mime value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMime() => $_has(3);
  @$pb.TagNumber(4)
  void clearMime() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get payload => $_getN(4);
  @$pb.TagNumber(5)
  set payload($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayload() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get groupIdHigh => $_getI64(5);
  @$pb.TagNumber(6)
  set groupIdHigh($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGroupIdHigh() => $_has(5);
  @$pb.TagNumber(6)
  void clearGroupIdHigh() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get groupIdLow => $_getI64(6);
  @$pb.TagNumber(7)
  set groupIdLow($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasGroupIdLow() => $_has(6);
  @$pb.TagNumber(7)
  void clearGroupIdLow() => $_clearField(7);
}

class Report extends $pb.GeneratedMessage {
  factory Report({
    $core.Iterable<Peer>? peers,
  }) {
    final result = create();
    if (peers != null) result.peers.addAll(peers);
    return result;
  }

  Report._();

  factory Report.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Report.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Report',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..pPM<Peer>(1, _omitFieldNames ? '' : 'peers', subBuilder: Peer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Report clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Report copyWith(void Function(Report) updates) =>
      super.copyWith((message) => updates(message as Report)) as Report;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Report create() => Report._();
  @$core.override
  Report createEmptyInstance() => create();
  static $pb.PbList<Report> createRepeated() => $pb.PbList<Report>();
  @$core.pragma('dart2js:noInline')
  static Report getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Report>(create);
  static Report? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Peer> get peers => $_getList(0);
}

enum NetworkPacket_Body {
  payload,
  msg,
  status,
  init,
  deviceSettings,
  scriptConfig,
  beacon,
  report,
  notSet
}

class NetworkPacket extends $pb.GeneratedMessage {
  factory NetworkPacket({
    $fixnum.Int64? from,
    $fixnum.Int64? to,
    Operation? operation,
    Interface? interface,
    $core.List<$core.int>? payload,
    MessageBody? msg,
    HaLowInterfaceStatus? status,
    HaLowInitConfig? init,
    DeviceSettings? deviceSettings,
    ScriptConfig? scriptConfig,
    Beacon? beacon,
    Report? report,
  }) {
    final result = create();
    if (from != null) result.from = from;
    if (to != null) result.to = to;
    if (operation != null) result.operation = operation;
    if (interface != null) result.interface = interface;
    if (payload != null) result.payload = payload;
    if (msg != null) result.msg = msg;
    if (status != null) result.status = status;
    if (init != null) result.init = init;
    if (deviceSettings != null) result.deviceSettings = deviceSettings;
    if (scriptConfig != null) result.scriptConfig = scriptConfig;
    if (beacon != null) result.beacon = beacon;
    if (report != null) result.report = report;
    return result;
  }

  NetworkPacket._();

  factory NetworkPacket.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NetworkPacket.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, NetworkPacket_Body>
      _NetworkPacket_BodyByTag = {
    100: NetworkPacket_Body.payload,
    101: NetworkPacket_Body.msg,
    102: NetworkPacket_Body.status,
    103: NetworkPacket_Body.init,
    104: NetworkPacket_Body.deviceSettings,
    105: NetworkPacket_Body.scriptConfig,
    106: NetworkPacket_Body.beacon,
    107: NetworkPacket_Body.report,
    0: NetworkPacket_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NetworkPacket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..oo(0, [100, 101, 102, 103, 104, 105, 106, 107])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'from', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'to', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<Operation>(3, _omitFieldNames ? '' : 'operation',
        enumValues: Operation.values)
    ..aE<Interface>(4, _omitFieldNames ? '' : 'interface',
        enumValues: Interface.values)
    ..a<$core.List<$core.int>>(
        100, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..aOM<MessageBody>(101, _omitFieldNames ? '' : 'msg',
        subBuilder: MessageBody.create)
    ..aOM<HaLowInterfaceStatus>(102, _omitFieldNames ? '' : 'status',
        subBuilder: HaLowInterfaceStatus.create)
    ..aOM<HaLowInitConfig>(103, _omitFieldNames ? '' : 'init',
        subBuilder: HaLowInitConfig.create)
    ..aOM<DeviceSettings>(104, _omitFieldNames ? '' : 'deviceSettings',
        subBuilder: DeviceSettings.create)
    ..aOM<ScriptConfig>(105, _omitFieldNames ? '' : 'scriptConfig',
        subBuilder: ScriptConfig.create)
    ..aOM<Beacon>(106, _omitFieldNames ? '' : 'beacon',
        subBuilder: Beacon.create)
    ..aOM<Report>(107, _omitFieldNames ? '' : 'report',
        subBuilder: Report.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkPacket clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkPacket copyWith(void Function(NetworkPacket) updates) =>
      super.copyWith((message) => updates(message as NetworkPacket))
          as NetworkPacket;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NetworkPacket create() => NetworkPacket._();
  @$core.override
  NetworkPacket createEmptyInstance() => create();
  static $pb.PbList<NetworkPacket> createRepeated() =>
      $pb.PbList<NetworkPacket>();
  @$core.pragma('dart2js:noInline')
  static NetworkPacket getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NetworkPacket>(create);
  static NetworkPacket? _defaultInstance;

  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  NetworkPacket_Body whichBody() => _NetworkPacket_BodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(100)
  @$pb.TagNumber(101)
  @$pb.TagNumber(102)
  @$pb.TagNumber(103)
  @$pb.TagNumber(104)
  @$pb.TagNumber(105)
  @$pb.TagNumber(106)
  @$pb.TagNumber(107)
  void clearBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get from => $_getI64(0);
  @$pb.TagNumber(1)
  set from($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFrom() => $_has(0);
  @$pb.TagNumber(1)
  void clearFrom() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get to => $_getI64(1);
  @$pb.TagNumber(2)
  set to($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTo() => $_has(1);
  @$pb.TagNumber(2)
  void clearTo() => $_clearField(2);

  @$pb.TagNumber(3)
  Operation get operation => $_getN(2);
  @$pb.TagNumber(3)
  set operation(Operation value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOperation() => $_has(2);
  @$pb.TagNumber(3)
  void clearOperation() => $_clearField(3);

  @$pb.TagNumber(4)
  Interface get interface => $_getN(3);
  @$pb.TagNumber(4)
  set interface(Interface value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasInterface() => $_has(3);
  @$pb.TagNumber(4)
  void clearInterface() => $_clearField(4);

  @$pb.TagNumber(100)
  $core.List<$core.int> get payload => $_getN(4);
  @$pb.TagNumber(100)
  set payload($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(100)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(100)
  void clearPayload() => $_clearField(100);

  @$pb.TagNumber(101)
  MessageBody get msg => $_getN(5);
  @$pb.TagNumber(101)
  set msg(MessageBody value) => $_setField(101, value);
  @$pb.TagNumber(101)
  $core.bool hasMsg() => $_has(5);
  @$pb.TagNumber(101)
  void clearMsg() => $_clearField(101);
  @$pb.TagNumber(101)
  MessageBody ensureMsg() => $_ensure(5);

  @$pb.TagNumber(102)
  HaLowInterfaceStatus get status => $_getN(6);
  @$pb.TagNumber(102)
  set status(HaLowInterfaceStatus value) => $_setField(102, value);
  @$pb.TagNumber(102)
  $core.bool hasStatus() => $_has(6);
  @$pb.TagNumber(102)
  void clearStatus() => $_clearField(102);
  @$pb.TagNumber(102)
  HaLowInterfaceStatus ensureStatus() => $_ensure(6);

  @$pb.TagNumber(103)
  HaLowInitConfig get init => $_getN(7);
  @$pb.TagNumber(103)
  set init(HaLowInitConfig value) => $_setField(103, value);
  @$pb.TagNumber(103)
  $core.bool hasInit() => $_has(7);
  @$pb.TagNumber(103)
  void clearInit() => $_clearField(103);
  @$pb.TagNumber(103)
  HaLowInitConfig ensureInit() => $_ensure(7);

  @$pb.TagNumber(104)
  DeviceSettings get deviceSettings => $_getN(8);
  @$pb.TagNumber(104)
  set deviceSettings(DeviceSettings value) => $_setField(104, value);
  @$pb.TagNumber(104)
  $core.bool hasDeviceSettings() => $_has(8);
  @$pb.TagNumber(104)
  void clearDeviceSettings() => $_clearField(104);
  @$pb.TagNumber(104)
  DeviceSettings ensureDeviceSettings() => $_ensure(8);

  @$pb.TagNumber(105)
  ScriptConfig get scriptConfig => $_getN(9);
  @$pb.TagNumber(105)
  set scriptConfig(ScriptConfig value) => $_setField(105, value);
  @$pb.TagNumber(105)
  $core.bool hasScriptConfig() => $_has(9);
  @$pb.TagNumber(105)
  void clearScriptConfig() => $_clearField(105);
  @$pb.TagNumber(105)
  ScriptConfig ensureScriptConfig() => $_ensure(9);

  @$pb.TagNumber(106)
  Beacon get beacon => $_getN(10);
  @$pb.TagNumber(106)
  set beacon(Beacon value) => $_setField(106, value);
  @$pb.TagNumber(106)
  $core.bool hasBeacon() => $_has(10);
  @$pb.TagNumber(106)
  void clearBeacon() => $_clearField(106);
  @$pb.TagNumber(106)
  Beacon ensureBeacon() => $_ensure(10);

  @$pb.TagNumber(107)
  Report get report => $_getN(11);
  @$pb.TagNumber(107)
  set report(Report value) => $_setField(107, value);
  @$pb.TagNumber(107)
  $core.bool hasReport() => $_has(11);
  @$pb.TagNumber(107)
  void clearReport() => $_clearField(107);
  @$pb.TagNumber(107)
  Report ensureReport() => $_ensure(11);
}

class GeoFence extends $pb.GeneratedMessage {
  factory GeoFence({
    $fixnum.Int64? idHigh,
    $fixnum.Int64? idLow,
    $core.String? name,
    MarkerColor? marker,
    AlertCondition? alertCondition,
    $core.int? geoIndex,
  }) {
    final result = create();
    if (idHigh != null) result.idHigh = idHigh;
    if (idLow != null) result.idLow = idLow;
    if (name != null) result.name = name;
    if (marker != null) result.marker = marker;
    if (alertCondition != null) result.alertCondition = alertCondition;
    if (geoIndex != null) result.geoIndex = geoIndex;
    return result;
  }

  GeoFence._();

  factory GeoFence.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GeoFence.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GeoFence',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'idHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'idLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aE<MarkerColor>(4, _omitFieldNames ? '' : 'marker',
        enumValues: MarkerColor.values)
    ..aE<AlertCondition>(5, _omitFieldNames ? '' : 'alertCondition',
        enumValues: AlertCondition.values)
    ..aI(6, _omitFieldNames ? '' : 'geoIndex', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoFence clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GeoFence copyWith(void Function(GeoFence) updates) =>
      super.copyWith((message) => updates(message as GeoFence)) as GeoFence;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GeoFence create() => GeoFence._();
  @$core.override
  GeoFence createEmptyInstance() => create();
  static $pb.PbList<GeoFence> createRepeated() => $pb.PbList<GeoFence>();
  @$core.pragma('dart2js:noInline')
  static GeoFence getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GeoFence>(create);
  static GeoFence? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get idHigh => $_getI64(0);
  @$pb.TagNumber(1)
  set idHigh($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIdHigh() => $_has(0);
  @$pb.TagNumber(1)
  void clearIdHigh() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get idLow => $_getI64(1);
  @$pb.TagNumber(2)
  set idLow($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIdLow() => $_has(1);
  @$pb.TagNumber(2)
  void clearIdLow() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  MarkerColor get marker => $_getN(3);
  @$pb.TagNumber(4)
  set marker(MarkerColor value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasMarker() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarker() => $_clearField(4);

  @$pb.TagNumber(5)
  AlertCondition get alertCondition => $_getN(4);
  @$pb.TagNumber(5)
  set alertCondition(AlertCondition value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAlertCondition() => $_has(4);
  @$pb.TagNumber(5)
  void clearAlertCondition() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get geoIndex => $_getIZ(5);
  @$pb.TagNumber(6)
  set geoIndex($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGeoIndex() => $_has(5);
  @$pb.TagNumber(6)
  void clearGeoIndex() => $_clearField(6);
}

enum SensorData_Value { boolValue, intValue, floatValue, notSet }

class SensorData extends $pb.GeneratedMessage {
  factory SensorData({
    SensorType? type,
    $core.bool? boolValue,
    $core.int? intValue,
    $core.double? floatValue,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (boolValue != null) result.boolValue = boolValue;
    if (intValue != null) result.intValue = intValue;
    if (floatValue != null) result.floatValue = floatValue;
    return result;
  }

  SensorData._();

  factory SensorData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SensorData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, SensorData_Value> _SensorData_ValueByTag = {
    2: SensorData_Value.boolValue,
    3: SensorData_Value.intValue,
    4: SensorData_Value.floatValue,
    0: SensorData_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SensorData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aE<SensorType>(1, _omitFieldNames ? '' : 'type',
        enumValues: SensorType.values)
    ..aOB(2, _omitFieldNames ? '' : 'boolValue')
    ..aI(3, _omitFieldNames ? '' : 'intValue', fieldType: $pb.PbFieldType.OS3)
    ..aD(4, _omitFieldNames ? '' : 'floatValue', fieldType: $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SensorData copyWith(void Function(SensorData) updates) =>
      super.copyWith((message) => updates(message as SensorData)) as SensorData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SensorData create() => SensorData._();
  @$core.override
  SensorData createEmptyInstance() => create();
  static $pb.PbList<SensorData> createRepeated() => $pb.PbList<SensorData>();
  @$core.pragma('dart2js:noInline')
  static SensorData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SensorData>(create);
  static SensorData? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  SensorData_Value whichValue() => _SensorData_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearValue() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SensorType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(SensorType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get boolValue => $_getBF(1);
  @$pb.TagNumber(2)
  set boolValue($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBoolValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearBoolValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get intValue => $_getIZ(2);
  @$pb.TagNumber(3)
  set intValue($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntValue() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get floatValue => $_getN(3);
  @$pb.TagNumber(4)
  set floatValue($core.double value) => $_setFloat(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFloatValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearFloatValue() => $_clearField(4);
}

class Peer extends $pb.GeneratedMessage {
  factory Peer({
    $fixnum.Int64? id,
    $core.int? rssi,
    $core.Iterable<SensorData>? sensorData,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (rssi != null) result.rssi = rssi;
    if (sensorData != null) result.sensorData.addAll(sensorData);
    return result;
  }

  Peer._();

  factory Peer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Peer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Peer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(2, _omitFieldNames ? '' : 'rssi', fieldType: $pb.PbFieldType.OS3)
    ..pPM<SensorData>(3, _omitFieldNames ? '' : 'sensorData',
        subBuilder: SensorData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Peer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Peer copyWith(void Function(Peer) updates) =>
      super.copyWith((message) => updates(message as Peer)) as Peer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Peer create() => Peer._();
  @$core.override
  Peer createEmptyInstance() => create();
  static $pb.PbList<Peer> createRepeated() => $pb.PbList<Peer>();
  @$core.pragma('dart2js:noInline')
  static Peer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Peer>(create);
  static Peer? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rssi => $_getIZ(1);
  @$pb.TagNumber(2)
  set rssi($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRssi() => $_has(1);
  @$pb.TagNumber(2)
  void clearRssi() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SensorData> get sensorData => $_getList(2);
}

class Beacon extends $pb.GeneratedMessage {
  factory Beacon({
    $fixnum.Int64? userIdHigh,
    $fixnum.Int64? userIdLow,
    $core.String? userName,
    $core.List<$core.int>? userPublicKey,
    $core.double? latitude,
    $core.double? longitude,
    MarkerColor? marker,
    DeviceType? deviceType,
    $core.bool? sleeping,
    GeoFence? geoFence,
    $core.Iterable<SensorData>? sensorData,
  }) {
    final result = create();
    if (userIdHigh != null) result.userIdHigh = userIdHigh;
    if (userIdLow != null) result.userIdLow = userIdLow;
    if (userName != null) result.userName = userName;
    if (userPublicKey != null) result.userPublicKey = userPublicKey;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (marker != null) result.marker = marker;
    if (deviceType != null) result.deviceType = deviceType;
    if (sleeping != null) result.sleeping = sleeping;
    if (geoFence != null) result.geoFence = geoFence;
    if (sensorData != null) result.sensorData.addAll(sensorData);
    return result;
  }

  Beacon._();

  factory Beacon.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Beacon.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Beacon',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'userIdHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'userIdLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'userName')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'userPublicKey', $pb.PbFieldType.OY)
    ..aD(5, _omitFieldNames ? '' : 'latitude', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'longitude', fieldType: $pb.PbFieldType.OF)
    ..aE<MarkerColor>(7, _omitFieldNames ? '' : 'marker',
        enumValues: MarkerColor.values)
    ..aE<DeviceType>(8, _omitFieldNames ? '' : 'deviceType',
        enumValues: DeviceType.values)
    ..aOB(10, _omitFieldNames ? '' : 'sleeping')
    ..aOM<GeoFence>(100, _omitFieldNames ? '' : 'geoFence',
        subBuilder: GeoFence.create)
    ..pPM<SensorData>(101, _omitFieldNames ? '' : 'sensorData',
        subBuilder: SensorData.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Beacon clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Beacon copyWith(void Function(Beacon) updates) =>
      super.copyWith((message) => updates(message as Beacon)) as Beacon;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Beacon create() => Beacon._();
  @$core.override
  Beacon createEmptyInstance() => create();
  static $pb.PbList<Beacon> createRepeated() => $pb.PbList<Beacon>();
  @$core.pragma('dart2js:noInline')
  static Beacon getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Beacon>(create);
  static Beacon? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userIdHigh => $_getI64(0);
  @$pb.TagNumber(1)
  set userIdHigh($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserIdHigh() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserIdHigh() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get userIdLow => $_getI64(1);
  @$pb.TagNumber(2)
  set userIdLow($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserIdLow() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserIdLow() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get userName => $_getSZ(2);
  @$pb.TagNumber(3)
  set userName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserName() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get userPublicKey => $_getN(3);
  @$pb.TagNumber(4)
  set userPublicKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserPublicKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get latitude => $_getN(4);
  @$pb.TagNumber(5)
  set latitude($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLatitude() => $_has(4);
  @$pb.TagNumber(5)
  void clearLatitude() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get longitude => $_getN(5);
  @$pb.TagNumber(6)
  set longitude($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLongitude() => $_has(5);
  @$pb.TagNumber(6)
  void clearLongitude() => $_clearField(6);

  @$pb.TagNumber(7)
  MarkerColor get marker => $_getN(6);
  @$pb.TagNumber(7)
  set marker(MarkerColor value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasMarker() => $_has(6);
  @$pb.TagNumber(7)
  void clearMarker() => $_clearField(7);

  @$pb.TagNumber(8)
  DeviceType get deviceType => $_getN(7);
  @$pb.TagNumber(8)
  set deviceType(DeviceType value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasDeviceType() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeviceType() => $_clearField(8);

  @$pb.TagNumber(10)
  $core.bool get sleeping => $_getBF(8);
  @$pb.TagNumber(10)
  set sleeping($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasSleeping() => $_has(8);
  @$pb.TagNumber(10)
  void clearSleeping() => $_clearField(10);

  @$pb.TagNumber(100)
  GeoFence get geoFence => $_getN(9);
  @$pb.TagNumber(100)
  set geoFence(GeoFence value) => $_setField(100, value);
  @$pb.TagNumber(100)
  $core.bool hasGeoFence() => $_has(9);
  @$pb.TagNumber(100)
  void clearGeoFence() => $_clearField(100);
  @$pb.TagNumber(100)
  GeoFence ensureGeoFence() => $_ensure(9);

  @$pb.TagNumber(101)
  $pb.PbList<SensorData> get sensorData => $_getList(10);
}

class HaLowInterfaceStatus extends $pb.GeneratedMessage {
  factory HaLowInterfaceStatus({
    $core.bool? supported,
    $core.bool? stackInitialized,
    $core.bool? meshMode,
    $core.bool? linkUp,
    $core.bool? routeReady,
    $core.bool? readyForReport,
    $core.int? ethertype,
    $core.String? meshId,
    $core.String? ipAddr,
    $core.String? gateway,
    $fixnum.Int64? macAddress,
    LicenseStatus? licenseStatus,
    $core.String? firmwareVersion,
  }) {
    final result = create();
    if (supported != null) result.supported = supported;
    if (stackInitialized != null) result.stackInitialized = stackInitialized;
    if (meshMode != null) result.meshMode = meshMode;
    if (linkUp != null) result.linkUp = linkUp;
    if (routeReady != null) result.routeReady = routeReady;
    if (readyForReport != null) result.readyForReport = readyForReport;
    if (ethertype != null) result.ethertype = ethertype;
    if (meshId != null) result.meshId = meshId;
    if (ipAddr != null) result.ipAddr = ipAddr;
    if (gateway != null) result.gateway = gateway;
    if (macAddress != null) result.macAddress = macAddress;
    if (licenseStatus != null) result.licenseStatus = licenseStatus;
    if (firmwareVersion != null) result.firmwareVersion = firmwareVersion;
    return result;
  }

  HaLowInterfaceStatus._();

  factory HaLowInterfaceStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HaLowInterfaceStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HaLowInterfaceStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'supported')
    ..aOB(2, _omitFieldNames ? '' : 'stackInitialized')
    ..aOB(3, _omitFieldNames ? '' : 'meshMode')
    ..aOB(4, _omitFieldNames ? '' : 'linkUp')
    ..aOB(5, _omitFieldNames ? '' : 'routeReady')
    ..aOB(6, _omitFieldNames ? '' : 'readyForReport')
    ..aI(7, _omitFieldNames ? '' : 'ethertype', fieldType: $pb.PbFieldType.OU3)
    ..aOS(8, _omitFieldNames ? '' : 'meshId')
    ..aOS(9, _omitFieldNames ? '' : 'ipAddr')
    ..aOS(10, _omitFieldNames ? '' : 'gateway')
    ..a<$fixnum.Int64>(
        11, _omitFieldNames ? '' : 'macAddress', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<LicenseStatus>(12, _omitFieldNames ? '' : 'licenseStatus',
        enumValues: LicenseStatus.values)
    ..aOS(13, _omitFieldNames ? '' : 'firmwareVersion')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HaLowInterfaceStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HaLowInterfaceStatus copyWith(void Function(HaLowInterfaceStatus) updates) =>
      super.copyWith((message) => updates(message as HaLowInterfaceStatus))
          as HaLowInterfaceStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HaLowInterfaceStatus create() => HaLowInterfaceStatus._();
  @$core.override
  HaLowInterfaceStatus createEmptyInstance() => create();
  static $pb.PbList<HaLowInterfaceStatus> createRepeated() =>
      $pb.PbList<HaLowInterfaceStatus>();
  @$core.pragma('dart2js:noInline')
  static HaLowInterfaceStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HaLowInterfaceStatus>(create);
  static HaLowInterfaceStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get supported => $_getBF(0);
  @$pb.TagNumber(1)
  set supported($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSupported() => $_has(0);
  @$pb.TagNumber(1)
  void clearSupported() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get stackInitialized => $_getBF(1);
  @$pb.TagNumber(2)
  set stackInitialized($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStackInitialized() => $_has(1);
  @$pb.TagNumber(2)
  void clearStackInitialized() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get meshMode => $_getBF(2);
  @$pb.TagNumber(3)
  set meshMode($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMeshMode() => $_has(2);
  @$pb.TagNumber(3)
  void clearMeshMode() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get linkUp => $_getBF(3);
  @$pb.TagNumber(4)
  set linkUp($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLinkUp() => $_has(3);
  @$pb.TagNumber(4)
  void clearLinkUp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get routeReady => $_getBF(4);
  @$pb.TagNumber(5)
  set routeReady($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRouteReady() => $_has(4);
  @$pb.TagNumber(5)
  void clearRouteReady() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get readyForReport => $_getBF(5);
  @$pb.TagNumber(6)
  set readyForReport($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReadyForReport() => $_has(5);
  @$pb.TagNumber(6)
  void clearReadyForReport() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get ethertype => $_getIZ(6);
  @$pb.TagNumber(7)
  set ethertype($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasEthertype() => $_has(6);
  @$pb.TagNumber(7)
  void clearEthertype() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get meshId => $_getSZ(7);
  @$pb.TagNumber(8)
  set meshId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasMeshId() => $_has(7);
  @$pb.TagNumber(8)
  void clearMeshId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get ipAddr => $_getSZ(8);
  @$pb.TagNumber(9)
  set ipAddr($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasIpAddr() => $_has(8);
  @$pb.TagNumber(9)
  void clearIpAddr() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get gateway => $_getSZ(9);
  @$pb.TagNumber(10)
  set gateway($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasGateway() => $_has(9);
  @$pb.TagNumber(10)
  void clearGateway() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get macAddress => $_getI64(10);
  @$pb.TagNumber(11)
  set macAddress($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMacAddress() => $_has(10);
  @$pb.TagNumber(11)
  void clearMacAddress() => $_clearField(11);

  @$pb.TagNumber(12)
  LicenseStatus get licenseStatus => $_getN(11);
  @$pb.TagNumber(12)
  set licenseStatus(LicenseStatus value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasLicenseStatus() => $_has(11);
  @$pb.TagNumber(12)
  void clearLicenseStatus() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get firmwareVersion => $_getSZ(12);
  @$pb.TagNumber(13)
  set firmwareVersion($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasFirmwareVersion() => $_has(12);
  @$pb.TagNumber(13)
  void clearFirmwareVersion() => $_clearField(13);
}

class HaLowInitConfig extends $pb.GeneratedMessage {
  factory HaLowInitConfig({
    $core.String? countryCode,
    $core.String? meshId,
    $core.String? passphrase,
    $core.int? maxHop,
    $fixnum.Int64? userIdHigh,
    $fixnum.Int64? userIdLow,
    $core.String? userName,
    $core.List<$core.int>? userPublicKey,
    $core.String? marker,
    $core.bool? hasLocation,
    $core.double? latitude,
    $core.double? longitude,
    $core.int? meshBandwidthMhz,
    $core.int? meshFrequencyKhz,
    $core.String? sdkCompatibility,
    $core.String? sdkReleaseId,
    $core.List<$core.int>? sdkReleaseSignature,
  }) {
    final result = create();
    if (countryCode != null) result.countryCode = countryCode;
    if (meshId != null) result.meshId = meshId;
    if (passphrase != null) result.passphrase = passphrase;
    if (maxHop != null) result.maxHop = maxHop;
    if (userIdHigh != null) result.userIdHigh = userIdHigh;
    if (userIdLow != null) result.userIdLow = userIdLow;
    if (userName != null) result.userName = userName;
    if (userPublicKey != null) result.userPublicKey = userPublicKey;
    if (marker != null) result.marker = marker;
    if (hasLocation != null) result.hasLocation = hasLocation;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (meshBandwidthMhz != null) result.meshBandwidthMhz = meshBandwidthMhz;
    if (meshFrequencyKhz != null) result.meshFrequencyKhz = meshFrequencyKhz;
    if (sdkCompatibility != null) result.sdkCompatibility = sdkCompatibility;
    if (sdkReleaseId != null) result.sdkReleaseId = sdkReleaseId;
    if (sdkReleaseSignature != null)
      result.sdkReleaseSignature = sdkReleaseSignature;
    return result;
  }

  HaLowInitConfig._();

  factory HaLowInitConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HaLowInitConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HaLowInitConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'countryCode')
    ..aOS(2, _omitFieldNames ? '' : 'meshId')
    ..aOS(3, _omitFieldNames ? '' : 'passphrase')
    ..aI(4, _omitFieldNames ? '' : 'maxHop', fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'userIdHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        6, _omitFieldNames ? '' : 'userIdLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(7, _omitFieldNames ? '' : 'userName')
    ..a<$core.List<$core.int>>(
        8, _omitFieldNames ? '' : 'userPublicKey', $pb.PbFieldType.OY)
    ..aOS(9, _omitFieldNames ? '' : 'marker')
    ..aOB(10, _omitFieldNames ? '' : 'hasLocation')
    ..aD(11, _omitFieldNames ? '' : 'latitude', fieldType: $pb.PbFieldType.OF)
    ..aD(12, _omitFieldNames ? '' : 'longitude', fieldType: $pb.PbFieldType.OF)
    ..aI(13, _omitFieldNames ? '' : 'meshBandwidthMhz',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(14, _omitFieldNames ? '' : 'meshFrequencyKhz',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(15, _omitFieldNames ? '' : 'sdkCompatibility')
    ..aOS(16, _omitFieldNames ? '' : 'sdkReleaseId')
    ..a<$core.List<$core.int>>(
        17, _omitFieldNames ? '' : 'sdkReleaseSignature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HaLowInitConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HaLowInitConfig copyWith(void Function(HaLowInitConfig) updates) =>
      super.copyWith((message) => updates(message as HaLowInitConfig))
          as HaLowInitConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HaLowInitConfig create() => HaLowInitConfig._();
  @$core.override
  HaLowInitConfig createEmptyInstance() => create();
  static $pb.PbList<HaLowInitConfig> createRepeated() =>
      $pb.PbList<HaLowInitConfig>();
  @$core.pragma('dart2js:noInline')
  static HaLowInitConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HaLowInitConfig>(create);
  static HaLowInitConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get countryCode => $_getSZ(0);
  @$pb.TagNumber(1)
  set countryCode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCountryCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCountryCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get meshId => $_getSZ(1);
  @$pb.TagNumber(2)
  set meshId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMeshId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMeshId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get passphrase => $_getSZ(2);
  @$pb.TagNumber(3)
  set passphrase($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassphrase() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassphrase() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxHop => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxHop($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxHop() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxHop() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get userIdHigh => $_getI64(4);
  @$pb.TagNumber(5)
  set userIdHigh($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUserIdHigh() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserIdHigh() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get userIdLow => $_getI64(5);
  @$pb.TagNumber(6)
  set userIdLow($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUserIdLow() => $_has(5);
  @$pb.TagNumber(6)
  void clearUserIdLow() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get userName => $_getSZ(6);
  @$pb.TagNumber(7)
  set userName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUserName() => $_has(6);
  @$pb.TagNumber(7)
  void clearUserName() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get userPublicKey => $_getN(7);
  @$pb.TagNumber(8)
  set userPublicKey($core.List<$core.int> value) => $_setBytes(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUserPublicKey() => $_has(7);
  @$pb.TagNumber(8)
  void clearUserPublicKey() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get marker => $_getSZ(8);
  @$pb.TagNumber(9)
  set marker($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasMarker() => $_has(8);
  @$pb.TagNumber(9)
  void clearMarker() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get hasLocation => $_getBF(9);
  @$pb.TagNumber(10)
  set hasLocation($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHasLocation() => $_has(9);
  @$pb.TagNumber(10)
  void clearHasLocation() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get latitude => $_getN(10);
  @$pb.TagNumber(11)
  set latitude($core.double value) => $_setFloat(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLatitude() => $_has(10);
  @$pb.TagNumber(11)
  void clearLatitude() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get longitude => $_getN(11);
  @$pb.TagNumber(12)
  set longitude($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLongitude() => $_has(11);
  @$pb.TagNumber(12)
  void clearLongitude() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get meshBandwidthMhz => $_getIZ(12);
  @$pb.TagNumber(13)
  set meshBandwidthMhz($core.int value) => $_setUnsignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMeshBandwidthMhz() => $_has(12);
  @$pb.TagNumber(13)
  void clearMeshBandwidthMhz() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get meshFrequencyKhz => $_getIZ(13);
  @$pb.TagNumber(14)
  set meshFrequencyKhz($core.int value) => $_setUnsignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMeshFrequencyKhz() => $_has(13);
  @$pb.TagNumber(14)
  void clearMeshFrequencyKhz() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get sdkCompatibility => $_getSZ(14);
  @$pb.TagNumber(15)
  set sdkCompatibility($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasSdkCompatibility() => $_has(14);
  @$pb.TagNumber(15)
  void clearSdkCompatibility() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get sdkReleaseId => $_getSZ(15);
  @$pb.TagNumber(16)
  set sdkReleaseId($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasSdkReleaseId() => $_has(15);
  @$pb.TagNumber(16)
  void clearSdkReleaseId() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.List<$core.int> get sdkReleaseSignature => $_getN(16);
  @$pb.TagNumber(17)
  set sdkReleaseSignature($core.List<$core.int> value) => $_setBytes(16, value);
  @$pb.TagNumber(17)
  $core.bool hasSdkReleaseSignature() => $_has(16);
  @$pb.TagNumber(17)
  void clearSdkReleaseSignature() => $_clearField(17);
}

class DeviceSettings extends $pb.GeneratedMessage {
  factory DeviceSettings({
    DeviceSettingsAction? action,
    $core.bool? deviceModeEnabled,
    $core.String? meshId,
    $core.bool? shareLocation,
    $core.String? userName,
    MarkerColor? marker,
    $core.int? beaconIntervalSeconds,
    $fixnum.Int64? userIdHigh,
    $fixnum.Int64? userIdLow,
    $core.List<$core.int>? userPublicKey,
    $core.List<$core.int>? userPrivateKey,
    $core.double? latitude,
    $core.double? longitude,
    $core.int? maxHop,
    GeoFence? geoFence,
    $core.String? uartI2cSensorType,
    $core.String? rs485SensorType,
    $core.int? geoIndex,
    $core.String? passphrase,
    $core.String? upstreamWifiSsid,
    $core.String? upstreamWifiPassphrase,
    $fixnum.Int64? beaconUnicast,
    DeviceType? deviceType,
    $core.bool? sleepModeEnabled,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (deviceModeEnabled != null) result.deviceModeEnabled = deviceModeEnabled;
    if (meshId != null) result.meshId = meshId;
    if (shareLocation != null) result.shareLocation = shareLocation;
    if (userName != null) result.userName = userName;
    if (marker != null) result.marker = marker;
    if (beaconIntervalSeconds != null)
      result.beaconIntervalSeconds = beaconIntervalSeconds;
    if (userIdHigh != null) result.userIdHigh = userIdHigh;
    if (userIdLow != null) result.userIdLow = userIdLow;
    if (userPublicKey != null) result.userPublicKey = userPublicKey;
    if (userPrivateKey != null) result.userPrivateKey = userPrivateKey;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (maxHop != null) result.maxHop = maxHop;
    if (geoFence != null) result.geoFence = geoFence;
    if (uartI2cSensorType != null) result.uartI2cSensorType = uartI2cSensorType;
    if (rs485SensorType != null) result.rs485SensorType = rs485SensorType;
    if (geoIndex != null) result.geoIndex = geoIndex;
    if (passphrase != null) result.passphrase = passphrase;
    if (upstreamWifiSsid != null) result.upstreamWifiSsid = upstreamWifiSsid;
    if (upstreamWifiPassphrase != null)
      result.upstreamWifiPassphrase = upstreamWifiPassphrase;
    if (beaconUnicast != null) result.beaconUnicast = beaconUnicast;
    if (deviceType != null) result.deviceType = deviceType;
    if (sleepModeEnabled != null) result.sleepModeEnabled = sleepModeEnabled;
    return result;
  }

  DeviceSettings._();

  factory DeviceSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeviceSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeviceSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..aE<DeviceSettingsAction>(1, _omitFieldNames ? '' : 'action',
        enumValues: DeviceSettingsAction.values)
    ..aOB(2, _omitFieldNames ? '' : 'deviceModeEnabled')
    ..aOS(3, _omitFieldNames ? '' : 'meshId')
    ..aOB(4, _omitFieldNames ? '' : 'shareLocation')
    ..aOS(5, _omitFieldNames ? '' : 'userName')
    ..aE<MarkerColor>(6, _omitFieldNames ? '' : 'marker',
        enumValues: MarkerColor.values)
    ..aI(7, _omitFieldNames ? '' : 'beaconIntervalSeconds',
        fieldType: $pb.PbFieldType.OU3)
    ..a<$fixnum.Int64>(
        8, _omitFieldNames ? '' : 'userIdHigh', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        9, _omitFieldNames ? '' : 'userIdLow', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        10, _omitFieldNames ? '' : 'userPublicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        11, _omitFieldNames ? '' : 'userPrivateKey', $pb.PbFieldType.OY)
    ..aD(12, _omitFieldNames ? '' : 'latitude', fieldType: $pb.PbFieldType.OF)
    ..aD(13, _omitFieldNames ? '' : 'longitude', fieldType: $pb.PbFieldType.OF)
    ..aI(14, _omitFieldNames ? '' : 'maxHop', fieldType: $pb.PbFieldType.OU3)
    ..aOM<GeoFence>(15, _omitFieldNames ? '' : 'geoFence',
        subBuilder: GeoFence.create)
    ..aOS(16, _omitFieldNames ? '' : 'uartI2cSensorType')
    ..aOS(17, _omitFieldNames ? '' : 'rs485SensorType')
    ..aI(18, _omitFieldNames ? '' : 'geoIndex', fieldType: $pb.PbFieldType.OU3)
    ..aOS(19, _omitFieldNames ? '' : 'passphrase')
    ..aOS(20, _omitFieldNames ? '' : 'upstreamWifiSsid')
    ..aOS(21, _omitFieldNames ? '' : 'upstreamWifiPassphrase')
    ..a<$fixnum.Int64>(
        22, _omitFieldNames ? '' : 'beaconUnicast', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<DeviceType>(24, _omitFieldNames ? '' : 'deviceType',
        enumValues: DeviceType.values)
    ..aOB(25, _omitFieldNames ? '' : 'sleepModeEnabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeviceSettings copyWith(void Function(DeviceSettings) updates) =>
      super.copyWith((message) => updates(message as DeviceSettings))
          as DeviceSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeviceSettings create() => DeviceSettings._();
  @$core.override
  DeviceSettings createEmptyInstance() => create();
  static $pb.PbList<DeviceSettings> createRepeated() =>
      $pb.PbList<DeviceSettings>();
  @$core.pragma('dart2js:noInline')
  static DeviceSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeviceSettings>(create);
  static DeviceSettings? _defaultInstance;

  @$pb.TagNumber(1)
  DeviceSettingsAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(DeviceSettingsAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get deviceModeEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set deviceModeEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceModeEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceModeEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get meshId => $_getSZ(2);
  @$pb.TagNumber(3)
  set meshId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMeshId() => $_has(2);
  @$pb.TagNumber(3)
  void clearMeshId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get shareLocation => $_getBF(3);
  @$pb.TagNumber(4)
  set shareLocation($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasShareLocation() => $_has(3);
  @$pb.TagNumber(4)
  void clearShareLocation() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get userName => $_getSZ(4);
  @$pb.TagNumber(5)
  set userName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUserName() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserName() => $_clearField(5);

  @$pb.TagNumber(6)
  MarkerColor get marker => $_getN(5);
  @$pb.TagNumber(6)
  set marker(MarkerColor value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasMarker() => $_has(5);
  @$pb.TagNumber(6)
  void clearMarker() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get beaconIntervalSeconds => $_getIZ(6);
  @$pb.TagNumber(7)
  set beaconIntervalSeconds($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBeaconIntervalSeconds() => $_has(6);
  @$pb.TagNumber(7)
  void clearBeaconIntervalSeconds() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get userIdHigh => $_getI64(7);
  @$pb.TagNumber(8)
  set userIdHigh($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUserIdHigh() => $_has(7);
  @$pb.TagNumber(8)
  void clearUserIdHigh() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get userIdLow => $_getI64(8);
  @$pb.TagNumber(9)
  set userIdLow($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasUserIdLow() => $_has(8);
  @$pb.TagNumber(9)
  void clearUserIdLow() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.int> get userPublicKey => $_getN(9);
  @$pb.TagNumber(10)
  set userPublicKey($core.List<$core.int> value) => $_setBytes(9, value);
  @$pb.TagNumber(10)
  $core.bool hasUserPublicKey() => $_has(9);
  @$pb.TagNumber(10)
  void clearUserPublicKey() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.int> get userPrivateKey => $_getN(10);
  @$pb.TagNumber(11)
  set userPrivateKey($core.List<$core.int> value) => $_setBytes(10, value);
  @$pb.TagNumber(11)
  $core.bool hasUserPrivateKey() => $_has(10);
  @$pb.TagNumber(11)
  void clearUserPrivateKey() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get latitude => $_getN(11);
  @$pb.TagNumber(12)
  set latitude($core.double value) => $_setFloat(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLatitude() => $_has(11);
  @$pb.TagNumber(12)
  void clearLatitude() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get longitude => $_getN(12);
  @$pb.TagNumber(13)
  set longitude($core.double value) => $_setFloat(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLongitude() => $_has(12);
  @$pb.TagNumber(13)
  void clearLongitude() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.int get maxHop => $_getIZ(13);
  @$pb.TagNumber(14)
  set maxHop($core.int value) => $_setUnsignedInt32(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMaxHop() => $_has(13);
  @$pb.TagNumber(14)
  void clearMaxHop() => $_clearField(14);

  @$pb.TagNumber(15)
  GeoFence get geoFence => $_getN(14);
  @$pb.TagNumber(15)
  set geoFence(GeoFence value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasGeoFence() => $_has(14);
  @$pb.TagNumber(15)
  void clearGeoFence() => $_clearField(15);
  @$pb.TagNumber(15)
  GeoFence ensureGeoFence() => $_ensure(14);

  @$pb.TagNumber(16)
  $core.String get uartI2cSensorType => $_getSZ(15);
  @$pb.TagNumber(16)
  set uartI2cSensorType($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasUartI2cSensorType() => $_has(15);
  @$pb.TagNumber(16)
  void clearUartI2cSensorType() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.String get rs485SensorType => $_getSZ(16);
  @$pb.TagNumber(17)
  set rs485SensorType($core.String value) => $_setString(16, value);
  @$pb.TagNumber(17)
  $core.bool hasRs485SensorType() => $_has(16);
  @$pb.TagNumber(17)
  void clearRs485SensorType() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.int get geoIndex => $_getIZ(17);
  @$pb.TagNumber(18)
  set geoIndex($core.int value) => $_setUnsignedInt32(17, value);
  @$pb.TagNumber(18)
  $core.bool hasGeoIndex() => $_has(17);
  @$pb.TagNumber(18)
  void clearGeoIndex() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get passphrase => $_getSZ(18);
  @$pb.TagNumber(19)
  set passphrase($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasPassphrase() => $_has(18);
  @$pb.TagNumber(19)
  void clearPassphrase() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get upstreamWifiSsid => $_getSZ(19);
  @$pb.TagNumber(20)
  set upstreamWifiSsid($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasUpstreamWifiSsid() => $_has(19);
  @$pb.TagNumber(20)
  void clearUpstreamWifiSsid() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.String get upstreamWifiPassphrase => $_getSZ(20);
  @$pb.TagNumber(21)
  set upstreamWifiPassphrase($core.String value) => $_setString(20, value);
  @$pb.TagNumber(21)
  $core.bool hasUpstreamWifiPassphrase() => $_has(20);
  @$pb.TagNumber(21)
  void clearUpstreamWifiPassphrase() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get beaconUnicast => $_getI64(21);
  @$pb.TagNumber(22)
  set beaconUnicast($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasBeaconUnicast() => $_has(21);
  @$pb.TagNumber(22)
  void clearBeaconUnicast() => $_clearField(22);

  @$pb.TagNumber(24)
  DeviceType get deviceType => $_getN(22);
  @$pb.TagNumber(24)
  set deviceType(DeviceType value) => $_setField(24, value);
  @$pb.TagNumber(24)
  $core.bool hasDeviceType() => $_has(22);
  @$pb.TagNumber(24)
  void clearDeviceType() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get sleepModeEnabled => $_getBF(23);
  @$pb.TagNumber(25)
  set sleepModeEnabled($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(25)
  $core.bool hasSleepModeEnabled() => $_has(23);
  @$pb.TagNumber(25)
  void clearSleepModeEnabled() => $_clearField(25);
}

class ScriptConfig extends $pb.GeneratedMessage {
  factory ScriptConfig({
    ScriptConfigAction? action,
    $core.int? scriptId,
    $core.String? name,
    $core.int? version,
    $core.int? totalSize,
    $core.int? offset,
    $core.List<$core.int>? chunk,
    $core.String? sensorType,
    $core.bool? selectUartI2c,
    $core.bool? selectRs485,
    $core.int? globalBufferSize,
    $core.String? mimeType,
  }) {
    final result = create();
    if (action != null) result.action = action;
    if (scriptId != null) result.scriptId = scriptId;
    if (name != null) result.name = name;
    if (version != null) result.version = version;
    if (totalSize != null) result.totalSize = totalSize;
    if (offset != null) result.offset = offset;
    if (chunk != null) result.chunk = chunk;
    if (sensorType != null) result.sensorType = sensorType;
    if (selectUartI2c != null) result.selectUartI2c = selectUartI2c;
    if (selectRs485 != null) result.selectRs485 = selectRs485;
    if (globalBufferSize != null) result.globalBufferSize = globalBufferSize;
    if (mimeType != null) result.mimeType = mimeType;
    return result;
  }

  ScriptConfig._();

  factory ScriptConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ScriptConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScriptConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'ai.edgez.halow'),
      createEmptyInstance: create)
    ..aE<ScriptConfigAction>(1, _omitFieldNames ? '' : 'action',
        enumValues: ScriptConfigAction.values)
    ..aI(2, _omitFieldNames ? '' : 'scriptId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aI(4, _omitFieldNames ? '' : 'version', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'totalSize', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'chunk', $pb.PbFieldType.OY)
    ..aOS(8, _omitFieldNames ? '' : 'sensorType')
    ..aOB(9, _omitFieldNames ? '' : 'selectUartI2c')
    ..aOB(10, _omitFieldNames ? '' : 'selectRs485')
    ..aI(11, _omitFieldNames ? '' : 'globalBufferSize',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(12, _omitFieldNames ? '' : 'mimeType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ScriptConfig copyWith(void Function(ScriptConfig) updates) =>
      super.copyWith((message) => updates(message as ScriptConfig))
          as ScriptConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScriptConfig create() => ScriptConfig._();
  @$core.override
  ScriptConfig createEmptyInstance() => create();
  static $pb.PbList<ScriptConfig> createRepeated() =>
      $pb.PbList<ScriptConfig>();
  @$core.pragma('dart2js:noInline')
  static ScriptConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScriptConfig>(create);
  static ScriptConfig? _defaultInstance;

  @$pb.TagNumber(1)
  ScriptConfigAction get action => $_getN(0);
  @$pb.TagNumber(1)
  set action(ScriptConfigAction value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get scriptId => $_getIZ(1);
  @$pb.TagNumber(2)
  set scriptId($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasScriptId() => $_has(1);
  @$pb.TagNumber(2)
  void clearScriptId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get version => $_getIZ(3);
  @$pb.TagNumber(4)
  set version($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearVersion() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get totalSize => $_getIZ(4);
  @$pb.TagNumber(5)
  set totalSize($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotalSize() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotalSize() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get offset => $_getIZ(5);
  @$pb.TagNumber(6)
  set offset($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOffset() => $_has(5);
  @$pb.TagNumber(6)
  void clearOffset() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get chunk => $_getN(6);
  @$pb.TagNumber(7)
  set chunk($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasChunk() => $_has(6);
  @$pb.TagNumber(7)
  void clearChunk() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get sensorType => $_getSZ(7);
  @$pb.TagNumber(8)
  set sensorType($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSensorType() => $_has(7);
  @$pb.TagNumber(8)
  void clearSensorType() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get selectUartI2c => $_getBF(8);
  @$pb.TagNumber(9)
  set selectUartI2c($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSelectUartI2c() => $_has(8);
  @$pb.TagNumber(9)
  void clearSelectUartI2c() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get selectRs485 => $_getBF(9);
  @$pb.TagNumber(10)
  set selectRs485($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSelectRs485() => $_has(9);
  @$pb.TagNumber(10)
  void clearSelectRs485() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get globalBufferSize => $_getIZ(10);
  @$pb.TagNumber(11)
  set globalBufferSize($core.int value) => $_setUnsignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasGlobalBufferSize() => $_has(10);
  @$pb.TagNumber(11)
  void clearGlobalBufferSize() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get mimeType => $_getSZ(11);
  @$pb.TagNumber(12)
  set mimeType($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasMimeType() => $_has(11);
  @$pb.TagNumber(12)
  void clearMimeType() => $_clearField(12);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
