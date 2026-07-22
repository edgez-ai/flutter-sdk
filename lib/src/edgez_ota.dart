/// Metadata returned by the EdgeZ firmware manifest endpoint.
class EdgezOtaRelease {
  const EdgezOtaRelease({
    required this.version,
    required this.size,
    required this.url,
  });

  factory EdgezOtaRelease.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    final size = json['size'];
    final url = json['url'];
    if (version is! String || version.trim().isEmpty) {
      throw const FormatException('OTA manifest has no firmware version');
    }
    if (size is! num || size.toInt() <= 0) {
      throw const FormatException('OTA manifest has an invalid image size');
    }
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      throw const FormatException('OTA manifest has an invalid image URL');
    }
    return EdgezOtaRelease(
      version: version,
      size: size.toInt(),
      url: uri.toString(),
    );
  }

  final String version;
  final int size;
  final String url;

  /// Whether this release is newer than [currentVersion].
  bool isNewerThan(String currentVersion) {
    List<int> components(String value) => value
        .replaceFirst(RegExp('^v'), '')
        .split(RegExp(r'[.\-_]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);

    final current = components(currentVersion);
    final available = components(version);
    if (current.isEmpty || available.isEmpty) {
      return currentVersion != version;
    }
    final count =
        current.length > available.length ? current.length : available.length;
    for (var index = 0; index < count; index++) {
      final left = index < current.length ? current[index] : 0;
      final right = index < available.length ? available[index] : 0;
      if (left != right) return right > left;
    }
    return false;
  }
}
