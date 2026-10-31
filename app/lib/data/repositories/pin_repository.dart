import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../services/key_value_store.dart';

enum PinResult { ok, wrong, locked }

const _maxWrongTries = 5;
const _lockFor = Duration(minutes: 5);

/// The co-pilot lock. Only a salted SHA-256 hash is stored, never the digits,
/// but four digits can be guessed offline: the protection is the lockout (five
/// wrong tries, five minutes, kept across restarts) and the Keystore-backed store.
class PinRepository {
  PinRepository({
    required this._store,
    this._clock = DateTime.now,
    Random? random,
  }) : _random = random ?? Random.secure();

  static const _hashKey = 'pin.hash';
  static const _triesKey = 'pin.wrongTries';
  static const _lockedUntilKey = 'pin.lockedUntil';

  final KeyValueStore _store;
  final DateTime Function() _clock;
  final Random _random;

  /// Stores [pin] as `salt:hash` and clears any lock.
  Future<void> set(String pin) async {
    final salt = base64Encode(List.generate(16, (_) => _random.nextInt(256)));
    await _store.write(_hashKey, '$salt:${_hash(salt, pin)}');
    await _clear();
  }

  Future<PinResult> verify(String pin) async {
    if (await lockedUntil() != null) return PinResult.locked;
    final stored = (await _read(_hashKey))?.split(':');
    if (stored != null && _hash(stored[0], pin) == stored[1]) {
      await _clear();
      return PinResult.ok;
    }
    final tries = (int.tryParse(await _read(_triesKey) ?? '') ?? 0) + 1;
    if (tries < _maxWrongTries) {
      await _store.write(_triesKey, '$tries');
      return PinResult.wrong;
    }
    await _store.delete(_triesKey);
    await _store.write(
      _lockedUntilKey,
      _clock().add(_lockFor).millisecondsSinceEpoch.toString(),
    );
    return PinResult.locked;
  }

  /// When the lock ends, or null if not locked.
  Future<DateTime?> lockedUntil() async {
    final raw = int.tryParse(await _read(_lockedUntilKey) ?? '');
    if (raw == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(raw);
    return until.isAfter(_clock()) ? until : null;
  }

  /// How long the lock still holds, or null if not locked.
  Future<Duration?> lockRemaining() async =>
      (await lockedUntil())?.difference(_clock());

  Future<void> reset() async {
    await _store.delete(_hashKey);
    await _clear();
  }

  Future<void> _clear() async {
    await _store.delete(_triesKey);
    await _store.delete(_lockedUntilKey);
  }

  /// A secure-storage failure reads as nothing stored (no PIN, no lock).
  Future<String?> _read(String key) async {
    try {
      return await _store.read(key);
    } on Object catch (e) {
      debugPrint('Could not read the co-pilot lock (${e.runtimeType})');
      return null;
    }
  }

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt$pin')).toString();
}
