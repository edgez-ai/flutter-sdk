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
    required this.dashboardDisplays,
    required this.onOpenTopology,
    required this.onRemoveNode,
    required this.onToggleDashboard,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final Map<String, ExampleDashboardDisplay> dashboardDisplays;
  final VoidCallback onOpenTopology;
  final ValueChanged<EdgezMeshNode> onRemoveNode;
  final ValueChanged<EdgezMeshNode> onToggleDashboard;
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
              TextButton.icon(
                onPressed: onOpenTopology,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Topology'),
              ),
              HaLowMeshStatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Interface: ${activeConnection.name.toUpperCase()}'),
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
                showOnDashboard:
                    dashboardDisplays[user.exampleUserId]?.showOnDashboard ??
                        false,
                onToggleDashboard: () => onToggleDashboard(user),
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

class NodeCard extends StatelessWidget {
  const NodeCard({
    required this.user,
    required this.latestSensor,
    required this.onTap,
    this.showOnDashboard,
    this.onToggleDashboard,
    super.key,
  });

  final EdgezMeshNode user;
  final EdgezSensorData? latestSensor;
  final VoidCallback onTap;
  final bool? showOnDashboard;
  final VoidCallback? onToggleDashboard;

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
                      if (onToggleDashboard != null)
                        IconButton(
                          tooltip: showOnDashboard == true
                              ? 'Remove from dashboard'
                              : 'Show on dashboard',
                          onPressed: onToggleDashboard,
                          icon: Icon(
                            showOnDashboard == true
                                ? Icons.dashboard
                                : Icons.dashboard_outlined,
                          ),
                        ),
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
