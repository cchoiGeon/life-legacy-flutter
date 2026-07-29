import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';

/// MockApiClient가 "그냥 고정값을 뱉는 것"이 아니라 **상태를 들고 있다**는
/// 것을 잠가 둔다. 이게 깨지면 답변을 저장해도 진행률이 안 오르고,
/// 화면 흐름이 도는지 확인할 수 없게 된다.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // GetStorage는 저장 위치를 path_provider에게 묻는다. 테스트에는 플러그인
    // 구현이 없으므로(MissingPluginException) 임시 디렉터리를 돌려주도록
    // 채널을 가로챈다. 프로젝트 폴더에 .gs 파일이 생기지 않게 systemTemp를 쓴다.
    final dir = await Directory.systemTemp.createTemp('life_legacy_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );

    await Storage.init();
  });

  test('인증번호가 틀리면 INVALID_CODE 로 거절한다', () async {
    final api = MockApiClient();
    expect(
      () => api.verifyCode(phone: '01012345678', code: '000000'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'INVALID_CODE'),
      ),
    );
  });

  test('데모 인증번호로는 세션이 발급된다', () async {
    final api = MockApiClient();
    final session = await api.verifyCode(
      phone: '01012345678',
      code: MockApiClient.demoCode,
    );
    expect(session.accessToken, isNotEmpty);
    expect(session.user.phone, '01012345678');
  });

  test('답변을 저장하면 진행률이 오르고 다음 질문이 나온다', () async {
    final api = MockApiClient();

    final before = await api.home();
    final q = await api.currentQuestion();
    expect(q, isNotNull, reason: '시드 데이터에 미답변 질문이 있어야 한다');

    final next = await api.saveAnswer(questionId: q!.id, text: '테스트 답변');
    final after = await api.home();

    expect(after.progress, greaterThan(before.progress));
    expect(after.remainingQuestions, before.remainingQuestions - 1);
    expect(next?.id, isNot(q.id), reason: '같은 질문이 다시 나오면 안 된다');
  });

  test('앞 장을 끝내야 다음 장이 열린다', () async {
    final api = MockApiClient();
    final chapters = await api.chapters();

    // 시드: 1장 완료 · 2장 작성 중 · 3장부터 잠김
    expect(chapters[0].status, ChapterStatus.done);
    expect(chapters[1].status, ChapterStatus.writing);
    expect(chapters[2].status, ChapterStatus.locked);
  });

  test('키보드로 적은 답변도 같은 경로로 저장된다', () async {
    final api = MockApiClient();
    final q = await api.currentQuestion();

    // AI 다듬기 단계가 없어졌으므로 saveAnswer 하나가 음성·키보드를 모두 받는다.
    await api.saveAnswer(questionId: q!.id, text: '직접 적은 답변입니다');
    final pages = await api.bookPages();

    expect(pages.expand((p) => p.paragraphs), contains('직접 적은 답변입니다'));
  });

  test('책 미리보기는 답변한 장만 싣는다', () async {
    final api = MockApiClient();
    final pages = await api.bookPages();

    expect(pages, isNotEmpty);
    // 잠긴 3~5장은 답변이 없으므로 실리지 않는다.
    expect(pages.every((p) => p.chapterOrder <= 2), isTrue);
  });
}
