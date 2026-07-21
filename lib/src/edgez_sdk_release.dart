import 'dart:typed_data';

import 'edgez_sdk_release.g.dart';

/// Private-key-signed credential attached to every HaLow initialization.
///
/// The signature is the raw 64-byte P-256 ECDSA `r || s` signature over the
/// SHA-256 digest of [signingPayload]. The private key must never be included
/// in this package.
final class EdgezSdkReleaseCredential {
  const EdgezSdkReleaseCredential({
    required this.compatibility,
    required this.releaseId,
    required this.signatureHex,
  });

  static const String signingPrefix = 'EDGEZ-FLUTTER-SDK-RELEASE-V1:';

  /// Replace this credential as part of every signed SDK release.
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
