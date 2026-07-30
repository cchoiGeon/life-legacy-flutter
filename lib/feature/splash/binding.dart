import 'package:get/get.dart';

import 'package:life_legacy/service/services.dart';

import 'splash_controller.dart';

class SplashBinding extends Bindings {
  /// ⚠️ `lazyPut`이 아니라 **`put`(즉시 생성)** 이다.
  ///
  /// 시안 A1에는 버튼이 없어서 [SplashView]가 컨트롤러를 한 번도 읽지 않는다.
  /// `lazyPut`이면 `Get.find`를 부르는 사람이 없어 컨트롤러가 아예 만들어지지
  /// 않고, `onInit`의 세션 확인·화면 이동이 돌지 않아 **스플래시에서 멈춘다.**
  @override
  void dependencies() {
    Get.put(SplashController(Get.find<AuthService>()));
  }
}
