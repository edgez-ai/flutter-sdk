import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'device_detail_screen.dart';
import 'models.dart';
import 'shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.activeConnection,
    required this.status,
    required this.users,
    required this.sensorSamples,
    required this.dashboardDisplays,
    required this.onOpenProvisioning,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final Map<String, ExampleDashboardDisplay> dashboardDisplays;
  final VoidCallback onOpenProvisioning;
  final ValueChanged<EdgezMeshNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    final items = <_DashboardItem>[
      for (final user in users)
        if (dashboardDisplays[user.exampleUserId] case final display?
            when display.showOnDashboard)
          _DashboardItem(
            user: user,
            display: display,
            samples: sensorSamples[user.nodeNum] ?? const <EdgezSensorSample>[],
          ),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              FilledButton.icon(
                onPressed: onOpenProvisioning,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('Prov'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoCard(
            title: 'Mesh overview',
            action: HaLowMeshStatusIcon(status: status),
            children: <Widget>[
              _DashboardValue(
                  label: 'Interface',
                  value: activeConnection.name.toUpperCase()),
              _DashboardValue(
                  label: 'Known nodes', value: users.length.toString()),
              _DashboardValue(
                  label: 'License',
                  value: status?.licenseStatus.label ?? 'Waiting for device'),
            ],
          ),
          const SizedBox(height: 16),
          Text('Visualization widgets',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const InfoCard(
              title: 'No dashboard devices yet',
              children: <Widget>[
                Text(
                    'Use the dashboard button on a node to add it, then choose its visualization from device details.'),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth >= 520
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final item in items)
                      SizedBox(
                        width: item.isCompact
                            ? compactWidth
                            : constraints.maxWidth,
                        child: item.user.opensConversation
                            ? _DashboardUserCard(
                                item: item,
                                onTap: () => onOpenNode(item.user),
                              )
                            : _DashboardSensorCard(
                                item: item,
                                onTap: () => onOpenNode(item.user),
                              ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.user,
    required this.display,
    required this.samples,
  });

  final EdgezMeshNode user;
  final ExampleDashboardDisplay display;
  final List<EdgezSensorSample> samples;

  bool get isCompact =>
      user.opensConversation ||
      display.widget != ExampleDashboardWidget.timeSeries;
}

class _DashboardUserCard extends StatelessWidget {
  const _DashboardUserCard({required this.item, required this.onTap});

  final _DashboardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _markerCardColor(context, item.user),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.user.resolvedDisplayName,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Tap to open conversation',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Node ${item.user.nodeId}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSensorCard extends StatelessWidget {
  const _DashboardSensorCard({required this.item, required this.onTap});

  final _DashboardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final samples = _samplesInRange(item.samples, item.display.range);
    final sample = samples.lastOrNull;
    return Card(
      color: _markerCardColor(context, item.user),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.user.resolvedDisplayName,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(item.display.widget.label,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              if (sample == null || !sample.data.hasAnyValue)
                const Text('No sensor data')
              else
                switch (item.display.widget) {
                  ExampleDashboardWidget.tempHumidity => _TempHumidity(
                      data: sample.data,
                    ),
                  ExampleDashboardWidget.latestValue => _LatestValues(
                      sample: sample,
                    ),
                  ExampleDashboardWidget.imuOrientation => _ImuOrientation(
                      data: sample.data,
                    ),
                  ExampleDashboardWidget.binaryData => _BinaryData(
                      sample: sample,
                    ),
                  ExampleDashboardWidget.timeSeries => _TimeSeries(
                      samples: samples,
                      range: item.display.range,
                    ),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _TempHumidity extends StatelessWidget {
  const _TempHumidity({required this.data});

  final EdgezSensorData data;

  @override
  Widget build(BuildContext context) {
    if (data.temperature == null && data.humidity == null) {
      return const Text('No temp or humidity');
    }
    return Column(
      children: <Widget>[
        SensorValueRow(label: 'Temp', value: data.temperature, unit: '°C'),
        SensorValueRow(label: 'Humidity', value: data.humidity, unit: '%'),
      ],
    );
  }
}

class _LatestValues extends StatelessWidget {
  const _LatestValues({required this.sample});

  final EdgezSensorSample sample;

  @override
  Widget build(BuildContext context) {
    final data = sample.data;
    return Column(
      children: <Widget>[
        SensorValueRow(
            label: 'Temperature', value: data.temperature, unit: '°C'),
        SensorValueRow(label: 'Humidity', value: data.humidity, unit: '%'),
        SensorValueRow(label: 'Pressure', value: data.pressure, unit: 'hPa'),
        SensorValueRow(
            label: 'Pass-by score', value: data.vibrationAverage, unit: ''),
        SensorValueRow(label: 'Altitude', value: data.altitude, unit: 'm'),
        SensorValueRow(label: 'Accel X', value: data.accelX, unit: 'm/s²'),
        SensorValueRow(label: 'Accel Y', value: data.accelY, unit: 'm/s²'),
        SensorValueRow(label: 'Accel Z', value: data.accelZ, unit: 'm/s²'),
        SensorValueRow(label: 'Gyro X', value: data.gyroX, unit: 'rad/s'),
        SensorValueRow(label: 'Gyro Y', value: data.gyroY, unit: 'rad/s'),
        SensorValueRow(label: 'Gyro Z', value: data.gyroZ, unit: 'rad/s'),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Updated ${formatLastSeenAge(sample.timestampMs)}',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _BinaryData extends StatelessWidget {
  const _BinaryData({required this.sample});

  final EdgezSensorSample sample;

  @override
  Widget build(BuildContext context) {
    final length = sample.data.binaryLengthBytes;
    return Text(
        length == null ? 'No binary data' : 'Binary length: $length bytes');
  }
}

class _TimeSeries extends StatelessWidget {
  const _TimeSeries({required this.samples, required this.range});

  final List<EdgezSensorSample> samples;
  final ExampleDashboardRange range;

  @override
  Widget build(BuildContext context) {
    final chartable = samples.where(_hasChartValue).toList(growable: false);
    if (chartable.isEmpty) return const Text('No chartable sensor data');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(range.label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter:
                SensorChartPainter(chartable, Theme.of(context).colorScheme),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Text('${chartable.length} samples',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ImuOrientation extends StatelessWidget {
  const _ImuOrientation({required this.data});

  final EdgezSensorData data;

  @override
  Widget build(BuildContext context) {
    final ax = data.accelX;
    final ay = data.accelY;
    final az = data.accelZ;
    if (ax == null || ay == null || az == null) {
      return const Text('No acceleration orientation data');
    }
    final magnitude = math.sqrt(ax * ax + ay * ay + az * az);
    if (magnitude < 0.01) return const Text('No acceleration orientation data');
    final roll = math.atan2(ay, az);
    final pitch = math.atan2(-ax, math.sqrt(ay * ay + az * az));
    return Column(
      children: <Widget>[
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _OrientationPainter(
              roll: roll,
              pitch: pitch,
              colorScheme: Theme.of(context).colorScheme,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Text(
          'Roll ${(roll * 180 / math.pi).toStringAsFixed(1)}°   '
          'Pitch ${(pitch * 180 / math.pi).toStringAsFixed(1)}°',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _OrientationPainter extends CustomPainter {
  const _OrientationPainter({
    required this.roll,
    required this.pitch,
    required this.colorScheme,
  });

  final double roll;
  final double pitch;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(roll);
    final height = 42.0 * math.cos(pitch).abs().clamp(0.25, 1.0);
    final rect = Rect.fromCenter(
        center: Offset.zero,
        width: math.min(size.width * 0.7, 180),
        height: height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = colorScheme.primaryContainer,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()
        ..color = colorScheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(rect.centerRight, 5, Paint()..color = colorScheme.error);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrientationPainter oldDelegate) =>
      oldDelegate.roll != roll ||
      oldDelegate.pitch != pitch ||
      oldDelegate.colorScheme != colorScheme;
}

List<EdgezSensorSample> _samplesInRange(
    List<EdgezSensorSample> samples, ExampleDashboardRange range) {
  final window = range.window;
  if (window == null) return samples;
  final since = DateTime.now().millisecondsSinceEpoch - window.inMilliseconds;
  return samples
      .where((sample) => sample.timestampMs >= since)
      .toList(growable: false);
}

bool _hasChartValue(EdgezSensorSample sample) {
  final data = sample.data;
  return data.temperature != null ||
      data.humidity != null ||
      data.pressure != null ||
      data.vibrationAverage != null;
}

Color _markerCardColor(BuildContext context, EdgezMeshNode user) {
  return Color.alphaBlend(
    user.exampleMarker.color.withValues(alpha: 0.18),
    Theme.of(context).colorScheme.surfaceContainerHighest,
  );
}

class _DashboardValue extends StatelessWidget {
  const _DashboardValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
              width: 104,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
