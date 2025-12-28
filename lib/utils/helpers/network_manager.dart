// Suppress a platform-dependent lint: connectivity_plus may emit either a
// single `ConnectivityResult` or a `List<ConnectivityResult>` on some
// platforms. We handle both below; ignore analyzer's unrelated-type check.
// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

import '../popups/loaders.dart';

/// Manages the network connectivity status and provides methods to check and handle connectivity changes.
class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<dynamic> _connectivitySubscription;
  final Rxn<ConnectivityResult> _connectionStatus = Rxn<ConnectivityResult>();

  /// Initialize the network manager and set up a stream to continually check the connection status.
  @override
  void onInit() {
    super.onInit();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  /// Update the connection status based on changes in connectivity and show a relevant popup for no internet connection.
  Future<void> _updateConnectionStatus(dynamic result) async {
    if (result is ConnectivityResult) {
      _connectionStatus.value = result;
      if (result == ConnectivityResult.none) {
        TLoaders.customToast(message: 'No Internet Connection');
      }
    } else if (result is List) {
      // Older or platform-specific implementations may emit a list.
      final list = result.cast<ConnectivityResult>();
      if (list.isNotEmpty) _connectionStatus.value = list.first;
      if (list.any((x) => x == ConnectivityResult.none)) {
        TLoaders.customToast(message: 'No Internet Connection');
      }
    }
  }

  /// Check the internet connection status.
  /// Returns `true` if connected, `false` otherwise.
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Dispose or close the active connectivity stream.
  @override
  void onClose() {
    super.onClose();
    _connectivitySubscription.cancel();
  }
}
