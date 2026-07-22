import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:edgez_flutter_sdk/edgez_flutter_sdk.dart';
import 'package:http/http.dart' as http;

const _marketplaceApi = 'https://www.edgez.ai/api/marketplace/items';

class MarketplaceDriverInstallRequest {
  const MarketplaceDriverInstallRequest({
    required this.itemId,
    required this.slug,
  });

  final String itemId;
  final String slug;

  static MarketplaceDriverInstallRequest? fromUri(Uri uri) {
    if (uri.scheme != 'edgez' ||
        uri.host != 'drivers' ||
        uri.path != '/install') {
      return null;
    }
    final itemId = uri.queryParameters['id']?.trim() ?? '';
    final slug = uri.queryParameters['slug']?.trim() ?? '';
    final idPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
    if (!idPattern.hasMatch(itemId) || !slugPattern.hasMatch(slug)) {
      return null;
    }
    return MarketplaceDriverInstallRequest(itemId: itemId, slug: slug);
  }
}

class MarketplaceDriverDownload {
  const MarketplaceDriverDownload({
    required this.bundle,
    required this.imageUrl,
  });

  final EdgezDriverBundle bundle;
  final Uri? imageUrl;
}

class MarketplaceDriverClient {
  MarketplaceDriverClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<MarketplaceDriverDownload> fetch(
    MarketplaceDriverInstallRequest request,
  ) async {
    final response = await _client.get(
      Uri.parse('$_marketplaceApi/${request.slug}'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Driver download failed: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const FormatException('Marketplace response is invalid');
    }
    final item = decoded.cast<String, Object?>();
    if (item['id'] != request.itemId ||
        item['slug'] != request.slug ||
        item['type'] != 'driver') {
      throw const FormatException(
        'Marketplace driver does not match the requested install link',
      );
    }
    final rawBundle = item['driverBundle'];
    if (rawBundle is! Map) {
      throw const FormatException(
        'Marketplace item does not include a driver bundle',
      );
    }
    final bundle = rawBundle.cast<String, Object?>();
    if (bundle['format'] != 'edgez-driver/v1') {
      throw const FormatException('Unsupported marketplace driver format');
    }
    final connector = switch (bundle['interface']) {
      'uart_i2c' => EdgezSensorConnector.uartI2c,
      'rs485' => EdgezSensorConnector.rs485,
      _ => throw const FormatException('Unsupported driver interface'),
    };
    final driverId = bundle['driverId'] as String? ?? '';
    final key = bundle['key'] as String? ?? '';
    final scriptId = (bundle['scriptId'] as num?)?.toInt() ?? 0;
    final version = (bundle['version'] as num?)?.toInt() ?? 0;
    final script = bundle['script'] as String? ?? '';
    if (driverId.isEmpty ||
        key.isEmpty ||
        scriptId <= 0 ||
        version <= 0 ||
        script.isEmpty) {
      throw const FormatException('Marketplace driver is incomplete');
    }
    final name = (bundle['name'] as String?)?.trim();
    final itemTitle = (item['title'] as String?)?.trim();
    final imageValue =
        (bundle['imageUrl'] as String?)?.trim().isNotEmpty == true
            ? bundle['imageUrl'] as String
            : item['snapshotImageUrl'] as String? ?? '';
    final imageUri = Uri.tryParse(imageValue);
    if (imageUri != null && imageUri.scheme != 'https') {
      throw const FormatException('Driver image must use HTTPS');
    }
    return MarketplaceDriverDownload(
      bundle: EdgezDriverBundle(
        driverId: driverId,
        key: key,
        scriptId: scriptId,
        version: version,
        name: name?.isNotEmpty == true
            ? name!
            : itemTitle?.isNotEmpty == true
                ? itemTitle!
                : request.slug,
        connector: connector,
        script: script,
        description: bundle['description'] as String? ?? '',
        globalBufferSize: (bundle['globalBufferSize'] as num?)?.toInt() ?? 4096,
        marketplaceItemId: request.itemId,
        marketplaceSlug: request.slug,
      ),
      imageUrl: imageUri?.hasAuthority == true ? imageUri : null,
    );
  }

  Future<Uint8List?> downloadImage(Uri? uri) async {
    if (uri == null) return null;
    if (uri.scheme != 'https') {
      throw const FormatException('Driver image must use HTTPS');
    }
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Driver image download failed: HTTP ${response.statusCode}',
      );
    }
    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw const FormatException('Downloaded driver image is empty');
    }
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } catch (_) {
      throw const FormatException('Downloaded driver image is invalid');
    } finally {
      codec?.dispose();
    }
    return bytes;
  }

  void close() => _client.close();
}
