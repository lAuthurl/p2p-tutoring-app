import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../abstract/base_repository.dart';
import '../../services/notifications/notification_model.dart';
import '../authentication_repository/authentication_repository.dart';

class NotificationRepository
    extends TBaseRepositoryController<NotificationModel> {
  static NotificationRepository get instance => Get.find();

  final GetStorage _local = GetStorage('notifications');

  @override
  Future<String> addItem(NotificationModel item) async {
    final key = 'notifications_${item.id}';
    await _local.write(key, item.toJson());
    return item.id;
  }

  @override
  Future<List<NotificationModel>> fetchAllItems() async {
    final String currentUserId = AuthenticationRepository.instance.getUserID;
    if (currentUserId.isEmpty) return [];

    final keys = _local.getKeys();
    final notifications = <NotificationModel>[];
    for (final k in keys) {
      if (k.toString().startsWith('notifications_')) {
        final data = _local.read(k);
        if (data is Map<String, dynamic>) {
          final nm = NotificationModel.fromJson(
            data['id'] ?? '',
            Map<String, dynamic>.from(data),
          );
          if (nm.recipientIds.contains(currentUserId)) notifications.add(nm);
        }
      }
    }
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Stream<List<NotificationModel>> fetchAllItemsAsStream() {
    // Streaming not implemented for local storage fallback
    return const Stream.empty();
  }

  @override
  Future<NotificationModel> fetchSingleItem(String id) async {
    final key = 'notifications_$id';
    final data = _local.read(key);
    if (data is Map<String, dynamic>) {
      return NotificationModel.fromJson(id, Map<String, dynamic>.from(data));
    }
    return NotificationModel.empty();
  }

  @override
  Future<void> updateItem(NotificationModel item) async {
    final key = 'notifications_${item.id}';
    await _local.write(key, item.toJson());
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    final key = 'notifications_$id';
    final existing = _local.read(key);
    if (existing is Map<String, dynamic>) {
      existing.addAll(json);
      await _local.write(key, existing);
    }
  }

  @override
  Future<void> deleteItem(NotificationModel item) async {
    final key = 'notifications_${item.id}';
    await _local.remove(key);
  }

  Future<void> markNotificationAsSeen(
    String notificationId,
    String userId,
  ) async {
    final key = 'notifications_$notificationId';
    final existing = _local.read(key);
    if (existing is Map<String, dynamic>) {
      final seenBy = Map<String, bool>.from(existing['seenBy'] ?? {});
      seenBy[userId] = true;
      existing['seenBy'] = seenBy;
      existing['seenAt'] = DateTime.now();
      await _local.write(key, existing);
    }
  }
}
