import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkChecker {
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return Connectivity().onConnectivityChanged;
  }
}

class YourWidget extends StatefulWidget {
  const YourWidget({super.key});

  @override
  YourWidgetState createState() => YourWidgetState();
}

class YourWidgetState extends State<YourWidget> {
  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  Future<void> _setupSubscriptions() async {
    final isConnected = await NetworkChecker.isConnected();
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No internet connection')));
      }
      return;
    }
    await _subscribeToCreate();
    await _subscribeToUpdate();
    await _subscribeToDelete();
  }

  Future<void> _subscribeToCreate() async {
    // Your implementation for subscribe to create
  }

  Future<void> _subscribeToUpdate() async {
    // Your implementation for subscribe to update
  }

  Future<void> _subscribeToDelete() async {
    // Your implementation for subscribe to delete
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
