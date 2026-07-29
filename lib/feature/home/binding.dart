import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => HomeController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
