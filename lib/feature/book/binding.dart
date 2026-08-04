import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'book_controller.dart';
import 'book_detail_controller.dart';

class BookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BookController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
        Get.find<AuthService>(),
      ),
    );
  }
}

class BookDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BookDetailController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
