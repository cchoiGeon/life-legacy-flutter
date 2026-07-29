import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 11 홈 대시보드 · 12 빈 상태.
///
/// 두 프레임은 같은 화면이고 [HomeSummary.isEmpty]로 갈린다.
class HomeController extends GetxController {
  HomeController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final Rxn<HomeSummary> summary = Rxn<HomeSummary>();
  final RxBool isLoading = true.obs;

  String get userName => _auth.displayName;
  String get initial => _auth.user.value?.initial ?? '?';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      summary.value = await _api.home();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// "이어서 이야기하기" · "첫 이야기 시작하기" 둘 다 작성 탭으로 간다.
  void continueWriting() => Get.offNamed(AppRoutes.write);

  void openBook() => Get.offNamed(AppRoutes.book);

  /// 알림 — 화면이 아직 없다(시안 A~F에 알림 목록 프레임이 없다).
  void openNotifications() => _toast.show('알림은 준비 중이에요');
}
