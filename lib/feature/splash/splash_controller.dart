import 'package:get/get.dart';

import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// A1 스플래시.
///
/// 저장된 세션을 확인해서 다음 화면을 정한다:
///   · 세션 없음              → 로그인(A2)
///   · 세션 있고 번호 없음    → 전화 연결(카카오 후속)
///   · 세션 있고 목차 X       → 자기소개(B1)
///   · 세션 있고 목차 O       → 홈(C1)
///
/// ⚠️ 어느 경우에도 **머무르지 않는다.** 시안 A1에는 버튼이 없다.
///    세션 확인이 순식간에 끝나도 [_minimumHold]만큼은 브랜드를 보여준다 —
///    화면이 번쩍이고 지나가면 앱이 잘못 뜬 것처럼 보인다.
class SplashController extends GetxController {
  SplashController(this._auth);

  final AuthService _auth;

  static const _minimumHold = Duration(milliseconds: 1200);

  @override
  void onInit() {
    super.onInit();
    _decide();
  }

  Future<void> _decide() async {
    final results = await Future.wait([
      _auth.restore(),
      Future<bool>.delayed(_minimumHold, () => false),
    ]);
    final restored = results.first;

    if (!restored) {
      Get.offAllNamed(AppRoutes.index);
      return;
    }

    final phone = _auth.user.value?.phone ?? '';
    if (phone.isEmpty) {
      Get.offAllNamed(
        AppRoutes.auth,
        arguments: const {'linkPhone': true},
      );
      return;
    }

    Get.offAllNamed(
      Storage.introDone ? AppRoutes.home : AppRoutes.intro,
    );
  }
}
