import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'faq_controller.dart';
import 'qna_controller.dart';

class FaqBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FaqController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}

class QnaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => QnaController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
