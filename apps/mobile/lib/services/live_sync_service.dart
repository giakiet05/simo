import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'sync_service.dart';

/// LiveStreamStatus represents the real-time SSE streaming connection status.
enum LiveStreamStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// LiveSyncService maintains a persistent Server-Sent Events stream with the backend
/// to receive real-time change notifications, handle reconnects, and trigger delta syncs.
class LiveSyncService {
  final SyncService _syncService;
  final http.Client _httpClient;
  
  LiveStreamStatus _status = LiveStreamStatus.disconnected;
  final _statusController = StreamController<LiveStreamStatus>.broadcast();
  
  http.Client? _streamClient;
  StreamSubscription<String>? _streamSubscription;
  Timer? _reconnectTimer;
  Timer? _debounceTimer;
  int _retryCount = 0;
  bool _isPaused = false;
  VoidCallback? _onDataChangedCallback;

  LiveSyncService({
    SyncService? syncService,
    http.Client? httpClient,
  })  : _syncService = syncService ?? SyncService(),
        _httpClient = httpClient ?? http.Client();

  /// Current connection status.
  LiveStreamStatus get status => _status;

  /// Stream of connection status changes.
  Stream<LiveStreamStatus> get statusStream => _statusController.stream;

  /// Attaches a callback to invoke when a data_changed signal is received.
  void setOnDataChangedCallback(VoidCallback callback) {
    _onDataChangedCallback = callback;
  }

  void _updateStatus(LiveStreamStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Establishes the real-time SSE connection.
  Future<void> connect() async {
    if (_isPaused) return;
    if (_status == LiveStreamStatus.connected || _status == LiveStreamStatus.connecting) {
      return;
    }

    _updateStatus(_retryCount > 0 ? LiveStreamStatus.reconnecting : LiveStreamStatus.connecting);

    try {
      final token = await _syncService.getAuthToken();
      if (token.isEmpty) {
        disconnect();
        return;
      }

      final deviceId = await _syncService.getDeviceId();
      final baseUrl = await _syncService.getBaseUrl();
      final uri = Uri.parse('$baseUrl/sync/events?token=${Uri.encodeComponent(token)}&client_id=${Uri.encodeComponent(deviceId)}&platform=mobile');

      _streamClient?.close();
      _streamClient = http.Client();

      final request = http.Request('GET', uri)
        ..headers['Accept'] = 'text/event-stream'
        ..headers['Cache-Control'] = 'no-cache';

      final response = await _streamClient!.send(request);

      if (response.statusCode != 200) {
        debugPrint('[LiveSync] Failed to connect SSE stream: HTTP ${response.statusCode}');
        _scheduleReconnect();
        return;
      }

      _retryCount = 0;
      _updateStatus(LiveStreamStatus.connected);
      debugPrint('[LiveSync] SSE stream connected successfully to $baseUrl/sync/events');

      String currentEvent = 'message';
      final StringBuffer dataBuffer = StringBuffer();

      _streamSubscription?.cancel();
      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) {
            // End of an SSE event block
            if (dataBuffer.isNotEmpty) {
              _handleEvent(currentEvent, dataBuffer.toString(), deviceId);
              dataBuffer.clear();
            }
            currentEvent = 'message';
            return;
          }

          if (trimmed.startsWith(':')) {
            // Heartbeat/keep-alive comment, ignore
            return;
          }

          if (trimmed.startsWith('event:')) {
            currentEvent = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            final dataContent = trimmed.substring(5).trim();
            if (dataBuffer.isNotEmpty) {
              dataBuffer.write('\n');
            }
            dataBuffer.write(dataContent);
          }
        },
        onError: (err) {
          debugPrint('[LiveSync] Stream error: $err');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[LiveSync] Stream closed by server');
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[LiveSync] Connection exception: $e');
      _scheduleReconnect();
    }
  }

  void _handleEvent(String eventType, String rawData, String myDeviceId) {
    if (eventType == 'connected') {
      debugPrint('[LiveSync] Server acknowledged connection: $rawData');
      _retryCount = 0;
      _updateStatus(LiveStreamStatus.connected);
      return;
    }

    if (eventType == 'data_changed') {
      try {
        final payload = jsonDecode(rawData) as Map<String, dynamic>;
        final sourceClientId = payload['source_client_id'] as String?;

        // Echo suppression: Ignore notifications originating from this device
        if (sourceClientId != null && sourceClientId == myDeviceId) {
          debugPrint('[LiveSync] Suppressed echo event from self ($myDeviceId)');
          return;
        }

        debugPrint('[LiveSync] Received remote data_changed from $sourceClientId. Scheduling debounced pull...');
        _triggerDebouncedPull();
      } catch (err) {
        debugPrint('[LiveSync] Error parsing data_changed payload: $err');
      }
    }
  }

  void _triggerDebouncedPull() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_onDataChangedCallback != null) {
        _onDataChangedCallback!();
      }
    });
  }

  void _scheduleReconnect() {
    if (_isPaused) return;
    _disconnectStreamOnly();
    _updateStatus(LiveStreamStatus.reconnecting);

    if (_reconnectTimer?.isActive ?? false) return;

    // Exponential backoff: 1s, 2s, 4s, 8s, max 30s + random jitter
    final baseDelayMs = min(1000 * pow(2, _retryCount).toInt(), 30000);
    final jitterMs = Random().nextInt(1000);
    final totalDelay = Duration(milliseconds: baseDelayMs + jitterMs);
    _retryCount++;

    debugPrint('[LiveSync] Reconnecting in ${totalDelay.inMilliseconds}ms (Attempt #$_retryCount)...');
    _reconnectTimer = Timer(totalDelay, () {
      connect();
    });
  }

  /// Pauses the SSE connection (e.g. when app moves to background or device sleeps).
  void pause() {
    _isPaused = true;
    _disconnectStreamOnly();
    _updateStatus(LiveStreamStatus.disconnected);
  }

  /// Resumes the SSE connection (e.g. when app returns to foreground).
  void resume() {
    _isPaused = false;
    _retryCount = 0;
    connect();
  }

  void _disconnectStreamOnly() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamClient?.close();
    _streamClient = null;
  }

  /// Completely terminates stream and timers.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _disconnectStreamOnly();
    _updateStatus(LiveStreamStatus.disconnected);
  }

  /// Disposes all controllers and timers.
  void dispose() {
    disconnect();
    _statusController.close();
  }
}
