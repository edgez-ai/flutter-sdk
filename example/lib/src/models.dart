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

ExampleDeviceType deviceTypeFromLabel(String label) {
  final normalized = label.toLowerCase();
  return ExampleDeviceType.values.firstWhere(
    (type) => type.label.toLowerCase() == normalized || type.name == normalized,
    orElse: () => ExampleDeviceType.unspecified,
  );
}

extension ExampleNodePresentation on EdgezMeshNode {
  ExampleDeviceType get exampleDeviceType => deviceTypeFromLabel(deviceType);

  ExampleMarker get exampleMarker => ExampleMarker.fromId(marker);

  String get exampleUserId =>
      userUuid.isNotEmpty ? userUuid : nodeNum.toString();

  String get exampleGeoFenceName => geoFenceName;
}
