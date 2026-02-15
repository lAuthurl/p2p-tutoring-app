import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionManager {
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, bool> _subscriptionStates = {};
  final Map<String, Completer<void>> _cancellationCompleters = {};
  bool _isDisposing = false;

  /// Subscribe with enhanced error handling and cancellation safety
  Future<void> subscribe<T extends Model>({
    required String subscriptionId,
    required GraphQLRequest<T> request,
    required Function(GraphQLResponse<T>) onData,
    Function(Object)? onError,
    VoidCallback? onEstablished,
  }) async {
    // Don't create new subscriptions if disposing
    if (_isDisposing) {
      safePrint('Manager is disposing, ignoring subscription request');
      return;
    }

    try {
      // Cancel existing subscription completely before creating new one
      await cancel(subscriptionId);

      // Wait to ensure cancellation is complete
      await Future.delayed(const Duration(milliseconds: 200));

      if (_isDisposing) return;

      safePrint('Setting up subscription: $subscriptionId');

      // Create the subscription stream
      final Stream<GraphQLResponse<T>> operation = Amplify.API.subscribe(
        request,
        onEstablished: () {
          if (!_isDisposing) {
            _subscriptionStates[subscriptionId] = true;
            safePrint('✅ Subscription established: $subscriptionId');
            onEstablished?.call();
          }
        },
      );

      // Listen to the stream with proper error handling
      _subscriptions[subscriptionId] = operation.listen(
        (event) {
          if (_isDisposing) return;

          if (event.hasErrors) {
            safePrint(
              '⚠️ Subscription event errors ($subscriptionId): ${event.errors}',
            );
          }

          try {
            onData(event);
          } catch (e) {
            safePrint('Error in onData callback: $e');
          }
        },
        onError: (error) {
          if (_isDisposing) return;

          safePrint('❌ Subscription error ($subscriptionId): $error');
          _subscriptionStates[subscriptionId] = false;

          if (onError != null) {
            try {
              onError(error);
            } catch (e) {
              safePrint('Error in onError callback: $e');
            }
          }
        },
        onDone: () {
          safePrint('🏁 Subscription done: $subscriptionId');
          _subscriptionStates[subscriptionId] = false;
          _subscriptions.remove(subscriptionId);
        },
        cancelOnError: false,
      );
    } catch (e) {
      safePrint('Failed to create subscription ($subscriptionId): $e');
      _subscriptionStates[subscriptionId] = false;
      // Don't rethrow - handle gracefully
    }
  }

  /// Cancel a specific subscription with proper synchronization
  Future<void> cancel(String subscriptionId) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) return;

    // Create a completer for this cancellation if it doesn't exist
    if (_cancellationCompleters.containsKey(subscriptionId)) {
      // Already canceling, wait for it
      await _cancellationCompleters[subscriptionId]!.future;
      return;
    }

    final completer = Completer<void>();
    _cancellationCompleters[subscriptionId] = completer;

    try {
      safePrint('Canceling subscription: $subscriptionId');

      // Cancel the subscription
      await subscription.cancel();

      // Clean up
      _subscriptions.remove(subscriptionId);
      _subscriptionStates.remove(subscriptionId);

      safePrint('✅ Subscription canceled: $subscriptionId');
    } catch (e) {
      safePrint('Error canceling subscription ($subscriptionId): $e');
    } finally {
      _cancellationCompleters.remove(subscriptionId);
      completer.complete();
    }
  }

  /// Cancel all subscriptions safely
  Future<void> cancelAll() async {
    if (_subscriptions.isEmpty) return;

    _isDisposing = true;

    safePrint('Canceling all subscriptions (${_subscriptions.length})');

    // Create list of subscription IDs to cancel
    final subscriptionIds = _subscriptions.keys.toList();

    // Cancel each subscription one by one to avoid race conditions
    for (final id in subscriptionIds) {
      try {
        await cancel(id);
        // Small delay between cancellations
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        safePrint('Error canceling subscription $id: $e');
      }
    }

    _subscriptions.clear();
    _subscriptionStates.clear();
    _cancellationCompleters.clear();

    safePrint('✅ All subscriptions canceled');
  }

  /// Check if subscription is active
  bool isActive(String subscriptionId) {
    return _subscriptionStates[subscriptionId] ?? false;
  }

  /// Get count of active subscriptions
  int get activeCount => _subscriptions.length;

  /// Dispose and cleanup all resources
  Future<void> dispose() async {
    safePrint('Disposing SubscriptionManager');
    await cancelAll();
    _isDisposing = false;
  }
}
