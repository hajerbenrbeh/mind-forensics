import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_data_cipher.dart';

/// Result codes for [SecureKeyManager.restoreMasterKeyFromRecovery].
enum MasterKeyRestoreResult {
  /// Key was decoded and written successfully.
  success,

  /// The recovery key string was invalid (wrong length, non-hex, or parse failure).
  invalidFormat,

  /// A valid master key already exists AND encrypted user data is present.
  /// The caller must show a user-visible confirmation dialog and pass forceOverwrite: true
  /// to proceed. This state prevents silent permanent data loss.
  existingKeyWithData,

  /// A valid master key already exists but no encrypted data was detected.
  /// The caller may pass forceOverwrite: true safely, but should still confirm with the user.
  existingKeyNoData,

  /// Platform secure storage is inaccessible or locked (e.g. Keystore error).
  secureStorageUnavailable,
}

/// Thrown when encrypted data exists on device, but the master key is missing
/// from secure storage. A fresh replacement key is NEVER silently generated.
class MasterKeyCorruptedOrMissingException implements Exception {
  const MasterKeyCorruptedOrMissingException([
    this.message = 'Master key is missing from secure storage while encrypted data is present.',
  ]);

  final String message;

  @override
  String toString() => 'MasterKeyCorruptedOrMissingException: $message';
}

/// Central Secure Key and Platform Storage Coordinator.
///
/// Manages:
/// - Hardware-backed platform storage via Android Keystore & iOS Keychain
/// - Generation and safe storage of the 256-bit Master Storage Key
/// - Cryptographic subkey derivation per-user partition using HMAC-SHA256
/// - Secure storage and migration of the Gemini API Key
class SecureKeyManager {
  SecureKeyManager({
    FlutterSecureStorage? secureStorage,
  }) : _storage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  final FlutterSecureStorage _storage;

  static const String keyMasterStorage = 'mf_master_storage_key_v1';
  static const String keySecureGeminiApi = 'mf_secure_gemini_api_key';
  static const String keySecureGroqApi = 'mf_secure_groq_api_key';
  static const String legacyPrefGeminiKey = 'mf_gemini_api_key';

  static final Map<String, String> _memoryFallbackStore = {};
  static List<int>? _staticMasterKey;

  static bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  List<int>? _cachedMasterKey;

  @visibleForTesting
  static void resetStaticCache() {
    _staticMasterKey = null;
    _memoryFallbackStore.clear();
  }

  Future<String?> _readSecure(String key) async {
    if (_isTestEnvironment) {
      return _memoryFallbackStore[key];
    }
    try {
      final val = await _storage.read(key: key);
      if (val != null) {
        _memoryFallbackStore[key] = val;
        return val;
      }
    } catch (_) {}
    return _memoryFallbackStore[key];
  }

  Future<bool> _writeSecure(String key, String value) async {
    _memoryFallbackStore[key] = value;
    if (_isTestEnvironment) return true;
    try {
      await _storage.write(key: key, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteSecure(String key) async {
    _memoryFallbackStore.remove(key);
    if (_isTestEnvironment) return;
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Retrieves or initializes the 256-bit Master Encryption Key from platform secure storage.
  Future<List<int>> getMasterKey() async {
    if (_cachedMasterKey != null) return _cachedMasterKey!;
    if (_staticMasterKey != null) {
      _cachedMasterKey = _staticMasterKey;
      return _staticMasterKey!;
    }

    try {
      final storedB64 = await _readSecure(keyMasterStorage);
      if (storedB64 != null && storedB64.isNotEmpty) {
        final keyBytes = base64Url.decode(storedB64);
        if (keyBytes.length == 32) {
          _cachedMasterKey = keyBytes;
          _staticMasterKey = keyBytes;
          return keyBytes;
        }
      }
    } catch (_) {}

    // If encrypted user data exists on this device, NEVER silently generate a replacement key,
    // as that would permanently orphan existing encrypted records.
    final hasData = await hasEncryptedDataOnDevice();
    if (hasData) {
      throw const MasterKeyCorruptedOrMissingException(
        'Encrypted clinical data was detected on device, but the master encryption key is missing or inaccessible in secure storage. '
        'A fresh master key cannot be silently generated because doing so would permanently orphan existing encrypted records. '
        'Restore the master key using your recovery key.',
      );
    }

    // Generate new CSPRNG 256-bit key and persist to platform secure storage
    final freshKey = LocalDataCipher.generateRandom256BitKey();
    final freshB64 = base64Url.encode(freshKey);
    await _writeSecure(keyMasterStorage, freshB64);

    _cachedMasterKey = freshKey;
    _staticMasterKey = freshKey;
    return freshKey;
  }

  /// Derives a cryptographically isolated 256-bit AES-GCM cipher for a specific [userId].
  Future<LocalDataCipher> getCipherForUser([String? userId]) async {
    final masterKey = await getMasterKey();
    final effectiveId = (userId != null &&
            userId.trim().isNotEmpty &&
            userId.trim() != 'local_user' &&
            userId.trim() != 'anonymous_local_vault')
        ? userId.trim()
        : 'anonymous_local_vault';
    
    // Key Derivation: Derive 256-bit subkey via HMAC-SHA256(masterKey, "user_partition:$effectiveId")
    final hmac = Hmac(sha256, masterKey);
    final derivedKeyBytes = hmac.convert(utf8.encode('user_partition:$effectiveId')).bytes;
    return LocalDataCipher(secretKeyBytes: derivedKeyBytes);
  }

  /// Migrates and reads the Gemini Developer API Key from platform secure storage.
  /// Automatically pulls legacy key from SharedPreferences and purges it once migrated.
  Future<String> getGeminiApiKey() async {
    try {
      final secureKey = await _readSecure(keySecureGeminiApi);
      if (secureKey != null && secureKey.trim().isNotEmpty) {
        return secureKey.trim();
      }
    } catch (_) {}

    // Check legacy SharedPreferences slot for backward-compatibility
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = prefs.getString(legacyPrefGeminiKey)?.trim();
    if (legacyKey != null && legacyKey.isNotEmpty && legacyKey != 'DEV_MOCK_GEMINI_KEY') {
      try {
        await _writeSecure(keySecureGeminiApi, legacyKey);
        await prefs.remove(legacyPrefGeminiKey); // Purge plaintext copy
      } catch (_) {}
      return legacyKey;
    }

    return '';
  }

  /// Securely saves the Gemini Developer API Key to platform secure storage.
  Future<void> saveGeminiApiKey(String apiKey) async {
    final clean = apiKey.trim();
    final prefs = await SharedPreferences.getInstance();

    if (clean.isNotEmpty && clean != 'DEV_MOCK_GEMINI_KEY') {
      await _writeSecure(keySecureGeminiApi, clean);
      await prefs.remove(legacyPrefGeminiKey); // Ensure plaintext is removed
    } else {
      await _deleteSecure(keySecureGeminiApi);
      await prefs.remove(legacyPrefGeminiKey);
    }
  }

  /// Clears the Gemini Developer API Key from secure storage.
  Future<void> clearGeminiApiKey() async {
    await _deleteSecure(keySecureGeminiApi);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyPrefGeminiKey);
  }

  /// Reads the Groq / OpenAI-compatible API Key from platform secure storage.
  Future<String> getGroqApiKey() async {
    try {
      final secureKey = await _readSecure(keySecureGroqApi);
      if (secureKey != null && secureKey.trim().isNotEmpty) {
        return secureKey.trim();
      }
    } catch (_) {}
    return '';
  }

  /// Securely saves the Groq API Key to platform secure storage.
  Future<void> saveGroqApiKey(String apiKey) async {
    final clean = apiKey.trim();
    if (clean.isNotEmpty && clean != 'DEV_MOCK_GEMINI_KEY') {
      await _writeSecure(keySecureGroqApi, clean);
    } else {
      await _deleteSecure(keySecureGroqApi);
    }
  }

  /// Clears the Groq API Key from secure storage.
  Future<void> clearGroqApiKey() async {
    await _deleteSecure(keySecureGroqApi);
  }

  /// Exports the 256-bit Master Storage Key as a standardized uppercase hex string.
  Future<String> exportMasterRecoveryKey() async {
    final keyBytes = await getMasterKey();
    return keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  /// Returns true if encrypted user data exists in SharedPreferences under any known
  /// Mind Forensics storage namespace (enc:v1 prefix).
  ///
  /// Used by [restoreMasterKeyFromRecovery] and [getMasterKey] to determine whether
  /// encrypted records depend on the master key.
  Future<bool> hasEncryptedDataOnDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final k in keys) {
        try {
          final value = prefs.get(k);
          if (value is String && LocalDataCipher.isEncrypted(value)) {
            return true;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// Restores the Master Storage Key from a provided hex-encoded recovery string.
  ///
  /// Safety contract:
  /// - Accepts restoration onto an empty installation (no existing key, no encrypted data).
  /// - Accepts restoration when no key is currently stored but encrypted data IS present —
  ///   this is the legitimate recovery scenario (key lost, data intact).
  /// - Rejects restoration when a valid master key already exists AND encrypted data is
  ///   present, to prevent accidental permanent data loss. Use [forceOverwrite] only when
  ///   the caller has confirmed through an explicit user-visible dialog that the existing
  ///   key and all encrypted data should be replaced.
  ///
  /// Validates:
  /// - Exact 64 hex characters (32 bytes = 256 bits).
  /// - Successful decoding into a valid 32-byte array.
  Future<MasterKeyRestoreResult> restoreMasterKeyFromRecovery(
    String recoveryKey, {
    bool forceOverwrite = false,
  }) async {
    final clean = recoveryKey.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (clean.length != 64) {
      return MasterKeyRestoreResult.invalidFormat;
    }

    try {
      final keyBytes = <int>[];
      for (int i = 0; i < 64; i += 2) {
        keyBytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
      }
      if (keyBytes.length != 32) return MasterKeyRestoreResult.invalidFormat;

      // Check whether a usable master key already exists in storage.
      final existingStored = await _readSecure(keyMasterStorage);
      final existingKeyValid = existingStored != null &&
          existingStored.isNotEmpty &&
          base64Url.decode(existingStored).length == 32;

      if (existingKeyValid && !forceOverwrite) {
        // A valid key already exists. Refuse to silently overwrite it.
        // The caller must present a user-visible confirmation and pass forceOverwrite: true.
        final hasData = await hasEncryptedDataOnDevice();
        return hasData
            ? MasterKeyRestoreResult.existingKeyWithData
            : MasterKeyRestoreResult.existingKeyNoData;
      }

      final b64 = base64Url.encode(keyBytes);
      final persisted = await _writeSecure(keyMasterStorage, b64);
      if (!persisted) {
        return MasterKeyRestoreResult.secureStorageUnavailable;
      }
      _cachedMasterKey = keyBytes;
      _staticMasterKey = keyBytes;
      return MasterKeyRestoreResult.success;
    } catch (_) {
      return MasterKeyRestoreResult.invalidFormat;
    }
  }

  /// Purges all master keys and secrets from secure storage (e.g. factory reset).
  Future<void> wipeAllKeys() async {
    _cachedMasterKey = null;
    _staticMasterKey = null;
    _memoryFallbackStore.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}

final secureKeyManagerProvider = Provider<SecureKeyManager>((ref) {
  return SecureKeyManager();
});
