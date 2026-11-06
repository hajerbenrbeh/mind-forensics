/// The synchronization status of a cognitive session record.
enum SyncStatus {
  /// Session is fully saved and synchronized with cloud backup.
  synced,

  /// Session has local modifications pending sync when connection is established.
  pendingSync,

  /// Session is explicitly marked to remain offline-only on this device.
  offlineOnly,
}

