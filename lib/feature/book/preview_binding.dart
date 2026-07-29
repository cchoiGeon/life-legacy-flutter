import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'preview_controller.dart';

/// 20·21 공통 바인딩.
class BookPreviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BookPreviewController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
      fenix: true,
    );
  }
}
