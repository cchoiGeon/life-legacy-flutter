import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 22 설정 — Figma 155:318.
class SettingsController extends GetxController {
  SettingsController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final Rxn<AppSettings> settings = Rxn<AppSettings>();
  final RxBool isLoading = true.obs;

  User? get user => _auth.user.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      settings.value = await _api.settings();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 토글은 낙관적으로 먼저 반영한다 — 스위치가 손가락을 따라오지 않으면
  /// 고장 난 것처럼 보인다. 실패하면 되돌리고 토스트로 알린다.
  Future<void> setDailyAlarm(bool value) async {
    final before = settings.value;
    if (before == null) return;
    settings.value = before.copyWith(dailyQuestionAlarm: value);
    try {
      settings.value = await _api.updateSettings(settings.value!);
    } on ApiException catch (e) {
      settings.value = before;
      _toast.showError(e);
    }
  }

  /// F4 인쇄본 배송지 수정. 돌아오면 프로필 카드가 바뀔 수 있어 다시 읽는다.
  void openShippingAddress() => Get.toNamed(AppRoutes.settingsAddress);

  /// F3 내 정보 (보기 전용)
  void openProfile() => Get.toNamed(AppRoutes.settingsProfile);

  /// 약관 문서는 시안에 화면이 없다. 자리만 만들어 뒀다.
  void openTerms() => _toast.show('이용약관은 준비 중이에요');

  void openPrivacy() => _toast.show('개인정보 처리방침은 준비 중이에요');

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(AppRoutes.splash);
  }
}
