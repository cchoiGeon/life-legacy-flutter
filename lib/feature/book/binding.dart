import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'book_controller.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BookController(Get.find<ApiClient>(), Get.find<ToastService>()),
    );
  }
}
