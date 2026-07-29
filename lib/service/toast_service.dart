import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';

/// 토스트 종류 — 시안 `sec/피드백`의 성공/오류 두 가지.
enum ToastKind { success, error }

/// 화면 위에 잠깐 뜨는 알림 한 건.
class ToastMessage {
  const ToastMessage({
    required this.kind,
    required this.title,
    this.description,
  });

  final ToastKind kind;

  /// "저장되었습니다."
  final String title;

  /// "다음 질문으로 이동합니다."
  final String? description;
}

/// 토스트 큐 — 화면(AppShell)이 이 값을 구독해서 그린다.
///
/// GetX의 `Get.snackbar`를 쓰지 않는 이유: 시안의 토스트는 모양이 정해져
/// 있어서 Material 스낵바를 뜯어고치는 것보다 직접 그리는 편이 짧다.
class ToastService extends GetxService {
  final Rxn<ToastMessage> current = Rxn<ToastMessage>();

  void show(String title, {String? description}) => _push(
    ToastMessage(
      kind: ToastKind.success,
      title: title,
      description: description,
    ),
  );

  void showError(Object error, {String? description}) {
    final message = error is ApiException
        ? error.message
        : '문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
    _push(
      ToastMessage(
        kind: ToastKind.error,
        title: message,
        description: description,
      ),
    );
  }

  void dismiss() => current.value = null;

  void _push(ToastMessage message) => current.value = message;
}
