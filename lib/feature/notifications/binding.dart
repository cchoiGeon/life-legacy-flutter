import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => NotificationsController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
