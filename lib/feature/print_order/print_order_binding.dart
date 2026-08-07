import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'print_order_controller.dart';

class PrintOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PrintOrderController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
