import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'write_controller.dart';

class WriteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => WriteController(Get.find<ApiClient>(), Get.find<ToastService>()),
    );
  }
}
