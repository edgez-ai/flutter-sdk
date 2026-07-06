import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({
    required this.user,
    required this.samples,
    required this.onBack,
    super.key,
  });

  final EdgezMeshNode user;
  final List<EdgezSensorSample> samples;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final latest = samples.lastOrNull?.data;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextButton(onPressed: onBack, child: const Text('Back')),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Conversation · ${user.exampleDeviceType.label}',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(user.resolvedDisplayName),
                  Text('Node ${user.nodeId}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          DeviceSummaryCard(user: user),
          const SizedBox(height: 12),
          GeoFenceCard(user: user),
          const SizedBox(height: 12),
          SensorLatestCard(
              data: latest, timestampMs: samples.lastOrNull?.timestampMs),
          const SizedBox(height: 12),
          SensorChartCard(samples: samples),
        ],
      ),
    );
  }
}

class DeviceSummaryCard extends StatelessWidget {
  const DeviceSummaryCard({required this.user, super.key});

  final EdgezMeshNode user;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Device',
      children: <Widget>[
        Text('Type ${user.exampleDeviceType.label}'),
        Text('Marker ${user.exampleMarker.label}'),
        Text('User ${user.exampleUserId}',
            style: Theme.of(context).textTheme.bodySmall),
        if (user.sleeping)
          Text('Sleeping', style: Theme.of(context).textTheme.bodySmall),
        if (user.hasLocation)
          Text(
              'Location ${formatCoordinate(user.latitude)}, ${formatCoordinate(user.longitude)}'),
      ],
    );
  }
}

class GeoFenceCard extends StatelessWidget {
  const GeoFenceCard({required this.user, super.key});

  final EdgezMeshNode user;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Geo fence',
      children: user.geoFenceName.isEmpty
          ? const <Widget>[Text('None')]
          : <Widget>[
              Text(user.geoFenceName),
              Text('${user.exampleMarker.label} · Enter',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Index ${user.geoIndex}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
    );
  }
}

class SensorLatestCard extends StatelessWidget {
  const SensorLatestCard(
      {required this.data, required this.timestampMs, super.key});

  final EdgezSensorData? data;
  final int? timestampMs;

  @override
  Widget build(BuildContext context) {
    final current = data;
    return InfoCard(
      title: 'Sensor',
      children: current == null || !current.hasAnyValue
          ? const <Widget>[Text('No sensor data received yet')]
          : <Widget>[
              SensorValueRow(
                  label: 'Temperature', value: current.temperature, unit: 'C'),
              SensorValueRow(
                  label: 'Humidity', value: current.humidity, unit: '%'),
              SensorValueRow(
                  label: 'Pressure', value: current.pressure, unit: 'hPa'),
              SensorValueRow(
                  label: 'Pass-by score',
                  value: current.vibrationAverage,
                  unit: ''),
              SensorValueRow(
                  label: 'Altitude', value: current.altitude, unit: 'm'),
              if (current.latitude != null && current.longitude != null)
                Text(
                    'Position ${formatCoordinate(current.latitude)}, ${formatCoordinate(current.longitude)}'),
              if (timestampMs != null)
                Text('Updated ${formatLastSeenAge(timestampMs!)}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
    );
  }
}

class SensorValueRow extends StatelessWidget {
  const SensorValueRow(
      {required this.label,
      required this.value,
      required this.unit,
      super.key});

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label),
        Text(unit.isEmpty
            ? formatSensorValue(value!)
            : '${formatSensorValue(value!)} $unit'),
      ],
    );
  }
}

class SensorChartCard extends StatelessWidget {
  const SensorChartCard({required this.samples, super.key});

  final List<EdgezSensorSample> samples;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Sensor time series',
      children: samples.isEmpty
          ? const <Widget>[Text('No chartable sensor values in the last hour')]
          : <Widget>[
              SizedBox(
                  height: 160,
                  child: CustomPaint(
                      painter: SensorChartPainter(
                          samples, Theme.of(context).colorScheme))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  LegendDot(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'Temperature C'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.secondary,
                      label: 'Humidity %'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.tertiary,
                      label: 'Pressure hPa'),
                  LegendDot(
                      color: Theme.of(context).colorScheme.outline,
                      label: 'Pass-by score'),
                ],
              ),
            ],
    );
  }
}

class SensorChartPainter extends CustomPainter {
  SensorChartPainter(this.samples, this.colors);

  final List<EdgezSensorSample> samples;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final border = Paint()
      ..color = colors.outlineVariant
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, border);
    final minTime = samples.first.timestampMs.toDouble();
    final maxTime = samples.last.timestampMs.toDouble();
    final values = samples.expand((sample) sync* {
      if (sample.data.temperature != null) yield sample.data.temperature!;
      if (sample.data.humidity != null) yield sample.data.humidity!;
      if (sample.data.pressure != null) yield sample.data.pressure! / 10;
      if (sample.data.vibrationAverage != null) {
        yield sample.data.vibrationAverage! * 20;
      }
    }).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    void drawSeries(
        Color color, double? Function(EdgezSensorSample sample) read) {
      final points = samples
          .map((sample) {
            final raw = read(sample);
            if (raw == null) return null;
            final x = maxTime == minTime
                ? 0.0
                : ((sample.timestampMs - minTime) / (maxTime - minTime)) *
                    size.width;
            final y = size.height -
                ((raw - minValue) /
                        ((maxValue - minValue).abs() < 0.001
                            ? 1
                            : maxValue - minValue)) *
                    size.height;
            return Offset(x, y);
          })
          .whereType<Offset>()
          .toList();
      if (points.length < 2) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      paint.color = color;
      canvas.drawPath(path, paint);
    }

    drawSeries(colors.primary, (sample) => sample.data.temperature);
    drawSeries(colors.secondary, (sample) => sample.data.humidity);
    drawSeries(
        colors.tertiary,
        (sample) =>
            sample.data.pressure == null ? null : sample.data.pressure! / 10);
    drawSeries(
        colors.outline,
        (sample) => sample.data.vibrationAverage == null
            ? null
            : sample.data.vibrationAverage! * 20);
  }

  @override
  bool shouldRepaint(covariant SensorChartPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.colors != colors;
}

class LegendDot extends StatelessWidget {
  const LegendDot({required this.color, required this.label, super.key});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
