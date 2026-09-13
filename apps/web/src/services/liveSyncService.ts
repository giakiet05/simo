import { getBaseUrl, getAuthToken } from './api';
import { localDb } from './db';
import { syncService } from './syncService';
import type { LiveStreamStatus } from '../types';

type StatusListener = (status: LiveStreamStatus) => void;

/**
 * LiveSyncService manages Server-Sent Events (SSE) connections for real-time live synchronization.
 * Handles auto-reconnect, echo suppression, tab focus catch-up, and debounced delta sync.
 */
class LiveSyncService {
  private eventSource: EventSource | null = null;
  private status: LiveStreamStatus = 'disconnected';
  private listeners: Set<StatusListener> = new Set();
  private reconnectTimer: number | null = null;
  private retryCount = 0;
  private debounceTimer: number | null = null;
  private isInitialized = false;

  /**
   * Initializes browser event listeners for visibility change and window focus.
   */
  public init() {
    if (this.isInitialized || typeof window === 'undefined') return;
    this.isInitialized = true;

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.handleTabResume();
      }
    });

    window.addEventListener('focus', () => {
      this.handleTabResume();
    });

    // Auto connect if auth token exists
    if (getAuthToken()) {
      this.connect();
    }
  }

  public getStatus(): LiveStreamStatus {
    return this.status;
  }

  public subscribe(listener: StatusListener): () => void {
    this.listeners.add(listener);
    listener(this.status);
    return () => this.listeners.delete(listener);
  }

  private setStatus(status: LiveStreamStatus) {
    if (this.status === status) return;
    this.status = status;
    this.listeners.forEach((l) => l(status));
    syncService.updateStreamStatus(status);
  }

  /**
   * Opens the SSE stream connection with auth token and device ID.
   */
  public connect() {
    const token = getAuthToken();
    if (!token) {
      this.disconnect();
      return;
    }

    if (this.eventSource) {
      if (this.status === 'connected' || this.status === 'connecting') {
        return;
      }
      this.disconnect();
    }

    this.setStatus(this.retryCount > 0 ? 'reconnecting' : 'connecting');

    const deviceId = localDb.getDeviceId();
    const baseUrl = getBaseUrl();
    const sseUrl = `${baseUrl}/sync/events?token=${encodeURIComponent(token)}&client_id=${encodeURIComponent(deviceId)}&platform=web`;

    try {
      this.eventSource = new EventSource(sseUrl);

      this.eventSource.addEventListener('connected', () => {
        this.retryCount = 0;
        this.setStatus('connected');
      });

      this.eventSource.addEventListener('data_changed', (e: MessageEvent) => {
        try {
          const payload = JSON.parse(e.data);
          // Echo suppression: Ignore events originating from this client
          if (payload.source_client_id && payload.source_client_id === deviceId) {
            return;
          }
          this.triggerDebouncedSync();
        } catch (err) {
          console.error('[LiveSync] Failed to parse data_changed event:', err);
        }
      });

      this.eventSource.onerror = (err) => {
        console.warn('[LiveSync] EventSource encountered error. Scheduling reconnect...', err);
        this.disconnect();
        this.scheduleReconnect();
      };
    } catch (err) {
      console.error('[LiveSync] Failed to initialize EventSource:', err);
      this.scheduleReconnect();
    }
  }

  /**
   * Schedules reconnection with exponential backoff and jitter.
   */
  private scheduleReconnect() {
    if (this.reconnectTimer) return;
    this.setStatus('reconnecting');

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    const baseDelay = Math.min(1000 * Math.pow(2, this.retryCount), 30000);
    const jitter = Math.random() * 1000;
    const delay = baseDelay + jitter;
    this.retryCount++;

    this.reconnectTimer = window.setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, delay);
  }

  /**
   * Triggers a debounced delta sync when receiving a data_changed event.
   */
  private triggerDebouncedSync(delayMs = 300) {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = window.setTimeout(() => {
      syncService.syncNow().catch((err) => {
        console.warn('[LiveSync] Debounced pull failed:', err);
      });
    }, delayMs);
  }

  /**
   * Handles user returning to tab: triggers delta catch-up sync and reconnects if dropped.
   */
  private handleTabResume() {
    const token = getAuthToken();
    if (!token) return;

    if (this.status !== 'connected') {
      this.connect();
    } else {
      // Catch up with any changes that occurred while tab was inactive
      syncService.syncNow().catch((err) => {
        console.warn('[LiveSync] Tab resume catch-up sync failed:', err);
      });
    }
  }

  /**
   * Closes the SSE connection and clears timers.
   */
  public disconnect() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }
    this.setStatus('disconnected');
  }
}

export const liveSyncService = new LiveSyncService();
