import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// AI 꼬리질문 단계를 잠근다.
///
/// 한 질문의 흐름은 **두 번 답하고 한 번 저장**이다:
///   질문 → 답변 → (AI) 꼬리질문 → 답변 → (AI) 윤문 → 저장 → 다음 질문
///
/// 사용자에게 보이는 건 자기가 답한 원문뿐이다. 윤문 결과는 저장만 하고
/// 작성 화면에서는 보여주지 않는다.
void main() {
  setUpAll(() => initTestEnv('write_followup'));

  Future<(WriteController, MockApiClient)> build() async {
    final api = MockApiClient();
    final c = WriteController(api, SpeechService(), ToastService());
    c.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return (c, api);
  }

  /// 키보드로 적어 확인 화면(D4)까지 민다.
  void typeAnswer(WriteController c, String text) {
    c.useKeyboard();
    c.answerController.text = text;
    c.submitTyped();
  }

  /// 1차 답변을 끝내고 꼬리질문을 받은 상태로 만든다.
  Future<void> reachFollowup(WriteController c, String text) async {
    typeAnswer(c, text);
    await c.confirmTranscript();
  }

  group('1차 답변 → 꼬리질문', () {
    test('1차 답변을 마치면 다음 질문이 아니라 꼬리질문으로 간다', () async {
      final (c, _) = await build();
      final first = c.question.value!.id;

      await reachFollowup(c, '제주도에 갔던 게 제일 기억에 남습니다');

      expect(c.question.value?.id, first, reason: '같은 질문에 머물러야 한다');
      expect(c.isFollowup.value, isTrue);
      expect(c.followup.value, isNotNull);
      expect(c.stage.value, WriteStage.ask, reason: '다시 답을 받는 대기 화면이다');
    });

    test('꼬리질문 화면은 AI가 만든 질문을 보여준다', () async {
      final (c, _) = await build();
      final original = c.question.value!.text;

      await reachFollowup(c, '제주도에 갔습니다');

      expect(c.displayQuestion, c.followup.value!.text);
      expect(c.displayQuestion, isNot(original));
      expect(c.followupBadge, '이어서 여쭤볼게요');
    });

    test('1차 답변 화면에는 배지가 없다', () async {
      final (c, _) = await build();

      expect(c.followupBadge, isNull);
      expect(c.displayQuestion, c.question.value!.text);
    });

    test('꼬리질문을 만드는 동안 전용 안내를 보여준다', () async {
      final (c, _) = await build();
      typeAnswer(c, '제주도에 갔습니다');

      final saving = c.confirmTranscript();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.stage.value, WriteStage.generatingFollowup);
      expect(c.loadingTitle, '말씀을 듣고 있어요');

      await saving;
    });
  });

  group('꼬리질문 답변 → 저장', () {
    test('꼬리질문에 답해야 다음 질문으로 넘어간다', () async {
      final (c, _) = await build();
      final first = c.question.value!.id;
      await reachFollowup(c, '제주도에 갔습니다');

      typeAnswer(c, '성산일출봉에 오래 있었습니다');
      await c.confirmTranscript();

      expect(c.question.value?.id, isNot(first), reason: '이제야 다음 질문이다');
      expect(c.isFollowup.value, isFalse, reason: '새 질문은 1차 답변부터다');
      expect(c.followup.value, isNull);
      expect(c.stage.value, WriteStage.ask);
    });

    test('정리하는 동안 꼬리질문 때와 다른 안내를 보여준다', () async {
      final (c, _) = await build();
      await reachFollowup(c, '제주도에 갔습니다');
      typeAnswer(c, '성산일출봉에 있었습니다');

      final saving = c.confirmTranscript();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.stage.value, WriteStage.saving);
      expect(c.loadingTitle, '이야기를 정리하고 있어요');

      await saving;
    });

    test('저장이 끝나도 윤문 결과를 화면에 보여주지 않는다', () async {
      final (c, _) = await build();
      await reachFollowup(c, '제주도에 갔습니다');
      typeAnswer(c, '성산일출봉에 있었습니다');

      await c.confirmTranscript();

      expect(c.transcript.value, isEmpty, reason: '다음 질문 화면은 비어 있어야 한다');
    });
  });

  group('꼬리질문 생성 실패 — 처음부터 다시', () {
    test('실패하면 다시 답해 달라는 화면으로 간다', () async {
      final (c, api) = await build();
      typeAnswer(c, '제주도에 갔습니다');
      api.failNextFollowup = true;

      await c.confirmTranscript();

      expect(c.stage.value, WriteStage.followupFailed);
      expect(c.isFollowup.value, isFalse);
      expect(c.followup.value, isNull);
    });

    test('"다시 시작하기"를 누르면 같은 질문을 처음부터 받는다', () async {
      final (c, api) = await build();
      final first = c.question.value!.id;
      typeAnswer(c, '제주도에 갔습니다');
      api.failNextFollowup = true;
      await c.confirmTranscript();

      c.restartQuestion();

      expect(c.stage.value, WriteStage.ask);
      expect(c.question.value?.id, first, reason: '질문은 그대로다');
      expect(c.transcript.value, isEmpty);
      expect(c.answerController.text, isEmpty);
    });
  });

  group('윤문 실패 — 글을 남긴 채 저장만 재시도', () {
    test('실패해도 확인 화면에 머물고 적은 글이 남는다', () async {
      final (c, api) = await build();
      await reachFollowup(c, '제주도에 갔습니다');
      typeAnswer(c, '성산일출봉에 오래 있었습니다');
      api.failNextSave = true;

      await c.confirmTranscript();

      expect(c.stage.value, WriteStage.confirm, reason: '화면을 떠나면 안 된다');
      expect(c.saveFailed.value, isTrue);
      expect(c.transcript.value, '성산일출봉에 오래 있었습니다');
      expect(c.saveLabel, '다시 저장하기');
    });

    test('다시 저장하면 성공하고 다음 질문으로 넘어간다', () async {
      final (c, api) = await build();
      final first = c.question.value!.id;
      await reachFollowup(c, '제주도에 갔습니다');
      typeAnswer(c, '성산일출봉에 있었습니다');
      api.failNextSave = true;
      await c.confirmTranscript();

      await c.confirmTranscript();

      expect(c.saveFailed.value, isFalse);
      expect(c.question.value?.id, isNot(first));
      expect(c.isFollowup.value, isFalse);
    });

    test('실패 후 "다시 쓰기"는 꼬리질문 답변만 다시 받는다', () async {
      final (c, api) = await build();
      await reachFollowup(c, '제주도에 갔습니다');
      typeAnswer(c, '성산일출봉에 있었습니다');
      api.failNextSave = true;
      await c.confirmTranscript();

      c.retryAnswer();

      expect(c.stage.value, WriteStage.keyboard);
      expect(c.isFollowup.value, isTrue, reason: '1차 답변으로 되돌아가면 안 된다');
      expect(c.answerController.text, '성산일출봉에 있었습니다');
    });
  });

  group('건너뛰기', () {
    test('건너뛰면 꼬리질문 없이 다음 질문으로 간다', () async {
      final (c, _) = await build();
      final first = c.question.value!.id;

      await c.skip();

      expect(c.question.value?.id, isNot(first));
      expect(c.isFollowup.value, isFalse);
      expect(c.followup.value, isNull);
    });
  });

  group('입력 방식 전달', () {
    test('음성으로 답하면 말한 시간과 함께 voice로 보낸다', () async {
      final (c, api) = await build();
      final questionId = c.question.value!.id;
      c.transcript.value = '제주도에 갔습니다';
      c.answerSource.value = WriteStage.recording;
      c.spokenSeconds.value = 42;
      c.stage.value = WriteStage.confirm;

      await c.confirmTranscript();

      expect(api.lastAnswerInputMode, ComposeMode.voice);
      expect(api.lastAnswerSpokenSeconds, 42);
      expect(api.lastAnswerQuestionId, questionId);
    });

    test('키보드로 적으면 말한 시간 없이 keyboard로 보낸다', () async {
      final (c, api) = await build();

      await reachFollowup(c, '제주도에 갔습니다');

      expect(api.lastAnswerInputMode, ComposeMode.keyboard);
      expect(api.lastAnswerSpokenSeconds, isNull);
    });
  });
}
