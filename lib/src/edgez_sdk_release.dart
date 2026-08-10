import 'dart:typed_data';

import 'edgez_sdk_release.g.dart';

/// Release metadata attached to every HaLow initialization.
///
/// [signatureHex] is empty in current releases because firmware no longer
/// validates an SDK license signature. Non-empty legacy credentials remain
/// supported for wire compatibility.
final class EdgezSdkReleaseCredential {
  const EdgezSdkReleaseCredential({
    required this.compatibility,
    required this.releaseId,
    required this.signatureHex,
  });

  static const String signingPrefix = 'EDGEZ-FLUTTER-SDK-RELEASE-V1:';

  /// Updated as part of every SDK release.
  static const EdgezSdkReleaseCredential current = EdgezSdkReleaseCredential(
    compatibility: edgezSdkCompatibility,
    releaseId: edgezSdkReleaseId,
    signatureHex: edgezSdkReleaseSignatureHex,
  );

  final String compatibility;
  final String releaseId;
  final String signatureHex;

  String get signingPayload => '$signingPrefix$compatibility:$releaseId';

  Uint8List get signature {
    if (compatibility.isEmpty || compatibility.length > 32) {
      throw StateError('EdgeZ SDK compatibility must contain 1-32 characters');
    }
    if (releaseId.isEmpty || releaseId.length > 32) {
      throw StateError('EdgeZ SDK release ID must contain 1-32 characters');
    }
    // Firmware no longer validates the SDK release signature. Keep the field
    // in the wire format for compatibility, but send an empty byte string.
    if (signatureHex.isEmpty) return Uint8List(0);
    if (signatureHex.length != 128 ||
        !RegExp(r'^[0-9a-fA-F]{128}$').hasMatch(signatureHex)) {
      throw StateError(
        'EdgeZ SDK release signature must be a 64-byte raw P-256 r||s value',
      );
    }
    return Uint8List.fromList(<int>[
      for (var offset = 0; offset < signatureHex.length; offset += 2)
        int.parse(signatureHex.substring(offset, offset + 2), radix: 16),
    ]);
  }
}
