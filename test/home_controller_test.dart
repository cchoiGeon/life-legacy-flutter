import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/home/home_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 홈(C1·C2)이 목차를 직접 들고 있어야 한다.
///
/// 시안이 홈 카드 아래에 목차를 펼쳐 놓으면서 `home()` 하나로는 부족해졌다 —
/// 진행률 카드용 요약과 목록용 장 정보를 같이 읽는다.
void main() {
  setUpAll(() => initTestEnv('home'));

  Future<HomeController> build() async {
    final api = MockApiClient();
    final c = HomeController(api, AuthService(api), ToastService());
    await c.load();
    return c;
  }

  test('요약과 목차를 함께 읽는다', () async {
    final c = await build();

    expect(c.summary.value, isNotNull);
    expect(c.chapters, hasLength(5));
  });

  test('장마다 오른쪽에 뜰 상태 글자가 정해진다', () async {
    final c = await build();

    final done = c.chapters.firstWhere(
      (x) => x.status == ChapterStatus.done,
    );
    final writing = c.chapters.firstWhere(
      (x) => x.status == ChapterStatus.writing,
    );
    final locked = c.chapters.firstWhere(
      (x) => x.status == ChapterStatus.locked,
    );

    expect(done.statusLabel, '완료');
    expect(writing.statusLabel, '3/8');
    expect(locked.statusLabel, isNull, reason: '잠긴 장은 아무것도 쓰지 않는다');
  });

  test('잠긴 장의 보조 문구는 몇 장을 마쳐야 열리는지 알려준다', () async {
    final c = await build();
    final locked = c.chapters.firstWhere(
      (x) => x.status == ChapterStatus.locked,
    );

    expect(locked.subtitle, '${locked.order - 1}장을 마치면 열려요');
  });

  test('진행 중인 장은 다음에 물어볼 질문을 보여준다', () async {
    final c = await build();
    final writing = c.chapters.firstWhere(
      (x) => x.status == ChapterStatus.writing,
    );

    expect(writing.nextQuestionText, isNotNull);
    expect(writing.subtitle, startsWith('다음 질문 · '));
  });

  test('빈 상태 문구는 첫 장을 가리킨다', () async {
    final c = await build();

    expect(c.emptyCtaLabel, '1장 시작하기');
    expect(c.emptyCaption, '1장 어린 시절의 질문 8개를 준비해뒀어요');
    expect(c.emptyProgressCaption, '5장 · 질문 34개가 기다리고 있어요');
  });
}
