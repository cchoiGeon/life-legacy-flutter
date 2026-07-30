import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/intro/intro_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 자기소개(B1~B5)의 **뒤집힌 규칙**을 잠근다.
///
/// 예전에는 선택지를 누르는 즉시 다음 문항으로 넘어갔고, 고른 값이 화면에
/// 남지 않았다. 시안 340:592가 이걸 뒤집었다 — 고른 값이 남고, 하단 "다음"을
/// 눌러야 넘어간다. 되돌아가면 아까 고른 값이 그대로 있어야 한다.
void main() {
  setUpAll(() => initTestEnv('intro'));

  Future<IntroController> build() async {
    final c = IntroController(MockApiClient(), ToastService());
    c.onInit();
    // 질문은 비동기로 들어온다.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return c;
  }

  test('학력 문항은 4지선다다', () async {
    final c = await build();
    final education = c.questions.last;

    expect(education.type, IntroAnswerType.choice);
    expect(education.choices, ['초등학교', '중학교', '고등학교', '대학교 이상']);
  });

  test('모든 문항에 부제가 붙는다 — 왜 묻는지 알려주는 자리다', () async {
    final c = await build();

    for (final q in c.questions) {
      expect(q.subtitle, isNotNull, reason: '${q.id}에 부제가 없다');
      expect(q.subtitle, isNotEmpty);
    }
  });

  test('선택지를 골라도 넘어가지 않는다 — "다음"이 넘긴다', () async {
    final c = await build();
    c.index.value = 1; // 성별 문항

    c.choose('여성');

    expect(c.index.value, 1, reason: '고르는 것만으로 넘어가면 안 된다');
    expect(c.selected.value, '여성', reason: '고른 값이 화면에 남아야 한다');
    expect(c.canGoNext, isTrue);

    c.next();
    expect(c.index.value, 2);
    expect(c.answers['i2'], '여성');
  });

  test('아무것도 고르지 않으면 "다음"이 눌리지 않는다', () async {
    final c = await build();
    c.index.value = 1;

    expect(c.canGoNext, isFalse);
    c.next();
    expect(c.index.value, 1);
  });

  test('뒤로 갔다 오면 고른 값이 되살아난다', () async {
    final c = await build();
    c.index.value = 1;
    c.choose('남성');
    c.next();

    c.back();

    expect(c.index.value, 1);
    expect(c.selected.value, '남성');
  });

  test('앞 문항으로 갔다가 다시 앞으로 와도 고른 값이 남는다', () async {
    final c = await build();
    c.index.value = 1;
    c.choose('여성');
    c.next(); // 결혼 문항
    c.choose('했어요');
    c.next(); // 자녀 문항
    c.back(); // 결혼
    c.back(); // 성별

    expect(c.selected.value, '여성');
    c.next();
    expect(c.selected.value, '했어요', reason: '앞으로 올 때도 되살려야 한다');
  });

  test('텍스트 문항은 입력이 있어야 넘어간다', () async {
    final c = await build();

    expect(c.canGoNext, isFalse);
    c.answerController.text = '김영희';
    expect(c.canGoNext, isTrue);

    c.next();
    expect(c.answers['i1'], '김영희');
  });

  test('버튼 문구는 다섯 문항 내내 "다음"이다', () async {
    final c = await build();

    // 시안 346:820 — 마지막 문항(B5)에도 "다음"이다.
    expect(c.ctaLabel, '다음');
    c.index.value = c.total - 1;
    expect(c.ctaLabel, '다음');
    expect(c.stepLabel, '5 / 5');
  });
}
