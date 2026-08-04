import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/intro/toc_controller.dart';
import 'package:life_legacy/service/services.dart';

/// 09(로딩) → 10(목차 확인) 사이에서 목차가 유실되던 버그를 잠근다.
///
/// 두 화면은 **서로 다른 컨트롤러 인스턴스**를 쓴다. 로딩 라우트가
/// `offNamed`로 스택에서 빠지면서 GetX가 컨트롤러를 폐기하고, 10번 진입 시
/// `fenix`가 새로 만들기 때문이다. 그래서 만들어 둔 목차는 필드가 아니라
/// **라우트 인자**로 넘어와야 하고, 컨트롤러는 그 인자를 해석할 줄 알아야 한다.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 컨트롤러가 생성 후 `Get.offNamed`를 부른다. 네비게이터가 없는 테스트에서
    // 실제 라우팅을 타지 않도록 GetX의 테스트 모드를 켠다.
    Get.testMode = true;
    final dir = await Directory.systemTemp.createTemp('life_legacy_toc_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => dir.path,
        );
    await Storage.init();
  });

  (TocController, AuthService) build() {
    final api = MockApiClient();
    final auth = AuthService(api);
    return (TocController(api, auth, ToastService()), auth);
  }

  const sample = [
    Chapter(
      id: 'c1',
      order: 1,
      title: '안동에서의 어린 시절',
      status: ChapterStatus.locked,
      answeredCount: 0,
      questionCount: 8,
    ),
    Chapter(
      id: 'c2',
      order: 2,
      title: '학창 시절과 꿈',
      status: ChapterStatus.locked,
      answeredCount: 0,
      questionCount: 8,
    ),
  ];

  test('List<Chapter> 인자를 받으면 그대로 목차로 세운다', () {
    final (controller, _) = build();
    controller.applyArguments(sample);

    expect(controller.chapters, hasLength(2));
    expect(controller.chapters.first.title, '안동에서의 어린 시절');
  });

  test('인자가 없으면 목차가 비어 있다 — 이게 화면이 비어 보이던 상태다', () {
    final (controller, _) = build();
    controller.applyArguments(null);

    expect(controller.chapters, isEmpty);
  });

  test('List 인자를 받으면 목차를 생성한다', () async {
    final (controller, _) = build();
    controller.applyArguments(const [
      IntroAnswerSubmission(questionId: 'i2', value: '여'),
    ]);

    await Future<void>.delayed(const Duration(seconds: 4));
    expect(controller.chapters, isNotEmpty);
    expect(controller.bookId.value, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('generateToc는 비어 있지 않은 목차를 돌려준다', () async {
    final result = await MockApiClient().generateToc(const [
      IntroAnswerSubmission(questionId: 'i2', value: '여'),
    ]);

    expect(result.chapters, isNotEmpty);
    expect(result.chapters.first.order, 1);
    expect(result.chapters.map((c) => c.title), contains('어린 시절'));
  }, timeout: const Timeout(Duration(seconds: 15)));

  test('목차를 확정하면 사용자 정보를 다시 읽는다', () async {
    final (c, auth) = build();
    c.bookId.value = 'b_mock_001';
    c.chapters.value = List.of(sample);

    await c.confirm();

    expect(auth.user.value, isNotNull);
    expect(auth.displayName, isNotEmpty);
  });

  test('목차를 확정하면 자기소개를 마쳤다고 표시한다', () async {
    await Storage.clearSession();
    final (c, _) = build();
    c.bookId.value = 'b_mock_001';
    c.chapters.value = List.of(sample);

    await c.confirm();

    expect(Storage.introDone, isTrue);
  });
}
