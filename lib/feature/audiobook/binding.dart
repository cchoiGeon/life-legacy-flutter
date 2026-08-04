import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'audiobook_controller.dart';

class AudiobookBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AudiobookController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
        Get.find<VoicePlayerService>(),
      ),
    );
  }
}
