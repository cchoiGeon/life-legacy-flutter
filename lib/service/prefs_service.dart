import 'package:get/get.dart';

import 'package:life_legacy/data/data_manager.dart';

/// 질문 글자 크기 한 단계.
typedef QuestionFontLevel = ({
  String label,
  double primary,
  double compact,
  double card,
});

/// 기기 로컬 표시 설정 — 서버와 무관하다.
class PrefsService extends GetxService {
  /// 시안 기본(보통)이 1번. 시니어용으로 크게·더 크게까지 둔다.
  static const levels = <QuestionFontLevel>[
    (label: '작게', primary: 24, compact: 18, card: 22),
    (label: '보통', primary: 28, compact: 20, card: 26),
    (label: '크게', primary: 32, compact: 22, card: 30),
    (label: '더 크게', primary: 36, compact: 24, card: 34),
  ];

  final RxInt questionFontLevel = 1.obs;

  QuestionFontLevel get current =>
      levels[questionFontLevel.value.clamp(0, levels.length - 1)];

  String get questionFontLabel => current.label;

  /// 작성 음성 화면 질문(명조 기본 28).
  double get questionPrimarySize => current.primary;

  /// 꼬리질문·키보드 모드 질문(명조 기본 20).
  double get questionCompactSize => current.compact;

  /// 홈·책 상세 카드 질문(명조 기본 26).
  double get questionCardSize => current.card;

  PrefsService init() {
    questionFontLevel.value =
        Storage.questionFontLevel.clamp(0, levels.length - 1);
    return this;
  }

  Future<void> setQuestionFontLevel(int level) async {
    final next = level.clamp(0, levels.length - 1);
    if (next == questionFontLevel.value) return;
    questionFontLevel.value = next;
    await Storage.saveQuestionFontLevel(next);
  }

  Future<void> smallerQuestionFont() =>
      setQuestionFontLevel(questionFontLevel.value - 1);

  Future<void> largerQuestionFont() =>
      setQuestionFontLevel(questionFontLevel.value + 1);
}
