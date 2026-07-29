import 'package:get/get.dart';

import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 01 스플래시.
///
/// 저장된 세션을 확인해서 다음 화면을 정한다:
///   · 세션 없음        → 로그인(02)
///   · 세션 있고 목차 X → 자기소개(07)
///   · 세션 있고 목차 O → 홈(11)
///
/// 세션이 있을 때는 화면을 스치듯 지나가고, 없을 때는 시작 화면으로
/// 머문다(시안 01번은 "시작하기" 버튼이 있는 랜딩이다).
class SplashController extends GetxController {
  SplashController(this._auth);

  final AuthService _auth;

  /// 세션 확인이 끝나기 전에는 버튼을 누를 수 없게 한다.
  final RxBool isChecking = true.obs;

  @override
  void onInit() {
    super.onInit();
    _decide();
  }

  Future<void> _decide() async {
    final restored = await _auth.restore();
    isChecking.value = false;
    if (!restored) return; // 랜딩에 머문다
    Get.offAllNamed(Storage.introDone ? AppRoutes.home : AppRoutes.intro);
  }

  void start() => Get.toNamed(AppRoutes.login);
}
