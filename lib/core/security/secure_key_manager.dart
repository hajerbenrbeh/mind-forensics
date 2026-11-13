import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_data_cipher.dart';

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

  Future<void> _writeSecure(String key, String value) async {
    _memoryFallbackStore[key] = value;
    if (_isTestEnvironment) return;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
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
