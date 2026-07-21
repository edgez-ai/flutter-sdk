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

import 'package:protobuf/protobuf.dart' as $pb;

class Operation extends $pb.ProtobufEnum {
  static const Operation OPERATION_UNSPECIFIED =
      Operation._(0, _omitEnumNames ? '' : 'OPERATION_UNSPECIFIED');
  static const Operation REQUEST =
      Operation._(1, _omitEnumNames ? '' : 'REQUEST');
  static const Operation RESPONSE =
      Operation._(2, _omitEnumNames ? '' : 'RESPONSE');
  static const Operation ACKNOWLEDGE =
      Operation._(3, _omitEnumNames ? '' : 'ACKNOWLEDGE');
  static const Operation STREAMING =
      Operation._(4, _omitEnumNames ? '' : 'STREAMING');
  static const Operation BROADCAST =
      Operation._(9, _omitEnumNames ? '' : 'BROADCAST');

  static const $core.List<Operation> values = <Operation>[
    OPERATION_UNSPECIFIED,
    REQUEST,
    RESPONSE,
    ACKNOWLEDGE,
    STREAMING,
    BROADCAST,
  ];

  static final $core.Map<$core.int, Operation> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static Operation? valueOf($core.int value) => _byValue[value];

  const Operation._(super.value, super.name);
}

class Interface extends $pb.ProtobufEnum {
  static const Interface INTERFACE_UNSPECIFIED =
      Interface._(0, _omitEnumNames ? '' : 'INTERFACE_UNSPECIFIED');
  static const Interface USB = Interface._(1, _omitEnumNames ? '' : 'USB');
  static const Interface BLE = Interface._(2, _omitEnumNames ? '' : 'BLE');
  static const Interface WIFI = Interface._(3, _omitEnumNames ? '' : 'WIFI');
  static const Interface ETHERNET =
      Interface._(4, _omitEnumNames ? '' : 'ETHERNET');
  static const Interface HALOW = Interface._(5, _omitEnumNames ? '' : 'HALOW');
  static const Interface LORA = Interface._(6, _omitEnumNames ? '' : 'LORA');
  static const Interface LIBP2P =
      Interface._(7, _omitEnumNames ? '' : 'LIBP2P');

  static const $core.List<Interface> values = <Interface>[
    INTERFACE_UNSPECIFIED,
    USB,
    BLE,
    WIFI,
    ETHERNET,
    HALOW,
    LORA,
    LIBP2P,
  ];

  static final $core.List<Interface?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static Interface? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Interface._(super.value, super.name);
}

class Mime extends $pb.ProtobufEnum {
  static const Mime MIME_UNSPECIFIED =
      Mime._(0, _omitEnumNames ? '' : 'MIME_UNSPECIFIED');
  static const Mime MIME_TEXT = Mime._(1, _omitEnumNames ? '' : 'MIME_TEXT');
  static const Mime MIME_VOICE = Mime._(2, _omitEnumNames ? '' : 'MIME_VOICE');
  static const Mime MIME_IMAGE = Mime._(3, _omitEnumNames ? '' : 'MIME_IMAGE');
  static const Mime MIME_VIDEO = Mime._(4, _omitEnumNames ? '' : 'MIME_VIDEO');
  static const Mime MIME_BINARY =
      Mime._(5, _omitEnumNames ? '' : 'MIME_BINARY');
  static const Mime MIME_VOICE_CALL =
      Mime._(6, _omitEnumNames ? '' : 'MIME_VOICE_CALL');

  static const $core.List<Mime> values = <Mime>[
    MIME_UNSPECIFIED,
    MIME_TEXT,
    MIME_VOICE,
    MIME_IMAGE,
    MIME_VIDEO,
    MIME_BINARY,
    MIME_VOICE_CALL,
  ];

  static final $core.List<Mime?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static Mime? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Mime._(super.value, super.name);
}

class MarkerColor extends $pb.ProtobufEnum {
  static const MarkerColor MARKER_DEFAULT =
      MarkerColor._(0, _omitEnumNames ? '' : 'MARKER_DEFAULT');
  static const MarkerColor MARKER_RED =
      MarkerColor._(1, _omitEnumNames ? '' : 'MARKER_RED');
  static const MarkerColor MARKER_BLUE =
      MarkerColor._(2, _omitEnumNames ? '' : 'MARKER_BLUE');
  static const MarkerColor MARKER_PURPLE =
      MarkerColor._(3, _omitEnumNames ? '' : 'MARKER_PURPLE');
  static const MarkerColor MARKER_YELLOW =
      MarkerColor._(4, _omitEnumNames ? '' : 'MARKER_YELLOW');
  static const MarkerColor MARKER_PINK =
      MarkerColor._(5, _omitEnumNames ? '' : 'MARKER_PINK');
  static const MarkerColor MARKER_BROWN =
      MarkerColor._(6, _omitEnumNames ? '' : 'MARKER_BROWN');
  static const MarkerColor MARKER_GREEN =
      MarkerColor._(7, _omitEnumNames ? '' : 'MARKER_GREEN');
  static const MarkerColor MARKER_ORANGE =
      MarkerColor._(8, _omitEnumNames ? '' : 'MARKER_ORANGE');
  static const MarkerColor MARKER_DEEP_PURPLE =
      MarkerColor._(9, _omitEnumNames ? '' : 'MARKER_DEEP_PURPLE');
  static const MarkerColor MARKER_LIGHT_BLUE =
      MarkerColor._(10, _omitEnumNames ? '' : 'MARKER_LIGHT_BLUE');
  static const MarkerColor MARKER_CYAN =
      MarkerColor._(11, _omitEnumNames ? '' : 'MARKER_CYAN');
  static const MarkerColor MARKER_TEAL =
      MarkerColor._(12, _omitEnumNames ? '' : 'MARKER_TEAL');
  static const MarkerColor MARKER_LIME =
      MarkerColor._(13, _omitEnumNames ? '' : 'MARKER_LIME');
  static const MarkerColor MARKER_DEEP_ORANGE =
      MarkerColor._(14, _omitEnumNames ? '' : 'MARKER_DEEP_ORANGE');
  static const MarkerColor MARKER_GRAY =
      MarkerColor._(15, _omitEnumNames ? '' : 'MARKER_GRAY');
  static const MarkerColor MARKER_BLUE_GRAY =
      MarkerColor._(16, _omitEnumNames ? '' : 'MARKER_BLUE_GRAY');

  static const $core.List<MarkerColor> values = <MarkerColor>[
    MARKER_DEFAULT,
    MARKER_RED,
    MARKER_BLUE,
    MARKER_PURPLE,
    MARKER_YELLOW,
    MARKER_PINK,
    MARKER_BROWN,
    MARKER_GREEN,
    MARKER_ORANGE,
    MARKER_DEEP_PURPLE,
    MARKER_LIGHT_BLUE,
    MARKER_CYAN,
    MARKER_TEAL,
    MARKER_LIME,
    MARKER_DEEP_ORANGE,
    MARKER_GRAY,
    MARKER_BLUE_GRAY,
  ];

  static final $core.List<MarkerColor?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 16);
  static MarkerColor? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MarkerColor._(super.value, super.name);
}

class DeviceSettingsAction extends $pb.ProtobufEnum {
  static const DeviceSettingsAction DEVICE_SETTINGS_ACTION_UNSPECIFIED =
      DeviceSettingsAction._(
          0, _omitEnumNames ? '' : 'DEVICE_SETTINGS_ACTION_UNSPECIFIED');
  static const DeviceSettingsAction DEVICE_SETTINGS_GET =
      DeviceSettingsAction._(1, _omitEnumNames ? '' : 'DEVICE_SETTINGS_GET');
  static const DeviceSettingsAction DEVICE_SETTINGS_SET =
      DeviceSettingsAction._(2, _omitEnumNames ? '' : 'DEVICE_SETTINGS_SET');
  static const DeviceSettingsAction DEVICE_SETTINGS_REPORT =
      DeviceSettingsAction._(3, _omitEnumNames ? '' : 'DEVICE_SETTINGS_REPORT');

  static const $core.List<DeviceSettingsAction> values = <DeviceSettingsAction>[
    DEVICE_SETTINGS_ACTION_UNSPECIFIED,
    DEVICE_SETTINGS_GET,
    DEVICE_SETTINGS_SET,
    DEVICE_SETTINGS_REPORT,
  ];

  static final $core.List<DeviceSettingsAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static DeviceSettingsAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DeviceSettingsAction._(super.value, super.name);
}

class ScriptConfigAction extends $pb.ProtobufEnum {
  static const ScriptConfigAction SCRIPT_CONFIG_ACTION_UNSPECIFIED =
      ScriptConfigAction._(
          0, _omitEnumNames ? '' : 'SCRIPT_CONFIG_ACTION_UNSPECIFIED');
  static const ScriptConfigAction SCRIPT_CONFIG_BEGIN =
      ScriptConfigAction._(1, _omitEnumNames ? '' : 'SCRIPT_CONFIG_BEGIN');
  static const ScriptConfigAction SCRIPT_CONFIG_CHUNK =
      ScriptConfigAction._(2, _omitEnumNames ? '' : 'SCRIPT_CONFIG_CHUNK');
  static const ScriptConfigAction SCRIPT_CONFIG_COMMIT =
      ScriptConfigAction._(3, _omitEnumNames ? '' : 'SCRIPT_CONFIG_COMMIT');
  static const ScriptConfigAction SCRIPT_CONFIG_DELETE =
      ScriptConfigAction._(4, _omitEnumNames ? '' : 'SCRIPT_CONFIG_DELETE');
  static const ScriptConfigAction SCRIPT_CONFIG_REPORT =
      ScriptConfigAction._(5, _omitEnumNames ? '' : 'SCRIPT_CONFIG_REPORT');

  static const $core.List<ScriptConfigAction> values = <ScriptConfigAction>[
    SCRIPT_CONFIG_ACTION_UNSPECIFIED,
    SCRIPT_CONFIG_BEGIN,
    SCRIPT_CONFIG_CHUNK,
    SCRIPT_CONFIG_COMMIT,
    SCRIPT_CONFIG_DELETE,
    SCRIPT_CONFIG_REPORT,
  ];

  static final $core.List<ScriptConfigAction?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ScriptConfigAction? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ScriptConfigAction._(super.value, super.name);
}

class LicenseStatus extends $pb.ProtobufEnum {
  static const LicenseStatus LICENSE_STATUS_UNSPECIFIED =
      LicenseStatus._(0, _omitEnumNames ? '' : 'LICENSE_STATUS_UNSPECIFIED');
  static const LicenseStatus LICENSE_STATUS_AUTHORIZED =
      LicenseStatus._(1, _omitEnumNames ? '' : 'LICENSE_STATUS_AUTHORIZED');
  static const LicenseStatus LICENSE_STATUS_DEVICE_NOT_LICENSED =
      LicenseStatus._(
          2, _omitEnumNames ? '' : 'LICENSE_STATUS_DEVICE_NOT_LICENSED');
  static const LicenseStatus LICENSE_STATUS_SDK_RELEASE_REQUIRED =
      LicenseStatus._(
          3, _omitEnumNames ? '' : 'LICENSE_STATUS_SDK_RELEASE_REQUIRED');
  static const LicenseStatus LICENSE_STATUS_SDK_VERSION_INCOMPATIBLE =
      LicenseStatus._(
          4, _omitEnumNames ? '' : 'LICENSE_STATUS_SDK_VERSION_INCOMPATIBLE');
  static const LicenseStatus LICENSE_STATUS_SDK_RELEASE_INVALID =
      LicenseStatus._(
          5, _omitEnumNames ? '' : 'LICENSE_STATUS_SDK_RELEASE_INVALID');

  static const $core.List<LicenseStatus> values = <LicenseStatus>[
    LICENSE_STATUS_UNSPECIFIED,
    LICENSE_STATUS_AUTHORIZED,
    LICENSE_STATUS_DEVICE_NOT_LICENSED,
    LICENSE_STATUS_SDK_RELEASE_REQUIRED,
    LICENSE_STATUS_SDK_VERSION_INCOMPATIBLE,
    LICENSE_STATUS_SDK_RELEASE_INVALID,
  ];

  static final $core.List<LicenseStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static LicenseStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LicenseStatus._(super.value, super.name);
}

class DeviceType extends $pb.ProtobufEnum {
  static const DeviceType DEVICE_TYPE_UNSPECIFIED =
      DeviceType._(0, _omitEnumNames ? '' : 'DEVICE_TYPE_UNSPECIFIED');
  static const DeviceType DEVICE_TYPE_UNKNOWN =
      DeviceType._(1, _omitEnumNames ? '' : 'DEVICE_TYPE_UNKNOWN');
  static const DeviceType DEVICE_TYPE_USER =
      DeviceType._(2, _omitEnumNames ? '' : 'DEVICE_TYPE_USER');
  static const DeviceType DEVICE_TYPE_GATEWAY =
      DeviceType._(3, _omitEnumNames ? '' : 'DEVICE_TYPE_GATEWAY');
  static const DeviceType DEVICE_TYPE_BEACON =
      DeviceType._(4, _omitEnumNames ? '' : 'DEVICE_TYPE_BEACON');
  static const DeviceType DEVICE_TYPE_SENSOR =
      DeviceType._(5, _omitEnumNames ? '' : 'DEVICE_TYPE_SENSOR');
  static const DeviceType DEVICE_TYPE_RELAY =
      DeviceType._(6, _omitEnumNames ? '' : 'DEVICE_TYPE_RELAY');

  static const $core.List<DeviceType> values = <DeviceType>[
    DEVICE_TYPE_UNSPECIFIED,
    DEVICE_TYPE_UNKNOWN,
    DEVICE_TYPE_USER,
    DEVICE_TYPE_GATEWAY,
    DEVICE_TYPE_BEACON,
    DEVICE_TYPE_SENSOR,
    DEVICE_TYPE_RELAY,
  ];

  static final $core.List<DeviceType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static DeviceType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DeviceType._(super.value, super.name);
}

class AlertCondition extends $pb.ProtobufEnum {
  static const AlertCondition ALERT_CONDITION_UNSPECIFIED =
      AlertCondition._(0, _omitEnumNames ? '' : 'ALERT_CONDITION_UNSPECIFIED');
  static const AlertCondition ALERT_CONDITION_ENTER =
      AlertCondition._(1, _omitEnumNames ? '' : 'ALERT_CONDITION_ENTER');
  static const AlertCondition ALERT_CONDITION_EXIT =
      AlertCondition._(2, _omitEnumNames ? '' : 'ALERT_CONDITION_EXIT');
  static const AlertCondition ALERT_CONDITION_NEAR =
      AlertCondition._(3, _omitEnumNames ? '' : 'ALERT_CONDITION_NEAR');
  static const AlertCondition ALERT_CONDITION_FAR =
      AlertCondition._(4, _omitEnumNames ? '' : 'ALERT_CONDITION_FAR');
  static const AlertCondition ALERT_CONDITION_LOW_BATTERY =
      AlertCondition._(5, _omitEnumNames ? '' : 'ALERT_CONDITION_LOW_BATTERY');

  static const $core.List<AlertCondition> values = <AlertCondition>[
    ALERT_CONDITION_UNSPECIFIED,
    ALERT_CONDITION_ENTER,
    ALERT_CONDITION_EXIT,
    ALERT_CONDITION_NEAR,
    ALERT_CONDITION_FAR,
    ALERT_CONDITION_LOW_BATTERY,
  ];

  static final $core.List<AlertCondition?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static AlertCondition? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AlertCondition._(super.value, super.name);
}

class SensorType extends $pb.ProtobufEnum {
  static const SensorType SENSOR_UNKNOWN =
      SensorType._(0, _omitEnumNames ? '' : 'SENSOR_UNKNOWN');
  static const SensorType SENSOR_TEMPERATURE =
      SensorType._(1, _omitEnumNames ? '' : 'SENSOR_TEMPERATURE');
  static const SensorType SENSOR_HUMIDITY =
      SensorType._(2, _omitEnumNames ? '' : 'SENSOR_HUMIDITY');
  static const SensorType SENSOR_LATITUDE =
      SensorType._(3, _omitEnumNames ? '' : 'SENSOR_LATITUDE');
  static const SensorType SENSOR_LONGITUDE =
      SensorType._(4, _omitEnumNames ? '' : 'SENSOR_LONGITUDE');
  static const SensorType SENSOR_LENGTH =
      SensorType._(5, _omitEnumNames ? '' : 'SENSOR_LENGTH');
  static const SensorType SENSOR_ACCEL_X =
      SensorType._(6, _omitEnumNames ? '' : 'SENSOR_ACCEL_X');
  static const SensorType SENSOR_ACCEL_Y =
      SensorType._(7, _omitEnumNames ? '' : 'SENSOR_ACCEL_Y');
  static const SensorType SENSOR_ACCEL_Z =
      SensorType._(8, _omitEnumNames ? '' : 'SENSOR_ACCEL_Z');
  static const SensorType SENSOR_GYRO_X =
      SensorType._(9, _omitEnumNames ? '' : 'SENSOR_GYRO_X');
  static const SensorType SENSOR_GYRO_Y =
      SensorType._(10, _omitEnumNames ? '' : 'SENSOR_GYRO_Y');
  static const SensorType SENSOR_GYRO_Z =
      SensorType._(11, _omitEnumNames ? '' : 'SENSOR_GYRO_Z');

  static const $core.List<SensorType> values = <SensorType>[
    SENSOR_UNKNOWN,
    SENSOR_TEMPERATURE,
    SENSOR_HUMIDITY,
    SENSOR_LATITUDE,
    SENSOR_LONGITUDE,
    SENSOR_LENGTH,
    SENSOR_ACCEL_X,
    SENSOR_ACCEL_Y,
    SENSOR_ACCEL_Z,
    SENSOR_GYRO_X,
    SENSOR_GYRO_Y,
    SENSOR_GYRO_Z,
  ];

  static final $core.List<SensorType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 11);
  static SensorType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SensorType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
