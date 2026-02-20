import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:async';

class DataStoreManager {
  static final DataStoreManager _instance = DataStoreManager._internal();
  factory DataStoreManager() => _instance;
  DataStoreManager._internal();

  bool _isSyncing = false;
  Timer? _retryTimer;

  /// Listen to DataStore Hub events
  void init() {
    Amplify.Hub.listen(HubChannel.DataStore, (HubEvent event) {
      switch (event.eventName) {
        case 'networkStatus':
          final status = event.payload as NetworkStatusEvent;
          if (status.active) _resumeSync();
          break;

        case 'subscriptionsEstablished':
          _isSyncing = true;
          _retryTimer?.cancel();
          safePrint('[DataStore] Subscription established');
          break;

        case 'subscriptionError':
          _isSyncing = false;
          safePrint('[DataStore] Subscription failed: ${event.payload}');
          _scheduleRetry();
          break;

        case 'ready':
          safePrint('[DataStore] Sync engine ready');
          break;

        default:
          safePrint('[DataStore] Event: ${event.eventName}');
      }
    });
  }

  /// Resume DataStore sync
  void _resumeSync() async {
    if (_isSyncing) return;
    try {
      safePrint('[DataStore] Attempting to resume sync...');
      await Amplify.DataStore.start();
      _isSyncing = true;
      safePrint('[DataStore] Sync resumed successfully');
    } catch (e) {
      safePrint('[DataStore] Failed to resume sync: $e');
      _scheduleRetry();
    }
  }

  /// Retry mechanism
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isSyncing) {
        safePrint('[DataStore] Retrying sync...');
        _resumeSync();
      } else {
        _retryTimer?.cancel();
      }
    });
  }

  /// Dispose retry timer
  void dispose() {
    _retryTimer?.cancel();
  }

  /// Clear all local DataStore
  Future<void> clear() async {
    try {
      await Amplify.DataStore.clear();
      _isSyncing = false;
      _retryTimer?.cancel();
      safePrint('✅ DataStore cleared successfully');
    } catch (e) {
      safePrint('❌ Failed to clear DataStore: $e');
    }
  }
}
