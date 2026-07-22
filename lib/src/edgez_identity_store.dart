import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class EdgezIdentityStore {
  static const _keyUserUuid = 'edgez_user_uuid';
  static const _keyUserName = 'edgez_user_name';
  static const _keyPrivateKey = 'edgez_user_private_key';
  static const _keyPublicKey = 'edgez_user_public_key';
  static const _defaultUserName = 'EdgeZ User';

  Future<EdgezUserIdentity> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = prefs.getString(_keyUserUuid) ?? _newUuid();
    final name = prefs.getString(_keyUserName) ?? _defaultUserName;
    final privateKey = _decodeKey(prefs.getString(_keyPrivateKey));
    final publicKey = _decodeKey(prefs.getString(_keyPublicKey));
    if (privateKey != null && publicKey != null) {
      return EdgezUserIdentity(
        userUuid: uuid,
        userIdHigh: _uuidHigh(uuid),
        userIdLow: _uuidLow(uuid),
        name: name,
        privateKey: privateKey,
        publicKey: publicKey,
      );
    }

    final generated = _generateKeyPair();
    final identity = EdgezUserIdentity(
      userUuid: uuid,
      userIdHigh: _uuidHigh(uuid),
      userIdLow: _uuidLow(uuid),
      name: name,
      privateKey: generated.$1,
      publicKey: generated.$2,
    );
    await save(identity);
    return identity;
  }

  Future<EdgezUserIdentity> updateName(String name) async {
    final identity = await getOrCreate();
    final updated = identity.copyWith(
      name: name.trim().isEmpty ? _defaultUserName : name.trim(),
    );
    await save(updated);
    return updated;
  }

  Future<EdgezUserIdentity> regenerateKeyPair() async {
    final identity = await getOrCreate();
    final generated = _generateKeyPair();
    final updated = identity.copyWith(
      privateKey: generated.$1,
      publicKey: generated.$2,
    );
    await save(updated);
    return updated;
  }

  /// Creates an independent identity without changing the app user's stored
  /// identity. Provisioning uses this for the device profile.
  EdgezUserIdentity createIdentity({String name = 'EdgeZ Device'}) {
    final uuid = _newUuid();
    final generated = _generateKeyPair();
    return EdgezUserIdentity(
      userUuid: uuid,
      userIdHigh: _uuidHigh(uuid),
      userIdLow: _uuidLow(uuid),
      name: name.trim().isEmpty ? 'EdgeZ Device' : name.trim(),
      privateKey: generated.$1,
      publicKey: generated.$2,
    );
  }

  Future<void> save(EdgezUserIdentity identity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserUuid, identity.userUuid);
    await prefs.setString(_keyUserName, identity.name);
    await prefs.setString(_keyPrivateKey, base64Encode(identity.privateKey));
    await prefs.setString(_keyPublicKey, base64Encode(identity.publicKey));
  }

  (List<int>, List<int>) _generateKeyPair() {
    final random = Random.secure();
    final privateKey = List<int>.generate(32, (_) => random.nextInt(256));
    _clamp(privateKey);
    return (privateKey, _publicKey(privateKey));
  }

  List<int> _publicKey(List<int> privateKey) {
    final scalar = List<int>.from(privateKey);
    _clamp(scalar);
    return _scalarMult(scalar, BigInt.from(9));
  }

  void _clamp(List<int> key) {
    key[0] = key[0] & 248;
    key[31] = (key[31] & 127) | 64;
  }

  List<int> _scalarMult(List<int> scalar, BigInt pointU) {
    final p = (BigInt.one << 255) - BigInt.from(19);
    final a24 = BigInt.from(121665);
    BigInt modP(BigInt value) => value % p;
    final x1 = pointU % p;
    var x2 = BigInt.one;
    var z2 = BigInt.zero;
    var x3 = x1;
    var z3 = BigInt.one;
    var swap = 0;

    for (var t = 254; t >= 0; t--) {
      final kt = (scalar[t ~/ 8] >> (t & 7)) & 1;
      swap ^= kt;
      if (swap == 1) {
        final oldX2 = x2;
        x2 = x3;
        x3 = oldX2;
        final oldZ2 = z2;
        z2 = z3;
        z3 = oldZ2;
      }
      swap = kt;

      final a = modP(x2 + z2);
      final aa = modP(a * a);
      final b = modP(x2 - z2);
      final bb = modP(b * b);
      final e = modP(aa - bb);
      final c = modP(x3 + z3);
      final d = modP(x3 - z3);
      final da = modP(d * a);
      final cb = modP(c * b);
      x3 = modP((da + cb) * (da + cb));
      z3 = modP(x1 * modP(da - cb) * modP(da - cb));
      x2 = modP(aa * bb);
      z2 = modP(e * modP(aa + a24 * e));
    }

    if (swap == 1) {
      final oldX2 = x2;
      x2 = x3;
      x3 = oldX2;
      final oldZ2 = z2;
      z2 = z3;
      z3 = oldZ2;
    }

    return _toLittleEndian32(modP(x2 * z2.modInverse(p)));
  }

  List<int> _toLittleEndian32(BigInt value) {
    final out = Uint8List(32);
    var current = value;
    for (var index = 0; index < out.length; index++) {
      out[index] = (current & BigInt.from(0xff)).toInt();
      current = current >> 8;
    }
    return out;
  }

  List<int>? _decodeKey(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = base64Decode(encoded);
    return decoded.length == 32 ? decoded : null;
  }

  String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  int _uuidHigh(String uuid) =>
      _signed64(uuid.replaceAll('-', '').substring(0, 16));

  int _uuidLow(String uuid) =>
      _signed64(uuid.replaceAll('-', '').substring(16, 32));

  int _signed64(String hex) {
    final value = BigInt.parse(hex, radix: 16);
    final signBit = BigInt.one << 63;
    final full = BigInt.one << 64;
    return (value >= signBit ? value - full : value).toInt();
  }
}

String edgezFormatHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
