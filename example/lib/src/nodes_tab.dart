import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'settings_tab.dart' show halowFrequenciesKhz, halowFrequencyLabel;
import 'shared_widgets.dart';

class NodesScreen extends StatelessWidget {
  const NodesScreen({
    required this.activeConnection,
    required this.status,
    required this.meshCountry,
    required this.meshBandwidthMhz,
    required this.meshFrequencyKhz,
    required this.users,
    required this.sensorSamples,
    required this.dashboardDisplays,
    required this.onOpenTopology,
    required this.onMeshFrequencyChanged,
    required this.onRemoveNode,
    required this.onToggleDashboard,
    required this.onTogglePublicChannel,
    required this.onOpenNode,
    super.key,
  });

  final EdgezConnectionType activeConnection;
  final EdgezMeshStatus? status;
  final String meshCountry;
  final int meshBandwidthMhz;
  final int meshFrequencyKhz;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final Map<String, ExampleDashboardDisplay> dashboardDisplays;
  final VoidCallback onOpenTopology;
  final ValueChanged<int> onMeshFrequencyChanged;
  final ValueChanged<EdgezMeshNode> onRemoveNode;
  final ValueChanged<EdgezMeshNode> onToggleDashboard;
  final void Function(EdgezMeshNode channel, bool enabled)
      onTogglePublicChannel;
  final ValueChanged<EdgezMeshNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    final canChangeChannel = status?.isUsable == true;
    final meshFrequencies = halowFrequenciesKhz(
      meshCountry,
      meshBandwidthMhz,
    );
    final publicChannels = users.where((user) => user.isPublicChannel).toList()
      ..sort((a, b) => a.nodeNum.compareTo(b.nodeNum));
    final discoveredUsers =
        users.where((user) => !user.isPublicChannel).toList();
    final nodesByChannel = <int, List<EdgezMeshNode>>{};
    for (final user in discoveredUsers) {
      (nodesByChannel[user.channelNumber] ??= <EdgezMeshNode>[]).add(user);
    }
    final channelNumbers = nodesByChannel.keys.toList()
      ..sort((a, b) {
        if (a == 0) return 1;
        if (b == 0) return -1;
        return a.compareTo(b);
      });
    for (final nodes in nodesByChannel.values) {
      nodes.sort((a, b) => a.resolvedDisplayName
          .toLowerCase()
          .compareTo(b.resolvedDisplayName.toLowerCase()));
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Nodes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: onOpenTopology,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Routes'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: meshFrequencies.contains(meshFrequencyKhz)
                          ? meshFrequencyKhz
                          : null,
                      hint: const Text('Channel'),
                      isDense: true,
                      isExpanded: true,
                      items: meshFrequencies
                          .map(
                            (frequencyKhz) => DropdownMenuItem<int>(
                              value: frequencyKhz,
                              child: Text(
                                halowFrequencyLabel(
                                  meshCountry,
                                  frequencyKhz,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: canChangeChannel
                          ? (frequencyKhz) {
                              if (frequencyKhz != null) {
                                onMeshFrequencyChanged(frequencyKhz);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Interface: ${activeConnection.name.toUpperCase()}'),
          const SizedBox(height: 16),
          if (publicChannels.isNotEmpty)
            _PublicChannelsSection(
              channels: publicChannels,
              onTogglePublicChannel: onTogglePublicChannel,
              onOpenNode: onOpenNode,
            ),
          if (publicChannels.isNotEmpty) const SizedBox(height: 16),
          if (discoveredUsers.isEmpty)
            const Text(
                'No beacon or discovery packets received yet. Connect BLE and save mesh settings to join the mesh.'),
          for (final channelNumber in channelNumbers) ...<Widget>[
            _ChannelNodesSection(
              channelNumber: channelNumber,
              frequencyKhz: _frequencyKhzForChannel(meshCountry, channelNumber),
              users: nodesByChannel[channelNumber]!,
              sensorSamples: sensorSamples,
              dashboardDisplays: dashboardDisplays,
              onRemoveNode: onRemoveNode,
              onToggleDashboard: onToggleDashboard,
              onOpenNode: onOpenNode,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PublicChannelsSection extends StatelessWidget {
  const _PublicChannelsSection({
    required this.channels,
    required this.onTogglePublicChannel,
    required this.onOpenNode,
  });

  final List<EdgezMeshNode> channels;
  final void Function(EdgezMeshNode channel, bool enabled)
      onTogglePublicChannel;
  final ValueChanged<EdgezMeshNode> onOpenNode;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: const PageStorageKey<String>('public-channels'),
          initiallyExpanded: false,
          leading: const Icon(Icons.campaign_outlined),
          title: const Text('Public channels'),
          subtitle: Text(
              '${channels.length} ${channels.length == 1 ? 'channel' : 'channels'}'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: <Widget>[
            for (final channel in channels) ...<Widget>[
              NodeCard(
                user: channel,
                latestSensor: null,
                onEnabledChanged: (enabled) =>
                    onTogglePublicChannel(channel, enabled),
                onTap: () => onOpenNode(channel),
              ),
              if (channel != channels.last) const SizedBox(height: 8),
            ],
          ],
        ),
      );
}

class _ChannelNodesSection extends StatelessWidget {
  const _ChannelNodesSection({
    required this.channelNumber,
    required this.frequencyKhz,
    required this.users,
    required this.sensorSamples,
    required this.dashboardDisplays,
    required this.onRemoveNode,
    required this.onToggleDashboard,
    required this.onOpenNode,
  });

  final int channelNumber;
  final int? frequencyKhz;
  final List<EdgezMeshNode> users;
  final Map<int, List<EdgezSensorSample>> sensorSamples;
  final Map<String, ExampleDashboardDisplay> dashboardDisplays;
  final ValueChanged<EdgezMeshNode> onRemoveNode;
  final ValueChanged<EdgezMeshNode> onToggleDashboard;
  final ValueChanged<EdgezMeshNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    final knownChannel = channelNumber > 0;
    final frequency = frequencyKhz;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('halow-channel-$channelNumber'),
        initiallyExpanded: false,
        leading: const Icon(Icons.cell_tower_outlined),
        title:
            Text(knownChannel ? 'Channel $channelNumber' : 'Unknown channel'),
        subtitle: Text(frequency != null
            ? '${(frequency / 1000).toStringAsFixed(3)} MHz · ${users.length} ${users.length == 1 ? 'node' : 'nodes'}'
            : '${users.length} ${users.length == 1 ? 'node' : 'nodes'}'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
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
            if (user != users.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

int? _frequencyKhzForChannel(String country, int channelNumber) {
  if (channelNumber <= 0) return null;
  final baseKhz = switch (country.toUpperCase()) {
    'AU' || 'CA' || 'NZ' || 'US' => 902000,
    'EU' || 'GB' || 'IN' => 863000,
    'JP' => 916500,
    'KR' => 917500,
    _ => null,
  };
  return baseKhz == null ? null : baseKhz + channelNumber * 500;
}

class NodeCard extends StatelessWidget {
  const NodeCard({
    required this.user,
    required this.latestSensor,
    required this.onTap,
    this.showOnDashboard,
    this.onToggleDashboard,
    this.onEnabledChanged,
    super.key,
  });

  final EdgezMeshNode user;
  final EdgezSensorData? latestSensor;
  final VoidCallback onTap;
  final bool? showOnDashboard;
  final VoidCallback? onToggleDashboard;
  final ValueChanged<bool>? onEnabledChanged;

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
                        Text(user.isPublicChannel
                            ? 'Talkgroup port ${user.nodeNum}'
                            : 'Node ${user.nodeId}'),
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
                      if (onEnabledChanged != null)
                        Switch(
                          value: user.enabled,
                          onChanged: onEnabledChanged,
                        ),
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
                      if (!user.isPublicChannel)
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
