import 'dart:async';
import 'dart:math' as math;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class TopologyScreen extends StatelessWidget {
  const TopologyScreen({
    required this.users,
    required this.links,
    required this.routes,
    required this.loading,
    required this.onRefresh,
    required this.onBack,
    super.key,
  });

  final List<EdgezMeshNode> users;
  final List<EdgezTopologyLink> links;
  final List<EdgezBatmanRoute> routes;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;

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
    final directRoutes = routes.where((route) => route.isDirect).length;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: <Widget>[
          Row(
            children: <Widget>[
              TextButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mesh topology and routes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Radio observations and BATMAN forwarding state',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Radio topology',
              style: Theme.of(context).textTheme.titleMedium),
          Text(
            'Direct peers and beacons heard in the last 5 minutes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _Metric(label: 'Nodes', value: '${nodeIds.length}'),
                  _Metric(label: 'Links', value: '${links.length}'),
                  const _Metric(label: 'Window', value: '5 min'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: SizedBox(
              height: 320,
              child: links.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No recent physical mesh links. The graph appears when topology reports arrive.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
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
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'BATMAN routing table',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Current forwarding routes reported by the connected device',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh routing table',
                onPressed: loading
                    ? null
                    : () => unawaited(onRefresh().catchError((Object _) {})),
                icon: loading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _Metric(label: 'Routes', value: '${routes.length}'),
                  _Metric(label: 'Direct', value: '$directRoutes'),
                  _Metric(
                    label: 'Relayed',
                    value: '${routes.length - directRoutes}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: routes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      loading
                          ? 'Requesting routes from the device…'
                          : 'No BATMAN routes reported. Refresh after mesh peers connect.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: <Widget>[
                      for (var index = 0; index < routes.length; index++) ...[
                        if (index > 0) const Divider(height: 1),
                        _RouteTile(
                          route: routes[index],
                          destinationName:
                              names[routes[index].destinationNodeNum],
                          nextHopName: names[routes[index].nextHopNodeNum],
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.route,
    this.destinationName,
    this.nextHopName,
  });

  final EdgezBatmanRoute route;
  final String? destinationName;
  final String? nextHopName;

  @override
  Widget build(BuildContext context) {
    final destination = _formatMac(route.destinationNodeNum);
    final nextHop = _formatMac(route.nextHopNodeNum);
    final namedDestination = destinationName?.trim().isNotEmpty == true;
    final namedNextHop = nextHopName?.trim().isNotEmpty == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            namedDestination ? destinationName! : destination,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (namedDestination)
            Text(destination, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            route.isDirect
                ? 'Next hop: direct'
                : 'Next hop: ${namedNextHop ? nextHopName : nextHop}',
          ),
          if (!route.isDirect && namedNextHop)
            Text(nextHop, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <Widget>[
              Chip(
                label: Text('${route.hops} hop${route.hops == 1 ? '' : 's'}'),
              ),
              Chip(label: Text('TQ ${route.tq}/255')),
              Chip(label: Text('Age ${_formatAge(route.ageMs)}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

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
      _drawLabel(
        canvas,
        Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
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
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) => true;
}

String _formatMac(int nodeNum) {
  final hex = (nodeNum & 0xffffffffffff).toRadixString(16).padLeft(12, '0');
  return <String>[
    for (var index = 0; index < 12; index += 2) hex.substring(index, index + 2),
  ].join(':');
}

String _formatAge(int ageMs) {
  if (ageMs < 1000) return '${ageMs}ms';
  if (ageMs < 60000) return '${(ageMs / 1000).toStringAsFixed(1)}s';
  return '${(ageMs / 60000).toStringAsFixed(1)}m';
}
