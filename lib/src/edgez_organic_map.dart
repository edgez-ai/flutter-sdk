import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A node marker displayed by [EdgezOrganicMap].
@immutable
class EdgezMapNode {
  const EdgezMapNode({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.marker = 'blue',
  })  : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  final String id;
  final String label;
  final double latitude;
  final double longitude;

  /// Organic Maps placemark color, such as blue, green, orange, or red.
  final String marker;

  Map<String, Object> toMap() => <String, Object>{
        'id': id,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'marker': marker,
      };
}

@immutable
class EdgezMapDownloadUpdate {
  const EdgezMapDownloadUpdate({
    required this.regionId,
    required this.status,
    this.progress,
    this.finished = false,
    this.failed = false,
  });

  final String regionId;
  final String status;
  final double? progress;
  final bool finished;
  final bool failed;
}

@immutable
class EdgezMapCamera {
  const EdgezMapCamera({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  })  : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180),
        assert(zoom >= 1 && zoom <= 20);

  final double latitude;
  final double longitude;
  final int zoom;
}

/// Controls an [EdgezOrganicMap] after its Android platform view is created.
class EdgezOrganicMapController {
  EdgezOrganicMapController._(
    int viewId, {
    required Future<dynamic> Function(MethodCall call) onNativeEvent,
  }) : _channel = MethodChannel('edgez_flutter_sdk/organic_map_$viewId') {
    _channel.setMethodCallHandler(onNativeEvent);
  }

  final MethodChannel _channel;

  Future<void> updateNodes(List<EdgezMapNode> nodes) =>
      _channel.invokeMethod<void>('updateNodes', <String, Object>{
        'nodes': nodes.map((node) => node.toMap()).toList(growable: false),
      });

  Future<void> downloadRegion(String regionId) =>
      _channel.invokeMethod<void>('downloadRegion', <String, Object>{
        'regionId': regionId,
      });

  Future<void> dismissDownloadRegion(String regionId) =>
      _channel.invokeMethod<void>('dismissDownloadRegion', <String, Object>{
        'regionId': regionId,
      });

  Future<EdgezMapCamera?> getCamera() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('getCamera');
    return _cameraFromMap(map);
  }

  Future<void> setCamera({
    required double latitude,
    required double longitude,
    int zoom = 9,
  }) {
    assert(latitude >= -90 && latitude <= 90);
    assert(longitude >= -180 && longitude <= 180);
    assert(zoom >= 1 && zoom <= 20);
    return _channel.invokeMethod<void>('setCamera', <String, Object>{
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
    });
  }
}

/// Native Organic Maps view backed by the EdgeZ offline Android library.
///
/// The map assets are packaged in the Android application, so rendering and
/// the supplied node markers work without an internet connection. When no
/// explicit center is supplied, the initial camera uses the device location,
/// or the first node if location permission is unavailable.
class EdgezOrganicMap extends StatefulWidget {
  const EdgezOrganicMap({
    required this.nodes,
    this.centerLatitude,
    this.centerLongitude,
    this.zoom = 9,
    this.enableMapDownloads = false,
    this.useHybridComposition = false,
    this.onMapRegionAvailable,
    this.onMapDownloadUpdate,
    this.onCameraChanged,
    this.onMapCreated,
    super.key,
  })  : assert(centerLatitude == null ||
            (centerLatitude >= -90 && centerLatitude <= 90)),
        assert(centerLongitude == null ||
            (centerLongitude >= -180 && centerLongitude <= 180)),
        assert((centerLatitude == null) == (centerLongitude == null)),
        assert(zoom >= 1 && zoom <= 20);

  final List<EdgezMapNode> nodes;
  final double? centerLatitude;
  final double? centerLongitude;
  final int zoom;

  /// Enables offline-region discovery and download events for a full map.
  /// Keep this disabled for embedded previews.
  final bool enableMapDownloads;

  /// Uses Android hybrid composition for layouts that clip or scroll the map.
  /// This is recommended for embedded dashboard previews because Organic Maps
  /// renders through a native `SurfaceView`.
  final bool useHybridComposition;
  final ValueChanged<String>? onMapRegionAvailable;
  final ValueChanged<EdgezMapDownloadUpdate>? onMapDownloadUpdate;
  final ValueChanged<EdgezMapCamera>? onCameraChanged;
  final ValueChanged<EdgezOrganicMapController>? onMapCreated;

  @override
  State<EdgezOrganicMap> createState() => _EdgezOrganicMapState();
}

class _EdgezOrganicMapState extends State<EdgezOrganicMap> {
  EdgezOrganicMapController? _controller;

  @override
  void dispose() {
    _controller?._channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<dynamic> _onNativeEvent(MethodCall call) async {
    if (!mounted) return null;
    final arguments = call.arguments;
    switch (call.method) {
      case 'mapRegionAvailable':
        final regionId = (arguments as Map?)?['regionId'] as String?;
        if (regionId != null) widget.onMapRegionAvailable?.call(regionId);
        return null;
      case 'mapDownloadProgress':
        final map = arguments as Map?;
        widget.onMapDownloadUpdate?.call(
          EdgezMapDownloadUpdate(
            regionId: map?['regionId'] as String? ?? '',
            status: map?['status'] as String? ?? 'Downloading map',
            progress: (map?['progress'] as num?)?.toDouble(),
          ),
        );
        return null;
      case 'mapDownloadFinished':
        final map = arguments as Map?;
        widget.onMapDownloadUpdate?.call(
          EdgezMapDownloadUpdate(
            regionId: map?['regionId'] as String? ?? '',
            status: map?['status'] as String? ?? 'Offline map cached',
            progress: 1,
            finished: true,
          ),
        );
        return null;
      case 'mapDownloadFailed':
        final map = arguments as Map?;
        widget.onMapDownloadUpdate?.call(
          EdgezMapDownloadUpdate(
            regionId: map?['regionId'] as String? ?? '',
            status: map?['status'] as String? ?? 'Map download failed',
            failed: true,
          ),
        );
        return null;
      case 'mapCameraChanged':
        final camera = _cameraFromMap(arguments as Map?);
        if (camera != null) widget.onCameraChanged?.call(camera);
        return null;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant EdgezOrganicMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null) return;
    if (!listEquals(oldWidget.nodes, widget.nodes)) {
      controller.updateNodes(widget.nodes);
    }
    if (oldWidget.centerLatitude != widget.centerLatitude ||
        oldWidget.centerLongitude != widget.centerLongitude ||
        oldWidget.zoom != widget.zoom) {
      final latitude = widget.centerLatitude;
      final longitude = widget.centerLongitude;
      if (latitude != null && longitude != null) {
        controller.setCamera(
          latitude: latitude,
          longitude: longitude,
          zoom: widget.zoom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const ColoredBox(
        color: Color(0xffeeeeee),
        child: Center(
          child: Text('EdgeZ Organic Maps is currently available on Android.'),
        ),
      );
    }
    final creationParams = <String, Object?>{
      'nodes': widget.nodes.map((node) => node.toMap()).toList(growable: false),
      'centerLatitude': widget.centerLatitude,
      'centerLongitude': widget.centerLongitude,
      'zoom': widget.zoom,
      'enableMapDownloads': widget.enableMapDownloads,
    };
    final mapView = _OrganicMapsAndroidView(
      creationParams: creationParams,
      useHybridComposition: widget.useHybridComposition,
      onPlatformViewCreated: (viewId) {
        final controller = EdgezOrganicMapController._(
          viewId,
          onNativeEvent: _onNativeEvent,
        );
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
    );
    return mapView;
  }
}

EdgezMapCamera? _cameraFromMap(Map? map) {
  final latitude = (map?['latitude'] as num?)?.toDouble();
  final rawLongitude = (map?['longitude'] as num?)?.toDouble();
  final rawZoom = (map?['zoom'] as num?)?.toInt();
  if (latitude == null ||
      rawLongitude == null ||
      rawZoom == null ||
      !latitude.isFinite ||
      !rawLongitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      rawZoom < 1) {
    return null;
  }
  final longitude = ((rawLongitude + 180) % 360 + 360) % 360 - 180;
  return EdgezMapCamera(
    latitude: latitude,
    longitude: longitude,
    zoom: rawZoom.clamp(1, 20),
  );
}

class _OrganicMapsAndroidView extends StatelessWidget {
  const _OrganicMapsAndroidView({
    required this.creationParams,
    required this.useHybridComposition,
    required this.onPlatformViewCreated,
  });

  final Map<String, Object?> creationParams;
  final bool useHybridComposition;
  final PlatformViewCreatedCallback onPlatformViewCreated;

  @override
  Widget build(BuildContext context) {
    const viewType = 'edgez_flutter_sdk/organic_map';
    if (!useHybridComposition) {
      return AndroidView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) {
        return PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener(onPlatformViewCreated)
          ..create();
      },
    );
  }
}
