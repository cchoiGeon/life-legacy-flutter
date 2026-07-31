import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 질문 문구 고치기.
///
/// 목차와 질문은 사용자별로 복제해 두므로, 한 사람이 고쳐도 다른 사람의
/// 질문은 그대로다. 고칠 수 있는 건 **문구뿐**이다 — 질문을 더하거나 빼는
/// 건 목차 구조가 흔들려서 1차 범위 밖이다.
void main() {
  setUpAll(() => initTestEnv('question_edit'));

  Future<(WriteController, MockApiClient)> build() async {
    final api = MockApiClient();
    final c = WriteController(api, SpeechService(), ToastService());
    c.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return (c, api);
  }

  void typeAnswer(WriteController c, String text) {
    c.useKeyboard();
    c.answerController.text = text;
    c.submitTyped();
  }

  test('문구를 고치면 화면의 질문이 바뀐다', () async {
    final (c, _) = await build();
    final before = c.question.value!.text;

    await c.editQuestionText('친구와 어떤 추억이 있으신가요?');

    expect(c.question.value?.text, '친구와 어떤 추억이 있으신가요?');
    expect(c.displayQuestion, '친구와 어떤 추억이 있으신가요?');
    expect(c.question.value?.text, isNot(before));
  });

  test('고쳐도 질문 자리는 그대로다', () async {
    final (c, _) = await build();
    final id = c.question.value!.id;
    final order = c.question.value!.order;

    await c.editQuestionText('친구와 어떤 추억이 있으신가요?');

    expect(c.question.value?.id, id, reason: '다른 질문이 되면 안 된다');
    expect(c.question.value?.order, order);
  });

  test('빈 문구로는 고칠 수 없다', () async {
    final (c, _) = await build();
    final before = c.question.value!.text;

    await c.editQuestionText('   ');

    expect(c.question.value?.text, before);
  });

  test('꼬리질문 단계에서는 고칠 수 없다', () async {
    final (c, _) = await build();
    typeAnswer(c, '제주도에 갔습니다');
    await c.confirmTranscript();
    final followupText = c.followup.value!.text;

    // 이미 그 질문에 답한 뒤다. 지금 문구를 바꾸면 저장될 답과 어긋난다.
    expect(c.canEditQuestion, isFalse);
    await c.editQuestionText('전혀 다른 질문');

    expect(c.displayQuestion, followupText, reason: '꼬리질문이 그대로여야 한다');
  });

  test('1차 답변 단계에서는 고칠 수 있다', () async {
    final (c, _) = await build();

    expect(c.canEditQuestion, isTrue);
  });

  test('이미 답한 질문은 서버가 거절한다', () async {
    final api = MockApiClient();
    final q = await api.currentQuestion();
    final followup = await api.submitAnswer(
      questionId: q!.id,
      text: '답했습니다',
      inputMode: ComposeMode.keyboard,
    );
    await api.submitFollowupAnswer(
      questionId: q.id,
      followupId: followup.id,
      text: '이어서 답했습니다',
      inputMode: ComposeMode.keyboard,
    );

    expect(
      () => api.updateQuestionText(questionId: q.id, text: '고친 문구'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'ALREADY_ANSWERED'),
      ),
    );
  });
}
