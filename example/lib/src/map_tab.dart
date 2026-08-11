import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({required this.nodes, super.key});

  final List<EdgezMeshNode> nodes;

  static const _sampleNodes = <EdgezMapNode>[
    EdgezMapNode(
      id: 'edgez-gateway',
      label: 'Gateway',
      latitude: 59.3293,
      longitude: 18.0686,
      marker: 'blue',
    ),
    EdgezMapNode(
      id: 'edgez-sensor',
      label: 'Sensor node',
      latitude: 59.3342,
      longitude: 18.0751,
      marker: 'green',
    ),
    EdgezMapNode(
      id: 'edgez-relay',
      label: 'Relay node',
      latitude: 59.3221,
      longitude: 18.0614,
      marker: 'orange',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final positionedNodes = nodes
        .where((node) => node.hasLocation)
        .map(
          (node) => EdgezMapNode(
            id: node.nodeId,
            label: node.resolvedDisplayName,
            latitude: node.latitude!,
            longitude: node.longitude!,
            marker: node.marker,
          ),
        )
        .toList(growable: false);
    final mapNodes = positionedNodes.isEmpty ? _sampleNodes : positionedNodes;
    final centerLatitude = mapNodes
            .map((node) => node.latitude)
            .reduce((left, right) => left + right) /
        mapNodes.length;
    final centerLongitude = mapNodes
            .map((node) => node.longitude)
            .reduce((left, right) => left + right) /
        mapNodes.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Offline map',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              positionedNodes.isEmpty
                  ? 'Showing 3 Stockholm sample nodes until mesh locations arrive.'
                  : 'Showing ${positionedNodes.length} mesh nodes with shared locations.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: EdgezOrganicMap(
                  nodes: mapNodes,
                  centerLatitude: centerLatitude,
                  centerLongitude: centerLongitude,
                  zoom: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Map data © OpenStreetMap contributors · Rendering by Organic Maps',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
