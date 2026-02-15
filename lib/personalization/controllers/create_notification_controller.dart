import 'package:get/get.dart';

import '../../../../routes/routes.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../data/repository/notifications/notification_repository.dart';
import '../../data/services/notifications/notification_model.dart';
import '../../utils/helpers/network_manager.dart';
import '../../utils/popups/loaders.dart';
import 'notification_controller.dart';

class CreateNotificationController extends GetxController {
  static CreateNotificationController get instance => Get.find();

  final isLoading = false.obs;

  final notificationController = Get.find<NotificationController>();
  final repository = Get.find<NotificationRepository>();

  /// Register new Notification
  Future<void> createNotification() async {
    try {
      // Start Loading
      isLoading.value = true;

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        isLoading.value = false;
        TLoaders.warningSnackBar(
          title: 'No Internet',
          message: 'Please check your connection.',
        );
        return;
      }

      final userController = Get.find<UserController>();

      // Ensure currentUser is loaded
      final currentUser = userController.currentUser.value;
      if (currentUser == null) {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'User Error',
          message: 'Current user not found.',
        );
        return;
      }

      // Fetch full user details (recipient)
      final recipient = userController.currentUser.value!;

      // Map Data
      final newRecord = NotificationModel(
        id: '', // will be assigned by repository
        title: "Welcome to Coding with T!",
        body:
            "Your account has been successfully created. Start exploring our features and enjoy your app development journey with us.",
        senderId: currentUser.id, // safe access
        recipientIds: [recipient.id],
        type: 'Account',
        routeId: '',
        isBroadcast: true,
        route: TRoutes.notificationDetails,
        seenBy: {},
        seenAt: null,
        createdAt: DateTime.now(),
      );

      // Call Repository to Create New Notification
      newRecord.id = await repository.addNewItem(newRecord);

      // Update Notifications List
      notificationController.notifications.insert(0, newRecord);
      notificationController.notifications.refresh();

      // Remove Loader
      isLoading.value = false;
      TLoaders.successSnackBar(
        title: 'Notification Sent',
        message: 'Welcome notification created!',
      );
    } catch (e) {
      isLoading.value = false;
      TLoaders.errorSnackBar(title: 'Oh Snap', message: e.toString());
    }
  }
}
