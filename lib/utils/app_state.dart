// Simple state to track when data sync is complete
class AppState {
  static int _syncVersion = 0;

  static void notifySyncComplete() {
    _syncVersion++;
    print('[APP_STATE] Sync version: $_syncVersion');
  }

  static int get syncVersion => _syncVersion;
}
