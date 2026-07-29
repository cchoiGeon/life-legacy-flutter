import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
