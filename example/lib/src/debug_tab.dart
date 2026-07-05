import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final status = meshStatus;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('Debug',
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              HaLowMeshStatusIcon(status: status),
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
