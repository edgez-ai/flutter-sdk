import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

enum ExampleDashboardWidget {
  tempHumidity('Temp & Humidity'),
  latestValue('Latest value'),
  imuOrientation('IMU orientation'),
  binaryData('Binary data'),
  timeSeries('Time series');

  const ExampleDashboardWidget(this.label);

  final String label;

  static ExampleDashboardWidget fromName(String? name) {
    return ExampleDashboardWidget.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ExampleDashboardWidget.tempHumidity,
    );
  }
}

enum ExampleDashboardRange {
  latest('Latest value', null),
  last30Minutes('Last 30 min', Duration(minutes: 30)),
  lastHour('Last 1 hour', Duration(hours: 1)),
  last6Hours('Last 6 hours', Duration(hours: 6));

  const ExampleDashboardRange(this.label, this.window);

  final String label;
  final Duration? window;

  static const timeSeriesOptions = <ExampleDashboardRange>[
    last30Minutes,
    lastHour,
    last6Hours,
  ];

  static ExampleDashboardRange fromName(String? name) {
    return ExampleDashboardRange.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ExampleDashboardRange.latest,
    );
  }
}

class ExampleDashboardDisplay {
  const ExampleDashboardDisplay({
    required this.deviceKey,
    this.showOnDashboard = false,
    this.widget = ExampleDashboardWidget.tempHumidity,
    this.range = ExampleDashboardRange.latest,
  });

  final String deviceKey;
  final bool showOnDashboard;
  final ExampleDashboardWidget widget;
  final ExampleDashboardRange range;

  ExampleDashboardDisplay copyWith({
    bool? showOnDashboard,
    ExampleDashboardWidget? widget,
    ExampleDashboardRange? range,
  }) {
    return ExampleDashboardDisplay(
      deviceKey: deviceKey,
      showOnDashboard: showOnDashboard ?? this.showOnDashboard,
      widget: widget ?? this.widget,
      range: range ?? this.range,
    );
  }
}

enum ExampleDeviceType {
  unspecified('Unspecified', true),
  user('User', true),
  gateway('Gateway', false),
  beacon('Beacon', false),
  sensor('Sensor', false),
  relay('Relay', false);

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
