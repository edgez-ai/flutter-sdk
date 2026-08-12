import 'dart:async';

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.nodes,
    required this.camera,
    required this.onCameraChanged,
    required this.onBack,
    super.key,
  });

  final List<EdgezMeshNode> nodes;
  final EdgezMapCamera? camera;
  final ValueChanged<EdgezMapCamera> onCameraChanged;
  final VoidCallback onBack;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  EdgezOrganicMapController? _mapController;
  String? _availableRegion;
  EdgezMapDownloadUpdate? _downloadUpdate;
  EdgezMapCamera? _latestCamera;
  final Set<String> _downloadRequestedRegions = <String>{};
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _latestCamera = widget.camera;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    await _closeMap();
    return true;
  }

  Future<void> _closeMap() async {
    if (_closing) return;
    _closing = true;
    var camera = _latestCamera;
    try {
      final controller = _mapController;
      camera = controller == null
          ? camera
          : await controller.getCamera().timeout(
                    const Duration(milliseconds: 400),
                    onTimeout: () => camera,
                  ) ??
              camera;
    } on MissingPluginException {
      // Native plugin changes require a full APK rebuild instead of hot reload.
    } on PlatformException {
      // Closing the map must not depend on the native camera being available.
    } finally {
      if (camera != null) widget.onCameraChanged(camera);
      if (mounted) widget.onBack();
    }
  }

  Future<void> _checkDownloadableRegion() async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      final regionId = await controller.findDownloadableRegion();
      if (!mounted) return;
      setState(() {
        if (regionId == null) {
          _downloadUpdate = const EdgezMapDownloadUpdate(
            regionId: '',
            status:
                'Zoom in to an uncached region to download its detailed map.',
          );
        } else {
          _downloadUpdate = null;
          _availableRegion = regionId;
        }
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _downloadUpdate = const EdgezMapDownloadUpdate(
          regionId: '',
          status: 'Rebuild and reinstall the app to enable map downloads.',
          failed: true,
        );
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _downloadUpdate = EdgezMapDownloadUpdate(
          regionId: '',
          status: 'Unable to check map region: ${error.message ?? error.code}',
          failed: true,
        );
      });
    }
  }

  Future<void> _downloadRegion(String regionId) async {
    if (!_downloadRequestedRegions.add(regionId)) return;
    setState(() {
      _availableRegion = null;
      _downloadUpdate = EdgezMapDownloadUpdate(
        regionId: regionId,
        status: 'Preparing map download: $regionId',
      );
    });
    try {
      await _mapController?.downloadRegion(regionId);
    } on PlatformException catch (error) {
      _downloadRequestedRegions.remove(regionId);
      if (!mounted) return;
      setState(() {
        _downloadUpdate = EdgezMapDownloadUpdate(
          regionId: regionId,
          status: 'Map download failed: ${error.message ?? error.code}',
          failed: true,
        );
      });
    }
  }

  Future<void> _dismissRegion(String regionId) async {
    setState(() => _availableRegion = null);
    try {
      await _mapController?.dismissDownloadRegion(regionId);
    } on PlatformException {
      // Dismissing the prompt should remain a local UI operation on failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionedNodes = widget.nodes
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
      onPopInvokedWithResult: (_, __) => unawaited(_closeMap()),
      child: Material(
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              EdgezOrganicMap(
                nodes: positionedNodes,
                centerLatitude: widget.camera?.latitude,
                centerLongitude: widget.camera?.longitude,
                zoom: widget.camera?.zoom ?? 9,
                enableMapDownloads: true,
                useHybridComposition: true,
                onCameraChanged: (camera) => _latestCamera = camera,
                onMapCreated: (controller) {
                  _mapController = controller;
                  Future<void>.delayed(
                    const Duration(seconds: 1),
                    _checkDownloadableRegion,
                  );
                },
                onMapRegionAvailable: (regionId) {
                  if (!mounted) return;
                  setState(() {
                    _downloadUpdate = null;
                    _availableRegion = regionId;
                  });
                },
                onMapDownloadUpdate: (update) {
                  if (!mounted) return;
                  setState(() {
                    _availableRegion = null;
                    _downloadUpdate = update;
                  });
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  onPressed: _closeMap,
                  tooltip: 'Close map',
                  icon: const Icon(Icons.close),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: IconButton.filled(
                  onPressed: _checkDownloadableRegion,
                  tooltip: 'Download offline map',
                  icon: const Icon(Icons.download_for_offline),
                ),
              ),
              if (_downloadUpdate case final update?)
                Positioned(
                  top: 12,
                  left: 72,
                  right: 72,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(update.status),
                          if (update.progress case final progress?) ...<Widget>[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: progress),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (_availableRegion case final regionId?)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 36,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Download map: $regionId?',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text('It will be cached for offline use.'),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              FilledButton(
                                onPressed: () => _downloadRegion(regionId),
                                child: const Text('Download'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _dismissRegion(regionId),
                                child: const Text('Not now'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
    required this.camera,
    required this.onOpenMap,
    super.key,
  });

  final List<EdgezMeshNode> nodes;
  final EdgezMapCamera? camera;
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
                centerLatitude: camera?.latitude,
                centerLongitude: camera?.longitude,
                zoom: camera?.zoom ?? 9,
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
