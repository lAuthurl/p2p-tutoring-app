import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Wait until Amplify DataStore sync engine is ready
Future<void> waitForDataStoreReady() async {
  final completer = Completer<void>();

  final sub = Amplify.Hub.listen(HubChannel.DataStore, (event) {
    if (event.eventName == 'ready') {
      safePrint('✅ DataStore READY — Cloud sync active');
      completer.complete();
    }
  });

  await completer.future;
  await sub.cancel();
}
