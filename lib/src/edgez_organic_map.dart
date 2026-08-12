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
    this.enableMapDownloads = true,
    this.useHybridComposition = false,
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
  final bool enableMapDownloads;

  /// Uses Android hybrid composition for layouts that clip or scroll the map.
  /// This is recommended for embedded dashboard previews because Organic Maps
  /// renders through a native `SurfaceView`.
  final bool useHybridComposition;
  final ValueChanged<EdgezOrganicMapController>? onMapCreated;

  @override
  State<EdgezOrganicMap> createState() => _EdgezOrganicMapState();
}

class _EdgezOrganicMapState extends State<EdgezOrganicMap> {
  EdgezOrganicMapController? _controller;
  String? _availableRegion;
  String? _downloadStatus;
  double? _downloadProgress;

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
        setState(() {
          _availableRegion = (arguments as Map?)?['regionId'] as String?;
        });
        return null;
      case 'mapDownloadProgress':
        final map = arguments as Map?;
        setState(() {
          _availableRegion = null;
          _downloadStatus = map?['status'] as String?;
          _downloadProgress = (map?['progress'] as num?)?.toDouble();
        });
        return null;
      case 'mapDownloadFinished':
        setState(() {
          _availableRegion = null;
          _downloadStatus = (arguments as Map?)?['status'] as String?;
          _downloadProgress = 1;
        });
        return null;
      case 'mapDownloadFailed':
        setState(() {
          _downloadStatus = (arguments as Map?)?['status'] as String?;
          _downloadProgress = null;
        });
        return null;
    }
    return null;
  }

  void _downloadAvailableRegion() {
    final region = _availableRegion;
    if (region == null) return;
    setState(() {
      _availableRegion = null;
      _downloadStatus = 'Preparing map download: $region';
      _downloadProgress = null;
    });
    _controller?.downloadRegion(region);
  }

  void _dismissAvailableRegion() {
    final region = _availableRegion;
    if (region == null) return;
    setState(() => _availableRegion = null);
    _controller?.dismissDownloadRegion(region);
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
    if (!widget.enableMapDownloads) return mapView;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        mapView,
        if (_downloadStatus case final status?)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(status),
                    if (_downloadProgress case final progress?) ...<Widget>[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (_availableRegion case final region?)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Download map: $region?',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    const Text('It will be cached for offline use.'),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        FilledButton(
                          onPressed: _downloadAvailableRegion,
                          child: const Text('Download'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _dismissAvailableRegion,
                          child: const Text('Not now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
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
