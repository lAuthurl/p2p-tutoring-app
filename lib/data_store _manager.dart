import 'package:amplify_flutter/amplify_flutter.dart';

class DataStoreManager {
  static final DataStoreManager _instance = DataStoreManager._internal();
  factory DataStoreManager() => _instance;
  DataStoreManager._internal();

  bool _isSyncing = false;

  void init() {
    Amplify.Hub.listen(HubChannel.DataStore, (event) async {
      switch (event.eventName) {
        case 'subscriptionsEstablished':
          _isSyncing = true;
          safePrint('[DataStore] Subscriptions established');
          break;

        case 'subscriptionError':
          _isSyncing = false;
          safePrint('[DataStore] Subscription error: ${event.payload}');
          break;

        case 'networkStatus':
          final status = event.payload as NetworkStatusEvent;

          if (status.active) {
            await _tryResume();
          }
          break;

        case 'ready':
          safePrint('[DataStore] Sync ready');
          break;

        default:
          break;
      }
    });
  }

  Future<void> _tryResume() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();

      if (!session.isSignedIn) {
        safePrint('[DataStore] Not signed in — will NOT resume');
        return;
      }

      if (_isSyncing) return;

      await Amplify.DataStore.start();
      _isSyncing = true;
      safePrint('[DataStore] Sync resumed');
    } catch (e) {
      safePrint('[DataStore] Resume failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      await Amplify.DataStore.stop();
      await Amplify.DataStore.clear();
      _isSyncing = false;
      safePrint('✅ DataStore cleared');
    } catch (e) {
      safePrint('❌ Failed to clear DataStore: $e');
    }
  }
}
