import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  EdgezOrganicMapController._(int viewId)
      : _channel = MethodChannel('edgez_flutter_sdk/organic_map_$viewId');

  final MethodChannel _channel;

  Future<void> updateNodes(List<EdgezMapNode> nodes) =>
      _channel.invokeMethod<void>('updateNodes', <String, Object>{
        'nodes': nodes.map((node) => node.toMap()).toList(growable: false),
      });

  Future<void> setCamera({
    required double latitude,
    required double longitude,
    int zoom = 12,
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
/// the supplied node markers work without an internet connection.
class EdgezOrganicMap extends StatefulWidget {
  const EdgezOrganicMap({
    required this.nodes,
    this.centerLatitude = 59.3293,
    this.centerLongitude = 18.0686,
    this.zoom = 12,
    this.onMapCreated,
    super.key,
  })  : assert(centerLatitude >= -90 && centerLatitude <= 90),
        assert(centerLongitude >= -180 && centerLongitude <= 180),
        assert(zoom >= 1 && zoom <= 20);

  final List<EdgezMapNode> nodes;
  final double centerLatitude;
  final double centerLongitude;
  final int zoom;
  final ValueChanged<EdgezOrganicMapController>? onMapCreated;

  @override
  State<EdgezOrganicMap> createState() => _EdgezOrganicMapState();
}

class _EdgezOrganicMapState extends State<EdgezOrganicMap> {
  EdgezOrganicMapController? _controller;

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
      controller.setCamera(
        latitude: widget.centerLatitude,
        longitude: widget.centerLongitude,
        zoom: widget.zoom,
      );
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
    return AndroidView(
      viewType: 'edgez_flutter_sdk/organic_map',
      creationParams: <String, Object>{
        'nodes':
            widget.nodes.map((node) => node.toMap()).toList(growable: false),
        'centerLatitude': widget.centerLatitude,
        'centerLongitude': widget.centerLongitude,
        'zoom': widget.zoom,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (viewId) {
        final controller = EdgezOrganicMapController._(viewId);
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
    );
  }
}
