import 'package:get/get.dart';

import 'package:life_legacy/service/services.dart';

import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SplashController(Get.find<AuthService>()));
  }
}
