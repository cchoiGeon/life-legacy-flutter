import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'review_controller.dart';

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ReviewController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
        Get.find<VoicePlayerService>(),
      ),
    );
  }
}
