import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 저장 실패(D5)를 잠근다.
///
/// 저장이 실패해도 **화면을 떠나지 않는다.** 토스트만 띄우고 넘겨 버리면
/// 방금 말한 이야기가 어디로 갔는지 알 수 없다. 확인 화면에 그대로 머물면서
/// 글은 남기고, 제목·버튼 문구만 "다시 저장"으로 바뀐다.
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

  test('적은 글도 확인 화면을 거친다', () async {
    final (c, _) = await build();
    typeAnswer(c, '감나무가 있었어요');

    expect(c.stage.value, WriteStage.confirm);
    expect(c.transcript.value, '감나무가 있었어요');
    expect(c.confirmTitle, '이렇게 정리했어요');
    expect(c.saveLabel, '저장하고 다음 질문');
  });

  test('적은 글에는 "말한 시간"이 붙지 않는다', () async {
    final (c, _) = await build();
    typeAnswer(c, '감나무');

    expect(c.answerCaption, '3자');
  });

  test('저장에 실패하면 확인 화면에 머물며 문구가 바뀐다', () async {
    final (c, api) = await build();
    typeAnswer(c, '감나무가 있었어요');
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
    typeAnswer(c, '감나무가 있었어요');
    api.failNextSave = true;
    await c.confirmTranscript();

    await c.confirmTranscript();

    expect(c.saveFailed.value, isFalse);
    expect(c.stage.value, WriteStage.ask);
    expect(c.question.value?.id, isNot(first), reason: '다음 질문으로 옮겨야 한다');
  });

  test('"다시 쓰기"를 누르면 실패 표시가 걷히고 적던 글로 돌아간다', () async {
    final (c, api) = await build();
    typeAnswer(c, '감나무가 있었어요');
    api.failNextSave = true;
    await c.confirmTranscript();

    c.retryAnswer();

    expect(c.saveFailed.value, isFalse);
    expect(c.stage.value, WriteStage.keyboard);
    expect(c.answerController.text, '감나무가 있었어요');
    expect(c.retryLabel, '다시 쓰기');
  });
}
