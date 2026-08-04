import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
      fenix: true,
    );
  }
}
