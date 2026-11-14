import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_key_manager.dart';

/// Provider that checks on app start whether local encrypted records exist while
/// the hardware master encryption key is missing or inaccessible.
final masterKeyStatusProvider = FutureProvider<bool>((ref) async {
  final keyManager = ref.watch(secureKeyManagerProvider);
  try {
    await keyManager.getMasterKey();
    return true; // Key is intact
  } on MasterKeyCorruptedOrMissingException {
    return false; // Key missing while encrypted data is present -> recovery required
  } catch (_) {
    return true;
  }
});
