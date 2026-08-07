import 'dart:math';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'example_database.dart';
import 'shared_widgets.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({
    required this.activeConnection,
    required this.meshStatus,
    required this.statusLine,
    required this.nodeCount,
    required this.conversationCount,
    required this.shareLocation,
    required this.deviceModeEnabled,
    required this.databaseReady,
    required this.speedMetrics,
    required this.onClose,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? meshStatus;
  final String statusLine;
  final int nodeCount;
  final int conversationCount;
  final bool shareLocation;
  final bool deviceModeEnabled;
  final bool databaseReady;
  final List<ExampleSpeedMetric> speedMetrics;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final status = meshStatus;
    return SafeArea(
      child: ListView(
        cacheExtent: 2400,
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onClose,
                tooltip: 'Back to settings',
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Debug',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              HaLowMeshStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Speed and loss · last 30 minutes',
            children: <Widget>[
              if (speedMetrics.isEmpty)
                const Text('No completed speed tests in this time window.')
              else ...<Widget>[
                DebugValue(
                  label: 'Moving speed',
                  value: _formatBitRate(speedMetrics.last.bitsPerSecond),
                ),
                DebugValue(
                  label: 'Moving loss',
                  value:
                      '${speedMetrics.last.packetLossPercent.toStringAsFixed(2)}%',
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    _ChartLegend(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'Speed',
                    ),
                    const SizedBox(width: 16),
                    _ChartLegend(
                      color: Theme.of(context).colorScheme.tertiary,
                      label: 'Loss',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SpeedHistoryPainter(
                      metrics: speedMetrics,
                      speedColor: Theme.of(context).colorScheme.primary,
                      lossColor: Theme.of(context).colorScheme.tertiary,
                      gridColor: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                Text(
                  '${speedMetrics.length} completed test${speedMetrics.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'Transport',
            children: <Widget>[
              DebugValue(
                  label: 'Active connection',
                  value: activeConnection.name.toUpperCase()),
              DebugValue(
                  label: 'Status',
                  value: statusLine.isEmpty ? 'No status' : statusLine),
              DebugValue(label: 'Known nodes', value: nodeCount.toString()),
              DebugValue(
                  label: 'Conversations', value: conversationCount.toString()),
              DebugValue(
                  label: 'Share location',
                  value: shareLocation ? 'Enabled' : 'Disabled'),
              DebugValue(
                  label: 'Device mode',
                  value: deviceModeEnabled ? 'Enabled' : 'Disabled'),
              DebugValue(
                  label: 'SQLite',
                  value: databaseReady ? 'Enabled' : 'Memory only'),
            ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'HaLow mesh',
            children: status == null
                ? const <Widget>[Text('No HaLow status received yet')]
                : <Widget>[
                    DebugValue(
                        label: 'Supported', value: status.supported.toString()),
                    DebugValue(
                        label: 'Initialized',
                        value: status.stackInitialized.toString()),
                    DebugValue(
                        label: 'Mesh mode', value: status.meshMode.toString()),
                    DebugValue(
                        label: 'Link up', value: status.linkUp.toString()),
                    DebugValue(
                        label: 'Route ready',
                        value: status.routeReady.toString()),
                    DebugValue(
                        label: 'Ready for report',
                        value: status.readyForReport.toString()),
                    DebugValue(
                        label: 'License', value: status.licenseStatus.label),
                    DebugValue(
                        label: 'Mesh ID',
                        value: status.meshId.isEmpty ? 'none' : status.meshId),
                    DebugValue(
                        label: 'IP',
                        value: status.ipAddress.isEmpty
                            ? 'none'
                            : status.ipAddress),
                    DebugValue(
                        label: 'Gateway',
                        value:
                            status.gateway.isEmpty ? 'none' : status.gateway),
                    DebugValue(
                        label: 'MAC',
                        value: status.macAddress == 0
                            ? 'none'
                            : status.macAddress.toRadixString(16)),
                  ],
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: 'SDK events',
            children: <Widget>[
              Text(
                statusLine.isEmpty
                    ? 'Events from the BLE SDK will appear here as status text.'
                    : statusLine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatBitRate(double bitsPerSecond) {
  if (bitsPerSecond >= 1000000) {
    return '${(bitsPerSecond / 1000000).toStringAsFixed(2)} Mbps';
  }
  return '${(bitsPerSecond / 1000).toStringAsFixed(1)} kbps';
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(width: 14, height: 3, color: color),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SpeedHistoryPainter extends CustomPainter {
  const _SpeedHistoryPainter({
    required this.metrics,
    required this.speedColor,
    required this.lossColor,
    required this.gridColor,
  });

  final List<ExampleSpeedMetric> metrics;
  final Color speedColor;
  final Color lossColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 4, size.width, size.height - 12);
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var line = 0; line <= 4; line++) {
      final y = bounds.top + bounds.height * line / 4;
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), grid);
    }
    if (metrics.isEmpty) return;
    final maxSpeed = metrics.fold<double>(
      1,
      (maximum, item) => max(maximum, item.bitsPerSecond),
    );
    final endMs = DateTime.now().millisecondsSinceEpoch;
    final startMs = endMs - const Duration(minutes: 30).inMilliseconds;

    Path pathFor(double Function(ExampleSpeedMetric metric) normalizedValue) {
      final path = Path();
      for (var index = 0; index < metrics.length; index++) {
        final metric = metrics[index];
        final xFraction = ((metric.timestampMs - startMs) / (endMs - startMs))
            .clamp(0.0, 1.0);
        final yFraction = normalizedValue(metric).clamp(0.0, 1.0);
        final point = Offset(
          bounds.left + bounds.width * xFraction,
          bounds.bottom - bounds.height * yFraction,
        );
        if (index == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    final speedPaint = Paint()
      ..color = speedColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final lossPaint = Paint()
      ..color = lossColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
        pathFor((item) => item.bitsPerSecond / maxSpeed), speedPaint);
    canvas.drawPath(
      pathFor((item) => item.packetLossPercent / 100),
      lossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedHistoryPainter oldDelegate) =>
      oldDelegate.metrics != metrics ||
      oldDelegate.speedColor != speedColor ||
      oldDelegate.lossColor != lossColor ||
      oldDelegate.gridColor != gridColor;
}

class DebugValue extends StatelessWidget {
  const DebugValue({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
