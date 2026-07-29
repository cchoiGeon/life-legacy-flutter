import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 13 알림 센터 — Figma `13 알림 센터 · /me/notifications`(169:553).
///
/// 홈 드롭다운의 "전체 보기"에서 들어온다. 목록만 보여주는 화면이라
/// 홈 컨트롤러와 상태를 공유하지 않고 자기 것을 따로 읽는다 —
/// 홈으로 돌아가면 홈이 다시 읽는다.
class NotificationsController extends GetxController {
  NotificationsController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxList<AppNotification> items = <AppNotification>[].obs;
  final RxBool isLoading = true.obs;

  int get unreadCount => items.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      items.value = await _api.notifications();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount == 0) return;
    try {
      items.value = await _api.markAllNotificationsRead();
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  /// 알림을 눌렀을 때. 각 알림이 어디로 가야 하는지는 서버 계약이
  /// 정해져야 알 수 있다(딥링크 필드 등). 지금은 자리만 만들어 뒀다.
  void openItem(AppNotification notification) =>
      _toast.show('알림 바로가기는 준비 중이에요');
}
