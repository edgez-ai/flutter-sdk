// This is a generated file - do not edit.
//
// Generated from edgez_mesh.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use operationDescriptor instead')
const Operation$json = {
  '1': 'Operation',
  '2': [
    {'1': 'OPERATION_UNSPECIFIED', '2': 0},
    {'1': 'REQUEST', '2': 1},
    {'1': 'RESPONSE', '2': 2},
    {'1': 'ACKNOWLEDGE', '2': 3},
    {'1': 'STREAMING', '2': 4},
    {'1': 'BROADCAST', '2': 9},
  ],
};

/// Descriptor for `Operation`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List operationDescriptor = $convert.base64Decode(
    'CglPcGVyYXRpb24SGQoVT1BFUkFUSU9OX1VOU1BFQ0lGSUVEEAASCwoHUkVRVUVTVBABEgwKCF'
    'JFU1BPTlNFEAISDwoLQUNLTk9XTEVER0UQAxINCglTVFJFQU1JTkcQBBINCglCUk9BRENBU1QQ'
    'CQ==');

@$core.Deprecated('Use interfaceDescriptor instead')
const Interface$json = {
  '1': 'Interface',
  '2': [
    {'1': 'INTERFACE_UNSPECIFIED', '2': 0},
    {'1': 'USB', '2': 1},
    {'1': 'BLE', '2': 2},
    {'1': 'WIFI', '2': 3},
    {'1': 'ETHERNET', '2': 4},
    {'1': 'HALOW', '2': 5},
    {'1': 'LORA', '2': 6},
    {'1': 'LIBP2P', '2': 7},
  ],
};

/// Descriptor for `Interface`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List interfaceDescriptor = $convert.base64Decode(
    'CglJbnRlcmZhY2USGQoVSU5URVJGQUNFX1VOU1BFQ0lGSUVEEAASBwoDVVNCEAESBwoDQkxFEA'
    'ISCAoEV0lGSRADEgwKCEVUSEVSTkVUEAQSCQoFSEFMT1cQBRIICgRMT1JBEAYSCgoGTElCUDJQ'
    'EAc=');

@$core.Deprecated('Use mimeDescriptor instead')
const Mime$json = {
  '1': 'Mime',
  '2': [
    {'1': 'MIME_UNSPECIFIED', '2': 0},
    {'1': 'MIME_TEXT', '2': 1},
    {'1': 'MIME_VOICE', '2': 2},
    {'1': 'MIME_IMAGE', '2': 3},
    {'1': 'MIME_VIDEO', '2': 4},
    {'1': 'MIME_BINARY', '2': 5},
    {'1': 'MIME_VOICE_CALL', '2': 6},
  ],
};

/// Descriptor for `Mime`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mimeDescriptor = $convert.base64Decode(
    'CgRNaW1lEhQKEE1JTUVfVU5TUEVDSUZJRUQQABINCglNSU1FX1RFWFQQARIOCgpNSU1FX1ZPSU'
    'NFEAISDgoKTUlNRV9JTUFHRRADEg4KCk1JTUVfVklERU8QBBIPCgtNSU1FX0JJTkFSWRAFEhMK'
    'D01JTUVfVk9JQ0VfQ0FMTBAG');

@$core.Deprecated('Use markerColorDescriptor instead')
const MarkerColor$json = {
  '1': 'MarkerColor',
  '2': [
    {'1': 'MARKER_DEFAULT', '2': 0},
    {'1': 'MARKER_RED', '2': 1},
    {'1': 'MARKER_BLUE', '2': 2},
    {'1': 'MARKER_PURPLE', '2': 3},
    {'1': 'MARKER_YELLOW', '2': 4},
    {'1': 'MARKER_PINK', '2': 5},
    {'1': 'MARKER_BROWN', '2': 6},
    {'1': 'MARKER_GREEN', '2': 7},
    {'1': 'MARKER_ORANGE', '2': 8},
    {'1': 'MARKER_DEEP_PURPLE', '2': 9},
    {'1': 'MARKER_LIGHT_BLUE', '2': 10},
    {'1': 'MARKER_CYAN', '2': 11},
    {'1': 'MARKER_TEAL', '2': 12},
    {'1': 'MARKER_LIME', '2': 13},
    {'1': 'MARKER_DEEP_ORANGE', '2': 14},
    {'1': 'MARKER_GRAY', '2': 15},
    {'1': 'MARKER_BLUE_GRAY', '2': 16},
  ],
};

/// Descriptor for `MarkerColor`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List markerColorDescriptor = $convert.base64Decode(
    'CgtNYXJrZXJDb2xvchISCg5NQVJLRVJfREVGQVVMVBAAEg4KCk1BUktFUl9SRUQQARIPCgtNQV'
    'JLRVJfQkxVRRACEhEKDU1BUktFUl9QVVJQTEUQAxIRCg1NQVJLRVJfWUVMTE9XEAQSDwoLTUFS'
    'S0VSX1BJTksQBRIQCgxNQVJLRVJfQlJPV04QBhIQCgxNQVJLRVJfR1JFRU4QBxIRCg1NQVJLRV'
    'JfT1JBTkdFEAgSFgoSTUFSS0VSX0RFRVBfUFVSUExFEAkSFQoRTUFSS0VSX0xJR0hUX0JMVUUQ'
    'ChIPCgtNQVJLRVJfQ1lBThALEg8KC01BUktFUl9URUFMEAwSDwoLTUFSS0VSX0xJTUUQDRIWCh'
    'JNQVJLRVJfREVFUF9PUkFOR0UQDhIPCgtNQVJLRVJfR1JBWRAPEhQKEE1BUktFUl9CTFVFX0dS'
    'QVkQEA==');

@$core.Deprecated('Use deviceSettingsActionDescriptor instead')
const DeviceSettingsAction$json = {
  '1': 'DeviceSettingsAction',
  '2': [
    {'1': 'DEVICE_SETTINGS_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'DEVICE_SETTINGS_GET', '2': 1},
    {'1': 'DEVICE_SETTINGS_SET', '2': 2},
    {'1': 'DEVICE_SETTINGS_REPORT', '2': 3},
  ],
};

/// Descriptor for `DeviceSettingsAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deviceSettingsActionDescriptor = $convert.base64Decode(
    'ChREZXZpY2VTZXR0aW5nc0FjdGlvbhImCiJERVZJQ0VfU0VUVElOR1NfQUNUSU9OX1VOU1BFQ0'
    'lGSUVEEAASFwoTREVWSUNFX1NFVFRJTkdTX0dFVBABEhcKE0RFVklDRV9TRVRUSU5HU19TRVQQ'
    'AhIaChZERVZJQ0VfU0VUVElOR1NfUkVQT1JUEAM=');

@$core.Deprecated('Use scriptConfigActionDescriptor instead')
const ScriptConfigAction$json = {
  '1': 'ScriptConfigAction',
  '2': [
    {'1': 'SCRIPT_CONFIG_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'SCRIPT_CONFIG_BEGIN', '2': 1},
    {'1': 'SCRIPT_CONFIG_CHUNK', '2': 2},
    {'1': 'SCRIPT_CONFIG_COMMIT', '2': 3},
    {'1': 'SCRIPT_CONFIG_DELETE', '2': 4},
    {'1': 'SCRIPT_CONFIG_REPORT', '2': 5},
  ],
};

/// Descriptor for `ScriptConfigAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List scriptConfigActionDescriptor = $convert.base64Decode(
    'ChJTY3JpcHRDb25maWdBY3Rpb24SJAogU0NSSVBUX0NPTkZJR19BQ1RJT05fVU5TUEVDSUZJRU'
    'QQABIXChNTQ1JJUFRfQ09ORklHX0JFR0lOEAESFwoTU0NSSVBUX0NPTkZJR19DSFVOSxACEhgK'
    'FFNDUklQVF9DT05GSUdfQ09NTUlUEAMSGAoUU0NSSVBUX0NPTkZJR19ERUxFVEUQBBIYChRTQ1'
    'JJUFRfQ09ORklHX1JFUE9SVBAF');

@$core.Deprecated('Use licenseStatusDescriptor instead')
const LicenseStatus$json = {
  '1': 'LicenseStatus',
  '2': [
    {'1': 'LICENSE_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'LICENSE_STATUS_AUTHORIZED', '2': 1},
    {'1': 'LICENSE_STATUS_DEVICE_NOT_LICENSED', '2': 2},
    {'1': 'LICENSE_STATUS_SDK_RELEASE_REQUIRED', '2': 3},
    {'1': 'LICENSE_STATUS_SDK_VERSION_INCOMPATIBLE', '2': 4},
    {'1': 'LICENSE_STATUS_SDK_RELEASE_INVALID', '2': 5},
  ],
};

/// Descriptor for `LicenseStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List licenseStatusDescriptor = $convert.base64Decode(
    'Cg1MaWNlbnNlU3RhdHVzEh4KGkxJQ0VOU0VfU1RBVFVTX1VOU1BFQ0lGSUVEEAASHQoZTElDRU'
    '5TRV9TVEFUVVNfQVVUSE9SSVpFRBABEiYKIkxJQ0VOU0VfU1RBVFVTX0RFVklDRV9OT1RfTElD'
    'RU5TRUQQAhInCiNMSUNFTlNFX1NUQVRVU19TREtfUkVMRUFTRV9SRVFVSVJFRBADEisKJ0xJQ0'
    'VOU0VfU1RBVFVTX1NES19WRVJTSU9OX0lOQ09NUEFUSUJMRRAEEiYKIkxJQ0VOU0VfU1RBVFVT'
    'X1NES19SRUxFQVNFX0lOVkFMSUQQBQ==');

@$core.Deprecated('Use deviceTypeDescriptor instead')
const DeviceType$json = {
  '1': 'DeviceType',
  '2': [
    {'1': 'DEVICE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'DEVICE_TYPE_UNKNOWN', '2': 1},
    {'1': 'DEVICE_TYPE_USER', '2': 2},
    {'1': 'DEVICE_TYPE_GATEWAY', '2': 3},
    {'1': 'DEVICE_TYPE_BEACON', '2': 4},
    {'1': 'DEVICE_TYPE_SENSOR', '2': 5},
    {'1': 'DEVICE_TYPE_RELAY', '2': 6},
  ],
};

/// Descriptor for `DeviceType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List deviceTypeDescriptor = $convert.base64Decode(
    'CgpEZXZpY2VUeXBlEhsKF0RFVklDRV9UWVBFX1VOU1BFQ0lGSUVEEAASFwoTREVWSUNFX1RZUE'
    'VfVU5LTk9XThABEhQKEERFVklDRV9UWVBFX1VTRVIQAhIXChNERVZJQ0VfVFlQRV9HQVRFV0FZ'
    'EAMSFgoSREVWSUNFX1RZUEVfQkVBQ09OEAQSFgoSREVWSUNFX1RZUEVfU0VOU09SEAUSFQoRRE'
    'VWSUNFX1RZUEVfUkVMQVkQBg==');

@$core.Deprecated('Use alertConditionDescriptor instead')
const AlertCondition$json = {
  '1': 'AlertCondition',
  '2': [
    {'1': 'ALERT_CONDITION_UNSPECIFIED', '2': 0},
    {'1': 'ALERT_CONDITION_ENTER', '2': 1},
    {'1': 'ALERT_CONDITION_EXIT', '2': 2},
    {'1': 'ALERT_CONDITION_NEAR', '2': 3},
    {'1': 'ALERT_CONDITION_FAR', '2': 4},
    {'1': 'ALERT_CONDITION_LOW_BATTERY', '2': 5},
  ],
};

/// Descriptor for `AlertCondition`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List alertConditionDescriptor = $convert.base64Decode(
    'Cg5BbGVydENvbmRpdGlvbhIfChtBTEVSVF9DT05ESVRJT05fVU5TUEVDSUZJRUQQABIZChVBTE'
    'VSVF9DT05ESVRJT05fRU5URVIQARIYChRBTEVSVF9DT05ESVRJT05fRVhJVBACEhgKFEFMRVJU'
    'X0NPTkRJVElPTl9ORUFSEAMSFwoTQUxFUlRfQ09ORElUSU9OX0ZBUhAEEh8KG0FMRVJUX0NPTk'
    'RJVElPTl9MT1dfQkFUVEVSWRAF');

@$core.Deprecated('Use sensorTypeDescriptor instead')
const SensorType$json = {
  '1': 'SensorType',
  '2': [
    {'1': 'SENSOR_UNKNOWN', '2': 0},
    {'1': 'SENSOR_TEMPERATURE', '2': 1},
    {'1': 'SENSOR_HUMIDITY', '2': 2},
    {'1': 'SENSOR_LATITUDE', '2': 3},
    {'1': 'SENSOR_LONGITUDE', '2': 4},
    {'1': 'SENSOR_LENGTH', '2': 5},
    {'1': 'SENSOR_ACCEL_X', '2': 6},
    {'1': 'SENSOR_ACCEL_Y', '2': 7},
    {'1': 'SENSOR_ACCEL_Z', '2': 8},
    {'1': 'SENSOR_GYRO_X', '2': 9},
    {'1': 'SENSOR_GYRO_Y', '2': 10},
    {'1': 'SENSOR_GYRO_Z', '2': 11},
  ],
};

/// Descriptor for `SensorType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sensorTypeDescriptor = $convert.base64Decode(
    'CgpTZW5zb3JUeXBlEhIKDlNFTlNPUl9VTktOT1dOEAASFgoSU0VOU09SX1RFTVBFUkFUVVJFEA'
    'ESEwoPU0VOU09SX0hVTUlESVRZEAISEwoPU0VOU09SX0xBVElUVURFEAMSFAoQU0VOU09SX0xP'
    'TkdJVFVERRAEEhEKDVNFTlNPUl9MRU5HVEgQBRISCg5TRU5TT1JfQUNDRUxfWBAGEhIKDlNFTl'
    'NPUl9BQ0NFTF9ZEAcSEgoOU0VOU09SX0FDQ0VMX1oQCBIRCg1TRU5TT1JfR1lST19YEAkSEQoN'
    'U0VOU09SX0dZUk9fWRAKEhEKDVNFTlNPUl9HWVJPX1oQCw==');

@$core.Deprecated('Use messageBodyDescriptor instead')
const MessageBody$json = {
  '1': 'MessageBody',
  '2': [
    {'1': 'message_id_high', '3': 1, '4': 1, '5': 4, '10': 'messageIdHigh'},
    {'1': 'message_id_low', '3': 2, '4': 1, '5': 4, '10': 'messageIdLow'},
    {'1': 'sequence', '3': 3, '4': 1, '5': 17, '10': 'sequence'},
    {
      '1': 'mime',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.Mime',
      '10': 'mime'
    },
    {'1': 'payload', '3': 5, '4': 1, '5': 12, '10': 'payload'},
    {'1': 'group_id_high', '3': 6, '4': 1, '5': 4, '10': 'groupIdHigh'},
    {'1': 'group_id_low', '3': 7, '4': 1, '5': 4, '10': 'groupIdLow'},
  ],
};

/// Descriptor for `MessageBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageBodyDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlQm9keRImCg9tZXNzYWdlX2lkX2hpZ2gYASABKARSDW1lc3NhZ2VJZEhpZ2gSJA'
    'oObWVzc2FnZV9pZF9sb3cYAiABKARSDG1lc3NhZ2VJZExvdxIaCghzZXF1ZW5jZRgDIAEoEVII'
    'c2VxdWVuY2USKAoEbWltZRgEIAEoDjIULmFpLmVkZ2V6LmhhbG93Lk1pbWVSBG1pbWUSGAoHcG'
    'F5bG9hZBgFIAEoDFIHcGF5bG9hZBIiCg1ncm91cF9pZF9oaWdoGAYgASgEUgtncm91cElkSGln'
    'aBIgCgxncm91cF9pZF9sb3cYByABKARSCmdyb3VwSWRMb3c=');

@$core.Deprecated('Use reportDescriptor instead')
const Report$json = {
  '1': 'Report',
  '2': [
    {
      '1': 'peers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ai.edgez.halow.Peer',
      '10': 'peers'
    },
  ],
};

/// Descriptor for `Report`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportDescriptor = $convert.base64Decode(
    'CgZSZXBvcnQSKgoFcGVlcnMYASADKAsyFC5haS5lZGdlei5oYWxvdy5QZWVyUgVwZWVycw==');

@$core.Deprecated('Use networkPacketDescriptor instead')
const NetworkPacket$json = {
  '1': 'NetworkPacket',
  '2': [
    {'1': 'from', '3': 1, '4': 1, '5': 4, '10': 'from'},
    {'1': 'to', '3': 2, '4': 1, '5': 4, '10': 'to'},
    {
      '1': 'operation',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.Operation',
      '10': 'operation'
    },
    {
      '1': 'interface',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.Interface',
      '10': 'interface'
    },
    {'1': 'payload', '3': 100, '4': 1, '5': 12, '9': 0, '10': 'payload'},
    {
      '1': 'msg',
      '3': 101,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.MessageBody',
      '9': 0,
      '10': 'msg'
    },
    {
      '1': 'status',
      '3': 102,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.HaLowInterfaceStatus',
      '9': 0,
      '10': 'status'
    },
    {
      '1': 'init',
      '3': 103,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.HaLowInitConfig',
      '9': 0,
      '10': 'init'
    },
    {
      '1': 'device_settings',
      '3': 104,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.DeviceSettings',
      '9': 0,
      '10': 'deviceSettings'
    },
    {
      '1': 'script_config',
      '3': 105,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.ScriptConfig',
      '9': 0,
      '10': 'scriptConfig'
    },
    {
      '1': 'beacon',
      '3': 106,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.Beacon',
      '9': 0,
      '10': 'beacon'
    },
    {
      '1': 'report',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.Report',
      '9': 0,
      '10': 'report'
    },
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `NetworkPacket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List networkPacketDescriptor = $convert.base64Decode(
    'Cg1OZXR3b3JrUGFja2V0EhIKBGZyb20YASABKARSBGZyb20SDgoCdG8YAiABKARSAnRvEjcKCW'
    '9wZXJhdGlvbhgDIAEoDjIZLmFpLmVkZ2V6LmhhbG93Lk9wZXJhdGlvblIJb3BlcmF0aW9uEjcK'
    'CWludGVyZmFjZRgEIAEoDjIZLmFpLmVkZ2V6LmhhbG93LkludGVyZmFjZVIJaW50ZXJmYWNlEh'
    'oKB3BheWxvYWQYZCABKAxIAFIHcGF5bG9hZBIvCgNtc2cYZSABKAsyGy5haS5lZGdlei5oYWxv'
    'dy5NZXNzYWdlQm9keUgAUgNtc2cSPgoGc3RhdHVzGGYgASgLMiQuYWkuZWRnZXouaGFsb3cuSG'
    'FMb3dJbnRlcmZhY2VTdGF0dXNIAFIGc3RhdHVzEjUKBGluaXQYZyABKAsyHy5haS5lZGdlei5o'
    'YWxvdy5IYUxvd0luaXRDb25maWdIAFIEaW5pdBJJCg9kZXZpY2Vfc2V0dGluZ3MYaCABKAsyHi'
    '5haS5lZGdlei5oYWxvdy5EZXZpY2VTZXR0aW5nc0gAUg5kZXZpY2VTZXR0aW5ncxJDCg1zY3Jp'
    'cHRfY29uZmlnGGkgASgLMhwuYWkuZWRnZXouaGFsb3cuU2NyaXB0Q29uZmlnSABSDHNjcmlwdE'
    'NvbmZpZxIwCgZiZWFjb24YaiABKAsyFi5haS5lZGdlei5oYWxvdy5CZWFjb25IAFIGYmVhY29u'
    'EjAKBnJlcG9ydBhrIAEoCzIWLmFpLmVkZ2V6LmhhbG93LlJlcG9ydEgAUgZyZXBvcnRCBgoEYm'
    '9keQ==');

@$core.Deprecated('Use geoFenceDescriptor instead')
const GeoFence$json = {
  '1': 'GeoFence',
  '2': [
    {'1': 'id_high', '3': 1, '4': 1, '5': 4, '10': 'idHigh'},
    {'1': 'id_low', '3': 2, '4': 1, '5': 4, '10': 'idLow'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'marker',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.MarkerColor',
      '10': 'marker'
    },
    {
      '1': 'alert_condition',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.AlertCondition',
      '10': 'alertCondition'
    },
    {'1': 'geo_index', '3': 6, '4': 1, '5': 13, '10': 'geoIndex'},
  ],
};

/// Descriptor for `GeoFence`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List geoFenceDescriptor = $convert.base64Decode(
    'CghHZW9GZW5jZRIXCgdpZF9oaWdoGAEgASgEUgZpZEhpZ2gSFQoGaWRfbG93GAIgASgEUgVpZE'
    'xvdxISCgRuYW1lGAMgASgJUgRuYW1lEjMKBm1hcmtlchgEIAEoDjIbLmFpLmVkZ2V6LmhhbG93'
    'Lk1hcmtlckNvbG9yUgZtYXJrZXISRwoPYWxlcnRfY29uZGl0aW9uGAUgASgOMh4uYWkuZWRnZX'
    'ouaGFsb3cuQWxlcnRDb25kaXRpb25SDmFsZXJ0Q29uZGl0aW9uEhsKCWdlb19pbmRleBgGIAEo'
    'DVIIZ2VvSW5kZXg=');

@$core.Deprecated('Use sensorDataDescriptor instead')
const SensorData$json = {
  '1': 'SensorData',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.SensorType',
      '10': 'type'
    },
    {'1': 'bool_value', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'boolValue'},
    {'1': 'int_value', '3': 3, '4': 1, '5': 17, '9': 0, '10': 'intValue'},
    {'1': 'float_value', '3': 4, '4': 1, '5': 2, '9': 0, '10': 'floatValue'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `SensorData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sensorDataDescriptor = $convert.base64Decode(
    'CgpTZW5zb3JEYXRhEi4KBHR5cGUYASABKA4yGi5haS5lZGdlei5oYWxvdy5TZW5zb3JUeXBlUg'
    'R0eXBlEh8KCmJvb2xfdmFsdWUYAiABKAhIAFIJYm9vbFZhbHVlEh0KCWludF92YWx1ZRgDIAEo'
    'EUgAUghpbnRWYWx1ZRIhCgtmbG9hdF92YWx1ZRgEIAEoAkgAUgpmbG9hdFZhbHVlQgcKBXZhbH'
    'Vl');

@$core.Deprecated('Use peerDescriptor instead')
const Peer$json = {
  '1': 'Peer',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
    {'1': 'rssi', '3': 2, '4': 1, '5': 17, '10': 'rssi'},
    {
      '1': 'sensor_data',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.ai.edgez.halow.SensorData',
      '10': 'sensorData'
    },
  ],
};

/// Descriptor for `Peer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerDescriptor = $convert.base64Decode(
    'CgRQZWVyEg4KAmlkGAEgASgEUgJpZBISCgRyc3NpGAIgASgRUgRyc3NpEjsKC3NlbnNvcl9kYX'
    'RhGAMgAygLMhouYWkuZWRnZXouaGFsb3cuU2Vuc29yRGF0YVIKc2Vuc29yRGF0YQ==');

@$core.Deprecated('Use beaconDescriptor instead')
const Beacon$json = {
  '1': 'Beacon',
  '2': [
    {'1': 'user_id_high', '3': 1, '4': 1, '5': 4, '10': 'userIdHigh'},
    {'1': 'user_id_low', '3': 2, '4': 1, '5': 4, '10': 'userIdLow'},
    {'1': 'user_name', '3': 3, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'user_public_key', '3': 4, '4': 1, '5': 12, '10': 'userPublicKey'},
    {'1': 'latitude', '3': 5, '4': 1, '5': 2, '10': 'latitude'},
    {'1': 'longitude', '3': 6, '4': 1, '5': 2, '10': 'longitude'},
    {
      '1': 'marker',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.MarkerColor',
      '10': 'marker'
    },
    {
      '1': 'device_type',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.DeviceType',
      '10': 'deviceType'
    },
    {'1': 'sleeping', '3': 10, '4': 1, '5': 8, '10': 'sleeping'},
    {
      '1': 'geo_fence',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.GeoFence',
      '10': 'geoFence'
    },
    {
      '1': 'sensor_data',
      '3': 101,
      '4': 3,
      '5': 11,
      '6': '.ai.edgez.halow.SensorData',
      '10': 'sensorData'
    },
  ],
};

/// Descriptor for `Beacon`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List beaconDescriptor = $convert.base64Decode(
    'CgZCZWFjb24SIAoMdXNlcl9pZF9oaWdoGAEgASgEUgp1c2VySWRIaWdoEh4KC3VzZXJfaWRfbG'
    '93GAIgASgEUgl1c2VySWRMb3cSGwoJdXNlcl9uYW1lGAMgASgJUgh1c2VyTmFtZRImCg91c2Vy'
    'X3B1YmxpY19rZXkYBCABKAxSDXVzZXJQdWJsaWNLZXkSGgoIbGF0aXR1ZGUYBSABKAJSCGxhdG'
    'l0dWRlEhwKCWxvbmdpdHVkZRgGIAEoAlIJbG9uZ2l0dWRlEjMKBm1hcmtlchgHIAEoDjIbLmFp'
    'LmVkZ2V6LmhhbG93Lk1hcmtlckNvbG9yUgZtYXJrZXISOwoLZGV2aWNlX3R5cGUYCCABKA4yGi'
    '5haS5lZGdlei5oYWxvdy5EZXZpY2VUeXBlUgpkZXZpY2VUeXBlEhoKCHNsZWVwaW5nGAogASgI'
    'UghzbGVlcGluZxI1CglnZW9fZmVuY2UYZCABKAsyGC5haS5lZGdlei5oYWxvdy5HZW9GZW5jZV'
    'IIZ2VvRmVuY2USOwoLc2Vuc29yX2RhdGEYZSADKAsyGi5haS5lZGdlei5oYWxvdy5TZW5zb3JE'
    'YXRhUgpzZW5zb3JEYXRh');

@$core.Deprecated('Use haLowInterfaceStatusDescriptor instead')
const HaLowInterfaceStatus$json = {
  '1': 'HaLowInterfaceStatus',
  '2': [
    {'1': 'supported', '3': 1, '4': 1, '5': 8, '10': 'supported'},
    {
      '1': 'stack_initialized',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'stackInitialized'
    },
    {'1': 'mesh_mode', '3': 3, '4': 1, '5': 8, '10': 'meshMode'},
    {'1': 'link_up', '3': 4, '4': 1, '5': 8, '10': 'linkUp'},
    {'1': 'route_ready', '3': 5, '4': 1, '5': 8, '10': 'routeReady'},
    {'1': 'ready_for_report', '3': 6, '4': 1, '5': 8, '10': 'readyForReport'},
    {'1': 'ethertype', '3': 7, '4': 1, '5': 13, '10': 'ethertype'},
    {'1': 'mesh_id', '3': 8, '4': 1, '5': 9, '10': 'meshId'},
    {'1': 'ip_addr', '3': 9, '4': 1, '5': 9, '10': 'ipAddr'},
    {'1': 'gateway', '3': 10, '4': 1, '5': 9, '10': 'gateway'},
    {'1': 'mac_address', '3': 11, '4': 1, '5': 4, '10': 'macAddress'},
    {
      '1': 'license_status',
      '3': 12,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.LicenseStatus',
      '10': 'licenseStatus'
    },
    {'1': 'firmware_version', '3': 13, '4': 1, '5': 9, '10': 'firmwareVersion'},
  ],
};

/// Descriptor for `HaLowInterfaceStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List haLowInterfaceStatusDescriptor = $convert.base64Decode(
    'ChRIYUxvd0ludGVyZmFjZVN0YXR1cxIcCglzdXBwb3J0ZWQYASABKAhSCXN1cHBvcnRlZBIrCh'
    'FzdGFja19pbml0aWFsaXplZBgCIAEoCFIQc3RhY2tJbml0aWFsaXplZBIbCgltZXNoX21vZGUY'
    'AyABKAhSCG1lc2hNb2RlEhcKB2xpbmtfdXAYBCABKAhSBmxpbmtVcBIfCgtyb3V0ZV9yZWFkeR'
    'gFIAEoCFIKcm91dGVSZWFkeRIoChByZWFkeV9mb3JfcmVwb3J0GAYgASgIUg5yZWFkeUZvclJl'
    'cG9ydBIcCglldGhlcnR5cGUYByABKA1SCWV0aGVydHlwZRIXCgdtZXNoX2lkGAggASgJUgZtZX'
    'NoSWQSFwoHaXBfYWRkchgJIAEoCVIGaXBBZGRyEhgKB2dhdGV3YXkYCiABKAlSB2dhdGV3YXkS'
    'HwoLbWFjX2FkZHJlc3MYCyABKARSCm1hY0FkZHJlc3MSRAoObGljZW5zZV9zdGF0dXMYDCABKA'
    '4yHS5haS5lZGdlei5oYWxvdy5MaWNlbnNlU3RhdHVzUg1saWNlbnNlU3RhdHVzEikKEGZpcm13'
    'YXJlX3ZlcnNpb24YDSABKAlSD2Zpcm13YXJlVmVyc2lvbg==');

@$core.Deprecated('Use haLowInitConfigDescriptor instead')
const HaLowInitConfig$json = {
  '1': 'HaLowInitConfig',
  '2': [
    {'1': 'country_code', '3': 1, '4': 1, '5': 9, '10': 'countryCode'},
    {'1': 'mesh_id', '3': 2, '4': 1, '5': 9, '10': 'meshId'},
    {'1': 'passphrase', '3': 3, '4': 1, '5': 9, '10': 'passphrase'},
    {'1': 'max_hop', '3': 4, '4': 1, '5': 13, '10': 'maxHop'},
    {'1': 'user_id_high', '3': 5, '4': 1, '5': 4, '10': 'userIdHigh'},
    {'1': 'user_id_low', '3': 6, '4': 1, '5': 4, '10': 'userIdLow'},
    {'1': 'user_name', '3': 7, '4': 1, '5': 9, '10': 'userName'},
    {'1': 'user_public_key', '3': 8, '4': 1, '5': 12, '10': 'userPublicKey'},
    {'1': 'marker', '3': 9, '4': 1, '5': 9, '10': 'marker'},
    {'1': 'has_location', '3': 10, '4': 1, '5': 8, '10': 'hasLocation'},
    {'1': 'latitude', '3': 11, '4': 1, '5': 2, '10': 'latitude'},
    {'1': 'longitude', '3': 12, '4': 1, '5': 2, '10': 'longitude'},
    {
      '1': 'mesh_bandwidth_mhz',
      '3': 13,
      '4': 1,
      '5': 13,
      '10': 'meshBandwidthMhz'
    },
    {
      '1': 'mesh_frequency_khz',
      '3': 14,
      '4': 1,
      '5': 13,
      '10': 'meshFrequencyKhz'
    },
    {
      '1': 'sdk_compatibility',
      '3': 15,
      '4': 1,
      '5': 9,
      '10': 'sdkCompatibility'
    },
    {'1': 'sdk_release_id', '3': 16, '4': 1, '5': 9, '10': 'sdkReleaseId'},
    {
      '1': 'sdk_release_signature',
      '3': 17,
      '4': 1,
      '5': 12,
      '10': 'sdkReleaseSignature'
    },
  ],
};

/// Descriptor for `HaLowInitConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List haLowInitConfigDescriptor = $convert.base64Decode(
    'Cg9IYUxvd0luaXRDb25maWcSIQoMY291bnRyeV9jb2RlGAEgASgJUgtjb3VudHJ5Q29kZRIXCg'
    'dtZXNoX2lkGAIgASgJUgZtZXNoSWQSHgoKcGFzc3BocmFzZRgDIAEoCVIKcGFzc3BocmFzZRIX'
    'CgdtYXhfaG9wGAQgASgNUgZtYXhIb3ASIAoMdXNlcl9pZF9oaWdoGAUgASgEUgp1c2VySWRIaW'
    'doEh4KC3VzZXJfaWRfbG93GAYgASgEUgl1c2VySWRMb3cSGwoJdXNlcl9uYW1lGAcgASgJUgh1'
    'c2VyTmFtZRImCg91c2VyX3B1YmxpY19rZXkYCCABKAxSDXVzZXJQdWJsaWNLZXkSFgoGbWFya2'
    'VyGAkgASgJUgZtYXJrZXISIQoMaGFzX2xvY2F0aW9uGAogASgIUgtoYXNMb2NhdGlvbhIaCghs'
    'YXRpdHVkZRgLIAEoAlIIbGF0aXR1ZGUSHAoJbG9uZ2l0dWRlGAwgASgCUglsb25naXR1ZGUSLA'
    'oSbWVzaF9iYW5kd2lkdGhfbWh6GA0gASgNUhBtZXNoQmFuZHdpZHRoTWh6EiwKEm1lc2hfZnJl'
    'cXVlbmN5X2toehgOIAEoDVIQbWVzaEZyZXF1ZW5jeUtoehIrChFzZGtfY29tcGF0aWJpbGl0eR'
    'gPIAEoCVIQc2RrQ29tcGF0aWJpbGl0eRIkCg5zZGtfcmVsZWFzZV9pZBgQIAEoCVIMc2RrUmVs'
    'ZWFzZUlkEjIKFXNka19yZWxlYXNlX3NpZ25hdHVyZRgRIAEoDFITc2RrUmVsZWFzZVNpZ25hdH'
    'VyZQ==');

@$core.Deprecated('Use deviceSettingsDescriptor instead')
const DeviceSettings$json = {
  '1': 'DeviceSettings',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.DeviceSettingsAction',
      '10': 'action'
    },
    {
      '1': 'device_mode_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'deviceModeEnabled'
    },
    {'1': 'mesh_id', '3': 3, '4': 1, '5': 9, '10': 'meshId'},
    {'1': 'share_location', '3': 4, '4': 1, '5': 8, '10': 'shareLocation'},
    {'1': 'user_name', '3': 5, '4': 1, '5': 9, '10': 'userName'},
    {
      '1': 'marker',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.MarkerColor',
      '10': 'marker'
    },
    {
      '1': 'beacon_interval_seconds',
      '3': 7,
      '4': 1,
      '5': 13,
      '10': 'beaconIntervalSeconds'
    },
    {'1': 'user_id_high', '3': 8, '4': 1, '5': 4, '10': 'userIdHigh'},
    {'1': 'user_id_low', '3': 9, '4': 1, '5': 4, '10': 'userIdLow'},
    {'1': 'user_public_key', '3': 10, '4': 1, '5': 12, '10': 'userPublicKey'},
    {'1': 'user_private_key', '3': 11, '4': 1, '5': 12, '10': 'userPrivateKey'},
    {'1': 'latitude', '3': 12, '4': 1, '5': 2, '10': 'latitude'},
    {'1': 'longitude', '3': 13, '4': 1, '5': 2, '10': 'longitude'},
    {'1': 'max_hop', '3': 14, '4': 1, '5': 13, '10': 'maxHop'},
    {
      '1': 'geo_fence',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.ai.edgez.halow.GeoFence',
      '10': 'geoFence'
    },
    {
      '1': 'uart_i2c_sensor_type',
      '3': 16,
      '4': 1,
      '5': 9,
      '10': 'uartI2cSensorType'
    },
    {
      '1': 'rs485_sensor_type',
      '3': 17,
      '4': 1,
      '5': 9,
      '10': 'rs485SensorType'
    },
    {'1': 'geo_index', '3': 18, '4': 1, '5': 13, '10': 'geoIndex'},
    {'1': 'passphrase', '3': 19, '4': 1, '5': 9, '10': 'passphrase'},
    {
      '1': 'upstream_wifi_ssid',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'upstreamWifiSsid'
    },
    {
      '1': 'upstream_wifi_passphrase',
      '3': 21,
      '4': 1,
      '5': 9,
      '10': 'upstreamWifiPassphrase'
    },
    {'1': 'beacon_unicast', '3': 22, '4': 1, '5': 4, '10': 'beaconUnicast'},
    {
      '1': 'device_type',
      '3': 24,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.DeviceType',
      '10': 'deviceType'
    },
    {
      '1': 'sleep_mode_enabled',
      '3': 25,
      '4': 1,
      '5': 8,
      '10': 'sleepModeEnabled'
    },
  ],
};

/// Descriptor for `DeviceSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deviceSettingsDescriptor = $convert.base64Decode(
    'Cg5EZXZpY2VTZXR0aW5ncxI8CgZhY3Rpb24YASABKA4yJC5haS5lZGdlei5oYWxvdy5EZXZpY2'
    'VTZXR0aW5nc0FjdGlvblIGYWN0aW9uEi4KE2RldmljZV9tb2RlX2VuYWJsZWQYAiABKAhSEWRl'
    'dmljZU1vZGVFbmFibGVkEhcKB21lc2hfaWQYAyABKAlSBm1lc2hJZBIlCg5zaGFyZV9sb2NhdG'
    'lvbhgEIAEoCFINc2hhcmVMb2NhdGlvbhIbCgl1c2VyX25hbWUYBSABKAlSCHVzZXJOYW1lEjMK'
    'Bm1hcmtlchgGIAEoDjIbLmFpLmVkZ2V6LmhhbG93Lk1hcmtlckNvbG9yUgZtYXJrZXISNgoXYm'
    'VhY29uX2ludGVydmFsX3NlY29uZHMYByABKA1SFWJlYWNvbkludGVydmFsU2Vjb25kcxIgCgx1'
    'c2VyX2lkX2hpZ2gYCCABKARSCnVzZXJJZEhpZ2gSHgoLdXNlcl9pZF9sb3cYCSABKARSCXVzZX'
    'JJZExvdxImCg91c2VyX3B1YmxpY19rZXkYCiABKAxSDXVzZXJQdWJsaWNLZXkSKAoQdXNlcl9w'
    'cml2YXRlX2tleRgLIAEoDFIOdXNlclByaXZhdGVLZXkSGgoIbGF0aXR1ZGUYDCABKAJSCGxhdG'
    'l0dWRlEhwKCWxvbmdpdHVkZRgNIAEoAlIJbG9uZ2l0dWRlEhcKB21heF9ob3AYDiABKA1SBm1h'
    'eEhvcBI1CglnZW9fZmVuY2UYDyABKAsyGC5haS5lZGdlei5oYWxvdy5HZW9GZW5jZVIIZ2VvRm'
    'VuY2USLwoUdWFydF9pMmNfc2Vuc29yX3R5cGUYECABKAlSEXVhcnRJMmNTZW5zb3JUeXBlEioK'
    'EXJzNDg1X3NlbnNvcl90eXBlGBEgASgJUg9yczQ4NVNlbnNvclR5cGUSGwoJZ2VvX2luZGV4GB'
    'IgASgNUghnZW9JbmRleBIeCgpwYXNzcGhyYXNlGBMgASgJUgpwYXNzcGhyYXNlEiwKEnVwc3Ry'
    'ZWFtX3dpZmlfc3NpZBgUIAEoCVIQdXBzdHJlYW1XaWZpU3NpZBI4Chh1cHN0cmVhbV93aWZpX3'
    'Bhc3NwaHJhc2UYFSABKAlSFnVwc3RyZWFtV2lmaVBhc3NwaHJhc2USJQoOYmVhY29uX3VuaWNh'
    'c3QYFiABKARSDWJlYWNvblVuaWNhc3QSOwoLZGV2aWNlX3R5cGUYGCABKA4yGi5haS5lZGdlei'
    '5oYWxvdy5EZXZpY2VUeXBlUgpkZXZpY2VUeXBlEiwKEnNsZWVwX21vZGVfZW5hYmxlZBgZIAEo'
    'CFIQc2xlZXBNb2RlRW5hYmxlZA==');

@$core.Deprecated('Use scriptConfigDescriptor instead')
const ScriptConfig$json = {
  '1': 'ScriptConfig',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ai.edgez.halow.ScriptConfigAction',
      '10': 'action'
    },
    {'1': 'script_id', '3': 2, '4': 1, '5': 13, '10': 'scriptId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 4, '4': 1, '5': 13, '10': 'version'},
    {'1': 'total_size', '3': 5, '4': 1, '5': 13, '10': 'totalSize'},
    {'1': 'offset', '3': 6, '4': 1, '5': 13, '10': 'offset'},
    {'1': 'chunk', '3': 7, '4': 1, '5': 12, '10': 'chunk'},
    {'1': 'sensor_type', '3': 8, '4': 1, '5': 9, '10': 'sensorType'},
    {'1': 'select_uart_i2c', '3': 9, '4': 1, '5': 8, '10': 'selectUartI2c'},
    {'1': 'select_rs485', '3': 10, '4': 1, '5': 8, '10': 'selectRs485'},
    {
      '1': 'global_buffer_size',
      '3': 11,
      '4': 1,
      '5': 13,
      '10': 'globalBufferSize'
    },
    {'1': 'mime_type', '3': 12, '4': 1, '5': 9, '10': 'mimeType'},
  ],
};

/// Descriptor for `ScriptConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scriptConfigDescriptor = $convert.base64Decode(
    'CgxTY3JpcHRDb25maWcSOgoGYWN0aW9uGAEgASgOMiIuYWkuZWRnZXouaGFsb3cuU2NyaXB0Q2'
    '9uZmlnQWN0aW9uUgZhY3Rpb24SGwoJc2NyaXB0X2lkGAIgASgNUghzY3JpcHRJZBISCgRuYW1l'
    'GAMgASgJUgRuYW1lEhgKB3ZlcnNpb24YBCABKA1SB3ZlcnNpb24SHQoKdG90YWxfc2l6ZRgFIA'
    'EoDVIJdG90YWxTaXplEhYKBm9mZnNldBgGIAEoDVIGb2Zmc2V0EhQKBWNodW5rGAcgASgMUgVj'
    'aHVuaxIfCgtzZW5zb3JfdHlwZRgIIAEoCVIKc2Vuc29yVHlwZRImCg9zZWxlY3RfdWFydF9pMm'
    'MYCSABKAhSDXNlbGVjdFVhcnRJMmMSIQoMc2VsZWN0X3JzNDg1GAogASgIUgtzZWxlY3RSczQ4'
    'NRIsChJnbG9iYWxfYnVmZmVyX3NpemUYCyABKA1SEGdsb2JhbEJ1ZmZlclNpemUSGwoJbWltZV'
    '90eXBlGAwgASgJUghtaW1lVHlwZQ==');
