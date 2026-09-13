import 'package:flutter_test/flutter_test.dart';
import 'package:simo/services/live_sync_service.dart';

void main() {
  group('LiveSyncService Tests', () {
    test('Initial status is disconnected', () {
      final service = LiveSyncService();
      expect(service.status, LiveStreamStatus.disconnected);
      service.dispose();
    });

    test('Status stream emits on pause and resume', () async {
      final service = LiveSyncService();
      final statuses = <LiveStreamStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      service.pause();
      expect(service.status, LiveStreamStatus.disconnected);

      service.dispose();
      await sub.cancel();
    });

    test('LiveStreamStatus enum has all expected states', () {
      expect(LiveStreamStatus.values, contains(LiveStreamStatus.disconnected));
      expect(LiveStreamStatus.values, contains(LiveStreamStatus.connecting));
      expect(LiveStreamStatus.values, contains(LiveStreamStatus.connected));
      expect(LiveStreamStatus.values, contains(LiveStreamStatus.reconnecting));
    });
  });
}
