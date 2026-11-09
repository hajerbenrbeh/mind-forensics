import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';

/// Custom exception thrown when decryption or authentication validation fails.
class DecryptionSecurityException implements Exception {
  const DecryptionSecurityException(this.message);
  final String message;

  @override
  String toString() => 'DecryptionSecurityException: $message';
}

/// Production Authenticated Encryption Cipher using AES-256-GCM.
///
/// Features:
/// - Authenticated Encryption with Associated Data (AEAD) via AES-GCM (256-bit key)
/// - Unique cryptographically secure 96-bit (12-byte) nonce for EVERY encryption operation
/// - 128-bit MAC authentication tag to detect any tampering or bit-flipping
/// - String serialization format: enc:v1${nonceB64Url}${cipherTextB64Url}${macB64Url}
class LocalDataCipher {
  LocalDataCipher({required this.secretKeyBytes})
      : _algorithm = AesGcm.with256bits();

  final List<int> secretKeyBytes;
  final AesGcm _algorithm;

  static const String prefixV1 = 'enc:v1\$';

  /// Returns true if [payload] is encrypted under the [prefixV1] format.
  static bool isEncrypted(String? payload) {
    if (payload == null) return false;
    return payload.startsWith(prefixV1);
  }

  /// Encrypts UTF-8 [plaintext] using a unique nonce under AES-256-GCM.
  Future<String> encryptString(String plaintext) async {
    final secretKey = SecretKey(secretKeyBytes);
    final nonce = _algorithm.newNonce();
    final clearBytes = utf8.encode(plaintext);

    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: secretKey,
      nonce: nonce,
    );

    final nonceB64 = base64Url.encode(secretBox.nonce);
    final cipherB64 = base64Url.encode(secretBox.cipherText);
    final macB64 = base64Url.encode(secretBox.mac.bytes);

    return '$prefixV1$nonceB64\$$cipherB64\$$macB64';
  }

  /// Decrypts and authenticates an [encryptedPayload] string.
  /// Throws [DecryptionSecurityException] if ciphertext was tampered or key is wrong.
  Future<String> decryptString(String encryptedPayload) async {
    if (!isEncrypted(encryptedPayload)) {
      throw const DecryptionSecurityException('Payload is not encrypted with enc:v1 header');
    }

    final raw = encryptedPayload.substring(prefixV1.length);
    final parts = raw.split('\$');
    if (parts.length != 3) {
      throw const DecryptionSecurityException('Malformed ciphertext format: expected 3 segments');
    }

    try {
      final nonce = base64Url.decode(parts[0]);
      final cipherText = base64Url.decode(parts[1]);
      final macBytes = base64Url.decode(parts[2]);

      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      final secretKey = SecretKey(secretKeyBytes);
      final clearBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return utf8.decode(clearBytes);
    } catch (e) {
      if (e is DecryptionSecurityException) rethrow;
      throw DecryptionSecurityException('Tampered ciphertext, invalid MAC, or key mismatch: $e');
    }
  }

  /// Generates a fresh 256-bit (32-byte) cryptographically secure random key.
  static List<int> generateRandom256BitKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}
