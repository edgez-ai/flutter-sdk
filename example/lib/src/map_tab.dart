import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({required this.nodes, super.key});

  final List<EdgezMeshNode> nodes;

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
                  ? 'No mesh nodes are currently sharing a location.'
                  : 'Showing ${positionedNodes.length} mesh nodes with shared locations.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: EdgezOrganicMap(
                  nodes: positionedNodes,
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
