import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// B6 목차 준비 중 · B7 목차 제안 확인.
class TocController extends GetxController {
  TocController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxBool isGenerating = false.obs;
  final RxBool isConfirming = false.obs;

  /// "순서 바꾸기"를 눌러 끌어 옮길 수 있는 상태인지.
  ///
  /// 기본은 꺼져 있다. 목록이 늘 드래그 가능하면 시니어 사용자가 스크롤하려다
  /// 장을 옮겨 버린다.
  final RxBool isReordering = false.obs;

  /// 로딩 화면 문구에 쓰는 이름. 자기소개 첫 답변에서 가져온다.
  final RxString name = ''.obs;

  /// ⚠️ 09(로딩)와 10(확인)은 **서로 다른 컨트롤러 인스턴스**다.
  ///
  /// `offNamed`로 넘어가면서 로딩 라우트가 스택에서 빠지면 GetX가 그 컨트롤러를
  /// 폐기하고, 10번 진입 시 `fenix`가 새로 만든다. 그래서 만들어 둔 목차를
  /// 필드에 담아 두는 것으로는 전달되지 않는다 — **라우트 인자로 넘겨야 한다.**
  ///
  /// 그래서 인자가 두 가지 모양이다:
  ///   · `Map<String, String>` = 자기소개 답변 → 목차를 만들어야 하는 09번
  ///   · `List<Chapter>`       = 이미 만들어진 목차 → 보여주기만 하는 10번
  @override
  void onInit() {
    super.onInit();
    applyArguments(Get.arguments);
  }

  /// 라우트 인자 해석. `onInit`에서 분리해 둔 이유는 테스트에서
  /// GetX 라우팅 없이 이 규칙만 확인하기 위해서다.
  @visibleForTesting
  void applyArguments(Object? args) {
    if (args is Map<String, String>) {
      name.value = (args['i1'] ?? '').trim();
      generate(args);
    } else if (args is List<Chapter>) {
      chapters.value = args;
    }
  }

  Future<void> generate(Map<String, String> answers) async {
    isGenerating.value = true;
    try {
      final result = await _api.generateToc(answers);
      chapters.value = result;
      // 로딩 화면을 스택에서 지우고 결과로 바꾼다 — 뒤로가기로 로딩에
      // 돌아가면 목차를 다시 만들어 버린다.
      Get.offNamed(AppRoutes.toc, arguments: result);
    } on ApiException catch (e) {
      _toast.showError(e);
      Get.back();
    } finally {
      isGenerating.value = false;
    }
  }

  Future<void> confirm() async {
    if (isConfirming.value) return;
    isConfirming.value = true;
    try {
      await _api.confirmToc(chapters);
      Get.offAllNamed(AppRoutes.home);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isConfirming.value = false;
    }
  }

  /// "순서 바꾸기" ↔ "다 바꿨어요"
  void toggleReorder() => isReordering.toggle();

  /// 끌어 놓은 결과를 반영한다.
  ///
  /// [newIndex]는 **꺼낸 뒤 기준**이다 — 화면이 `ReorderableListView.onReorderItem`
  /// 을 쓰기 때문에 이미 보정돼서 들어온다. 구식 `onReorder`로 되돌리면
  /// 아래로 옮길 때 한 칸씩 밀린다.
  void reorder(int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;
    final moved = chapters.removeAt(oldIndex);
    chapters.insert(newIndex, moved);
  }

  /// 화면에 뜨는 번호. `Chapter.order`가 아니라 **목록에서의 자리**다 —
  /// 순서를 바꾸는 동안에는 원래 order가 더 이상 맞지 않는다.
  /// 확정할 때 `confirmToc`가 이 순서대로 order를 다시 매긴다.
  int displayNumber(int index) => index + 1;
}
