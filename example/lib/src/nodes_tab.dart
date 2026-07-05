import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'shared_widgets.dart';

class NodesScreen extends StatelessWidget {
  const NodesScreen({
    required this.activeConnection,
    required this.status,
    required this.users,
    required this.onRemoveNode,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<ExampleNode> users;
  final ValueChanged<ExampleNode> onRemoveNode;
  final ValueChanged<ExampleNode> onOpenNode;

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
          Text('Users / Nodes', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (users.isEmpty) const Text('No HaLow users seen yet'),
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
              child: NodeCard(user: user, onTap: () => onOpenNode(user)),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class NodeCard extends StatelessWidget {
  const NodeCard({required this.user, required this.onTap, super.key});

  final ExampleNode user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = user.marker.color;
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
                        Text(user.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: color)),
                        Text('Node ${user.nodeId}'),
                        Text('User ${user.userId}',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Type ${user.deviceType.label}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (user.geoFence != null)
                          Text('Geofence ${user.geoFence!.name}',
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
                      Text(
                          'Last seen ${formatLastSeenAge(user.meshNode.lastSeenMs)}',
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
                  Text(user.displayName.split(' ').first),
                  Text(user.route),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
