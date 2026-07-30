import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'address_controller.dart';
import 'profile_controller.dart';
import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}

/// F3 내 정보
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ProfileController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
    );
  }
}

/// F4 인쇄본 배송지 수정
class AddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AddressController(
        Get.find<ApiClient>(),
        Get.find<ToastService>(),
      ),
    );
  }
}
