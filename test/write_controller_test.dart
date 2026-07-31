import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 답변 확인(D4)과 저장 실패(D5)의 **문구 규칙**을 잠근다.
///
/// 저장이 실패해도 **화면을 떠나지 않는다.** 토스트만 띄우고 넘겨 버리면
/// 방금 말한 이야기가 어디로 갔는지 알 수 없다. 확인 화면에 그대로 머물면서
/// 글은 남기고, 제목·버튼 문구만 "다시 저장"으로 바뀐다.
///
/// 꼬리질문 흐름 자체(어느 단계에서 무엇이 저장되는지)는
/// `write_followup_test.dart`가 맡는다.
void main() {
  setUpAll(() => initTestEnv('write'));

  Future<(WriteController, MockApiClient)> build() async {
    final api = MockApiClient();
    final c = WriteController(api, SpeechService(), ToastService());
    c.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return (c, api);
  }

  /// 확인 화면(D4)까지 밀어 넣는다.
  void typeAnswer(WriteController c, String text) {
    c.useKeyboard();
    c.answerController.text = text;
    c.submitTyped();
  }

  /// 저장이 일어나는 지점, 즉 **꼬리답변 확인 화면**까지 밀어 넣는다.
  ///
  /// 저장(윤문)은 꼬리답변을 보낼 때 일어난다. 1차 답변을 보내는 호출은
  /// 꼬리질문을 받아 오는 것이라 실패해도 D5가 아니라 D8로 간다.
  Future<void> reachSaveStep(WriteController c, String text) async {
    typeAnswer(c, '제주도에 갔던 게 기억납니다');
    await c.confirmTranscript();
    typeAnswer(c, text);
  }

  test('적은 글도 확인 화면을 거친다', () async {
    final (c, _) = await build();
    typeAnswer(c, '감나무가 있었어요');

    expect(c.stage.value, WriteStage.confirm);
    expect(c.transcript.value, '감나무가 있었어요');
    expect(c.confirmTitle, '이렇게 정리했어요');
    // 1차 답변이라 아직 저장 단계가 아니다 — 문구 규칙은 write_followup_test가 맡는다.
    expect(c.saveLabel, '이어서 답하기');
  });

  test('적은 글에는 "말한 시간"이 붙지 않는다', () async {
    final (c, _) = await build();
    typeAnswer(c, '감나무');

    expect(c.answerCaption, '3자');
  });

  test('저장에 실패하면 확인 화면에 머물며 문구가 바뀐다', () async {
    final (c, api) = await build();
    await reachSaveStep(c, '감나무가 있었어요');
    api.failNextSave = true;

    await c.confirmTranscript();

    expect(c.stage.value, WriteStage.confirm, reason: '화면을 떠나면 안 된다');
    expect(c.saveFailed.value, isTrue);
    expect(c.transcript.value, '감나무가 있었어요', reason: '적은 글이 남아 있어야 한다');
    expect(c.confirmTitle, '정리는 마쳤어요');
    expect(c.confirmSubtitle, '저장만 남았어요');
    expect(c.saveLabel, '다시 저장하기');
  });

  test('다시 저장하면 성공하고 다음 질문으로 넘어간다', () async {
    final (c, api) = await build();
    final first = c.question.value!.id;
    await reachSaveStep(c, '감나무가 있었어요');
    api.failNextSave = true;
    await c.confirmTranscript();

    await c.confirmTranscript();

    expect(c.saveFailed.value, isFalse);
    expect(c.stage.value, WriteStage.ask);
    expect(c.question.value?.id, isNot(first), reason: '다음 질문으로 옮겨야 한다');
  });

  test('"다시 쓰기"를 누르면 실패 표시가 걷히고 적던 글로 돌아간다', () async {
    final (c, api) = await build();
    await reachSaveStep(c, '감나무가 있었어요');
    api.failNextSave = true;
    await c.confirmTranscript();

    c.retryAnswer();

    expect(c.saveFailed.value, isFalse);
    expect(c.stage.value, WriteStage.keyboard);
    expect(c.answerController.text, '감나무가 있었어요');
    expect(c.retryLabel, '다시 쓰기');
  });
}
