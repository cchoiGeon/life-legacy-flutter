import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// C1 홈 대시보드 · C2 빈 상태.
///
/// 두 프레임은 같은 화면이고 [HomeSummary.isEmpty]로 갈린다.
class HomeController extends GetxController {
  HomeController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final Rxn<HomeSummary> summary = Rxn<HomeSummary>();

  /// 카드 아래 목차 목록. 시안 C1이 홈에서 바로 보여준다 —
  /// 자서전 탭까지 가야 진행 상황을 볼 수 있으면 홈이 할 일이 없다.
  final RxList<Chapter> chapters = <Chapter>[].obs;

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
      final results = await Future.wait([_api.home(), _api.chapters()]);
      summary.value = results[0] as HomeSummary;
      chapters.value = results[1] as List<Chapter>;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// 빈 상태(C2) 카드 문구 — "1장 어린 시절의 질문 8개를 준비해뒀어요".
  String get emptyCaption {
    if (chapters.isEmpty) return '첫 질문을 준비하고 있어요';
    final first = chapters.first;
    return '${first.order}장 ${first.title}의 질문 ${first.questionCount}개를 준비해뒀어요';
  }

  /// 빈 상태 CTA — "1장 시작하기"
  String get emptyCtaLabel =>
      chapters.isEmpty ? '시작하기' : '${chapters.first.order}장 시작하기';

  /// "5장 · 질문 40개가 기다리고 있어요" (시안 348:812)
  String get emptyProgressCaption {
    final questions = chapters.fold(0, (sum, c) => sum + c.questionCount);
    return '${chapters.length}장 · 질문 $questions개가 기다리고 있어요';
  }

  /// "말로 답하기" · "1장 시작하기" 둘 다 작성 탭으로 간다.
  void continueWriting() => Get.offNamed(AppRoutes.write);

  void openBook() => Get.offNamed(AppRoutes.book);

  /// 목차 한 줄을 눌렀을 때. 잠긴 장은 눌리지 않는다.
  void openChapter(Chapter chapter) {
    if (chapter.status == ChapterStatus.locked) {
      _toast.show('${chapter.order - 1}장을 마치면 열려요');
      return;
    }
    continueWriting();
  }

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
