import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({required this.nodes, required this.onBack, super.key});

  final List<EdgezMeshNode> nodes;
  final VoidCallback onBack;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => onBack(),
      child: Material(
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              EdgezOrganicMap(nodes: positionedNodes),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  onPressed: onBack,
                  tooltip: 'Close map',
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                left: 12,
                right: 72,
                bottom: 8,
                child: Text(
                  positionedNodes.isEmpty
                      ? 'No mesh nodes are sharing a location · Map data © OpenStreetMap contributors'
                      : '${positionedNodes.length} mesh nodes · Map data © OpenStreetMap contributors',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    shadows: const <Shadow>[
                      Shadow(color: Colors.white, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardMapPreview extends StatelessWidget {
  const DashboardMapPreview({
    required this.nodes,
    required this.onOpenMap,
    super.key,
  });

  final List<EdgezMeshNode> nodes;
  final VoidCallback onOpenMap;

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
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: EdgezOrganicMap(
                nodes: positionedNodes,
                enableMapDownloads: false,
                useHybridComposition: true,
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenMap,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
