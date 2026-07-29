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

  // ── 헤더 알림 ─────────────────────────────────────────────
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxBool isNotificationsOpen = false.obs;
  final RxBool isNotificationsLoading = false.obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  String get userName => _auth.displayName;
  String get initial => _auth.user.value?.initial ?? '?';

  @override
  void onInit() {
    super.onInit();
    load();
    loadNotifications();
  }

  /// 알림은 보조 정보라 실패해도 홈을 막지 않는다 — 조용히 비워 둔다.
  Future<void> loadNotifications() async {
    try {
      notifications.value = await _api.notifications();
    } on ApiException {
      notifications.clear();
    }
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

  /// 헤더 벨 — 드롭다운을 열고 닫는다 (Figma 169:446).
  void toggleNotifications() {
    isNotificationsOpen.toggle();
    if (isNotificationsOpen.value) loadNotifications();
  }

  void closeNotifications() => isNotificationsOpen.value = false;

  Future<void> markAllNotificationsRead() async {
    isNotificationsLoading.value = true;
    try {
      notifications.value = await _api.markAllNotificationsRead();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isNotificationsLoading.value = false;
    }
  }

  /// "전체 보기" → 알림 센터(13). 돌아오면 목록을 다시 읽는다
  /// (센터에서 "모두 읽음"을 눌렀을 수 있다).
  Future<void> openAllNotifications() async {
    closeNotifications();
    await Get.toNamed(AppRoutes.notifications);
    await loadNotifications();
  }
}
