import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'intro_controller.dart';

class IntroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => IntroController(
        Get.find<ApiClient>(),
        Get.find<SpeechService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
