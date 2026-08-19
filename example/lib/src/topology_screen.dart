import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class TopologyScreen extends StatelessWidget {
  const TopologyScreen({
    required this.users,
    required this.routes,
    required this.loading,
    required this.onRefresh,
    required this.onBack,
    super.key,
  });

  final List<EdgezMeshNode> users;
  final List<EdgezBatmanRoute> routes;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final names = <int, String>{
      for (final user in users) user.nodeNum: user.resolvedDisplayName,
    };
    final directRoutes = routes.where((route) => route.isDirect).length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
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
                        'BATMAN routing table',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Current routes reported by the connected device',
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
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _RouteMetric(label: 'Routes', value: '${routes.length}'),
                    _RouteMetric(label: 'Direct', value: '$directRoutes'),
                    _RouteMetric(
                      label: 'Relayed',
                      value: '${routes.length - directRoutes}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: routes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            loading
                                ? 'Requesting routes from the device…'
                                : 'No BATMAN routes reported. Refresh after mesh peers connect.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: routes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return _RouteTile(
                            route: route,
                            destinationName: names[route.destinationNodeNum],
                            nextHopName: names[route.nextHopNodeNum],
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
            style: Theme.of(context).textTheme.bodyMedium,
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

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({required this.label, required this.value});

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
