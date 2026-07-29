import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

import 'login_controller.dart';

/// 02~06 공통 바인딩.
///
/// `fenix: true` — 로그인 → 전화번호 → 인증번호로 이동하는 동안 앞 화면이
/// 스택에서 빠지면 GetX가 컨트롤러를 지운다. 뒤로 돌아왔을 때 다시 만들어
/// 주도록 한다.
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ToastService>(),
      ),
      fenix: true,
    );
  }
}
