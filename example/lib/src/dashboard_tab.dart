import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'nodes_tab.dart';
import 'shared_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.activeConnection,
    required this.status,
    required this.users,
    required this.sensorSamples,
    required this.onOpenProvisioning,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final VoidCallback onOpenProvisioning;
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
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
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
                value: activeConnection.name.toUpperCase(),
              ),
              _DashboardValue(
                label: 'Known nodes',
                value: users.length.toString(),
              ),
              _DashboardValue(
                label: 'License',
                value: status?.licenseStatus.label ?? 'Waiting for device',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Devices and conversations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            const InfoCard(
              title: 'No dashboard devices yet',
              children: <Widget>[
                Text(
                  'Provision a device or connect to the mesh. Discovered nodes will appear here.',
                ),
              ],
            ),
          for (final user in users) ...<Widget>[
            NodeCard(
              user: user,
              latestSensor: sensorSamples[user.nodeNum]?.lastOrNull?.data,
              onTap: () => onOpenNode(user),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
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
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
