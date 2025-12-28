import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'notification_model.dart';

@pragma('vm:entry-point')
Future<void> backgroundHandler(dynamic message) async {
  return;
}

class TNotificationService extends GetxService {
  static TNotificationService get instance => Get.find();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<NotificationModel> notifications = [];

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
  }

  Future<void> initializeNotifications() async {
    await _requestPermission();
    _initializeLocalNotifications();
  }

  Future<void> _requestPermission() async {
    if (kDebugMode) {
      print("Notification permission request skipped (migration).");
    }
  }

  static Future<String> getToken() async {
    return '';
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _localNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }

  Future<void> _showLocalNotification(dynamic message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    String? title;
    String? body;
    String payload = '';

    if (message is Map<String, dynamic>) {
      title = message['notification']?['title'] as String?;
      body = message['notification']?['body'] as String?;
      final data = message['data'] as Map<String, dynamic>?;
      if (data != null && data['route'] != null && data['id'] != null) {
        payload = '${data['route']}?id=${data['id']}';
      }
    }

    await _localNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  void addNotification(dynamic message, {String? route, String? routeId}) {
    // Build notification using message if available
    String title = 'No Title';
    String body = 'No Body';
    if (message is Map<String, dynamic>) {
      title = message['notification']?['title'] ?? title;
      body = message['notification']?['body'] ?? body;
    }

    final notification = NotificationModel(
      id: '',
      title: title,
      body: body,
      route: route ?? '',
      routeId: routeId ?? '',
      createdAt: DateTime.now(),
      seenBy: {},
      isBroadcast: false,
      type: '',
      recipientIds: [],
      senderId: '',
    );

    notifications.add(notification);

    // Show local notification
    _showLocalNotification(message);
  }

  Future<void> _onSelectNotification(NotificationResponse response) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      Get.toNamed(response.payload!);
    }
  }

  Future<void> handleInitialMessage() async {
    return;
  }
}
