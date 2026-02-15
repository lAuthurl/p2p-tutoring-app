import 'package:get/get.dart';

import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/subject_controller.dart';
import 'package:p2p_tutoring_app/Feautures/dashboard/Home/controllers/home_controller.dart';
import 'package:p2p_tutoring_app/Feautures/Booking/controllers/booking_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // These require signed-in user + datastore started
    Get.put(SubjectController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(BookingController(), permanent: true);
  }
}
