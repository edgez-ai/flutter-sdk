import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

enum ExampleDeviceType {
  unspecified('Unspecified', true),
  user('User', true),
  gateway('Gateway', false),
  beacon('Beacon', false),
  sensor('Sensor', false);

  const ExampleDeviceType(this.label, this.opensConversation);

  final String label;
  final bool opensConversation;
}

enum ExampleMarker {
  blue('Blue', Colors.blue),
  red('Red', Colors.red),
  green('Green', Colors.green),
  orange('Orange', Colors.orange),
  purple('Purple', Colors.deepPurple),
  teal('Teal', Colors.teal),
  gray('Gray', Colors.blueGrey);

  const ExampleMarker(this.label, this.color);

  final String label;
  final Color color;

  static ExampleMarker fromId(String id) {
    return ExampleMarker.values.firstWhere(
      (marker) => marker.name == id,
      orElse: () => ExampleMarker.blue,
    );
  }
}

class ExampleGeoFence {
  const ExampleGeoFence({
    required this.name,
    required this.marker,
    required this.alertCondition,
  });

  final String name;
  final ExampleMarker marker;
  final String alertCondition;
}

class ExampleSensorData {
  const ExampleSensorData({
    this.latitude,
    this.longitude,
    this.altitude,
    this.temperature,
    this.humidity,
    this.pressure,
    this.vibrationAverage,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? temperature;
  final double? humidity;
  final double? pressure;
  final double? vibrationAverage;

  bool get hasAnyValue {
    return latitude != null ||
        longitude != null ||
        altitude != null ||
        temperature != null ||
        humidity != null ||
        pressure != null ||
        vibrationAverage != null;
  }
}

class ExampleSensorSample {
  const ExampleSensorSample({
    required this.timestampMs,
    required this.data,
  });

  final int timestampMs;
  final ExampleSensorData data;
}

class ExampleNode {
  const ExampleNode({
    required this.meshNode,
    required this.deviceType,
    required this.hasPublicKey,
    this.geoFence,
    this.geoIndex = 0,
    this.samples = const <ExampleSensorSample>[],
  });

  final EdgezMeshNode meshNode;
  final ExampleDeviceType deviceType;
  final bool hasPublicKey;
  final ExampleGeoFence? geoFence;
  final int geoIndex;
  final List<ExampleSensorSample> samples;

  int get nodeNum => meshNode.nodeNum;
  String get displayName => meshNode.displayName;
  String get nodeId => meshNode.nodeId;
  String get userId =>
      meshNode.userUuid.isNotEmpty ? meshNode.userUuid : nodeNum.toString();
  String get route => meshNode.route;
  bool get sleeping => meshNode.sleeping;
  ExampleMarker get marker => ExampleMarker.fromId(meshNode.marker);

  bool get hasLocation =>
      meshNode.latitude != null && meshNode.longitude != null;
}
