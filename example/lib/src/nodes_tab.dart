import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

class NodesScreen extends StatelessWidget {
  const NodesScreen({
    required this.activeConnection,
    required this.status,
    required this.users,
    required this.sensorSamples,
    required this.topologyLinks,
    required this.onRemoveNode,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final List<EdgezTopologyLink> topologyLinks;
  final ValueChanged<EdgezMeshNode> onRemoveNode;
  final ValueChanged<EdgezMeshNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text('Nodes',
                      style: Theme.of(context).textTheme.headlineMedium)),
              HaLowMeshStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Interface: ${activeConnection.name.toUpperCase()}'),
          const SizedBox(height: 16),
          TopologyPanel(users: users, links: topologyLinks),
          const SizedBox(height: 16),
          Text('Discovered users / nodes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (users.isEmpty)
            const Text(
                'No beacon or discovery packets received yet. Connect BLE and save mesh settings to join the mesh.'),
          for (final user in users) ...<Widget>[
            Dismissible(
              key: ValueKey<int>(user.nodeNum),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text('Delete',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
              onDismissed: (_) => onRemoveNode(user),
              child: NodeCard(
                user: user,
                latestSensor: sensorSamples[user.nodeNum]?.lastOrNull?.data,
                onTap: () => onOpenNode(user),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class TopologyPanel extends StatelessWidget {
  const TopologyPanel({
    required this.users,
    required this.links,
    super.key,
  });

  final List<EdgezMeshNode> users;
  final List<EdgezTopologyLink> links;

  @override
  Widget build(BuildContext context) {
    final nodeIds = links
        .expand((link) => <int>[link.reporterNodeNum, link.peerNodeNum])
        .toSet()
        .toList()
      ..sort();
    final names = <int, String>{
      for (final user in users) user.nodeNum: user.resolvedDisplayName,
    };
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Mesh topology',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Graph from peer reports heard in the last 5 minutes',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _TopologyMetric(label: 'Nodes', value: '${nodeIds.length}'),
                _TopologyMetric(label: 'Links', value: '${links.length}'),
                const _TopologyMetric(label: 'Window', value: '5 min'),
              ],
            ),
            const SizedBox(height: 12),
            if (links.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                      'No recent mesh links. The graph appears when remote beacons report peers.'),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: CustomPaint(
                  painter: _TopologyPainter(
                    links: links,
                    nodeIds: nodeIds,
                    names: names,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopologyMetric extends StatelessWidget {
  const _TopologyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TopologyPainter extends CustomPainter {
  _TopologyPainter({
    required this.links,
    required this.nodeIds,
    required this.names,
    required this.colorScheme,
  });

  final List<EdgezTopologyLink> links;
  final List<int> nodeIds;
  final Map<int, String> names;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final graphRadius =
        math.min(size.width, size.height) * (nodeIds.length <= 2 ? 0.27 : 0.36);
    const nodeRadius = 24.0;
    final positions = <int, Offset>{};
    for (var index = 0; index < nodeIds.length; index++) {
      final angle = -math.pi / 2 + 2 * math.pi * index / nodeIds.length;
      positions[nodeIds[index]] = Offset(
        center.dx + graphRadius * math.cos(angle),
        center.dy + graphRadius * math.sin(angle),
      );
    }

    for (final link in links) {
      final start = positions[link.reporterNodeNum];
      final end = positions[link.peerNodeNum];
      if (start == null || end == null) continue;
      final rssi = link.rssiDbm;
      final color = rssi == null
          ? colorScheme.outline
          : rssi >= -65
              ? Colors.green.shade700
              : rssi >= -85
                  ? Colors.amber.shade800
                  : Colors.red.shade700;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      _drawLabel(
        canvas,
        midpoint,
        rssi == null ? 'RSSI unknown' : '$rssi dBm',
        colorScheme.onSurface,
        colorScheme.surface.withValues(alpha: 0.9),
        fontSize: 11,
      );
    }

    for (final entry in positions.entries) {
      canvas.drawCircle(
        entry.value,
        nodeRadius,
        Paint()..color = colorScheme.primary,
      );
      _drawLabel(
        canvas,
        entry.value,
        _nodeLabel(entry.key),
        colorScheme.onPrimary,
        Colors.transparent,
        fontSize: 10,
        maxWidth: nodeRadius * 1.8,
      );
    }
  }

  String _nodeLabel(int nodeNum) {
    final name = names[nodeNum];
    if (name != null && name.isNotEmpty) {
      return name.length > 9 ? name.substring(0, 9) : name;
    }
    final low = nodeNum & 0xffff;
    return '${(low >> 8).toRadixString(16).padLeft(2, '0')}:'
        '${(low & 0xff).toRadixString(16).padLeft(2, '0')}';
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    String text,
    Color foreground,
    Color background, {
    required double fontSize,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    final rect = Rect.fromCenter(
      center: center,
      width: painter.width + 8,
      height: painter.height + 4,
    );
    if (background.a > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = background,
      );
    }
    painter.paint(canvas, rect.topLeft + const Offset(4, 2));
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.links != links ||
        oldDelegate.nodeIds != nodeIds ||
        oldDelegate.names != names ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class NodeCard extends StatelessWidget {
  const NodeCard({
    required this.user,
    required this.latestSensor,
    required this.onTap,
    super.key,
  });

  final EdgezMeshNode user;
  final EdgezSensorData? latestSensor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = user.exampleMarker.color;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(user.resolvedDisplayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: color)),
                        Text('Node ${user.nodeId}'),
                        Text('User ${user.exampleUserId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Type ${user.exampleDeviceType.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (user.opensConversation)
                          Text('Conversation ready',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (user.exampleGeoFenceName.isNotEmpty)
                          Text('Geofence ${user.exampleGeoFenceName}',
                              style: Theme.of(context).textTheme.bodySmall),
                        if (latestSensor != null)
                          Text(_sensorSummary(latestSensor!),
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (user.sleeping)
                        Text('Sleeping',
                            style: Theme.of(context).textTheme.labelLarge),
                      Text('Last seen ${formatLastSeenAge(user.lastSeenMs)}',
                          style: Theme.of(context).textTheme.labelLarge),
                      if (user.hasLocation)
                        Icon(Icons.location_on, color: color),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: <Widget>[
                  Text(user.resolvedDisplayName.split(' ').first),
                  Text(user.route),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sensorSummary(EdgezSensorData data) {
    final parts = <String>[];
    if (data.temperature != null) {
      parts.add('${formatSensorValue(data.temperature!)} C');
    }
    if (data.humidity != null) {
      parts.add('${formatSensorValue(data.humidity!)}%');
    }
    if (data.pressure != null) {
      parts.add('${formatSensorValue(data.pressure!)} hPa');
    }
    if (data.vibrationAverage != null) {
      parts.add('score ${formatSensorValue(data.vibrationAverage!)}');
    }
    return parts.isEmpty
        ? 'Sensor data received'
        : 'Sensor ${parts.join(' · ')}';
  }
}
