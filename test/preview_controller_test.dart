import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/book/preview_controller.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 책 미리보기(E2)는 **쪽 단위**로 넘긴다.
///
/// 예전에는 장 단위였다. 시안 하단이 "12 / 34쪽"으로 바뀌면서 한 장 안에서도
/// 쪽을 넘길 수 있어야 하고, 특정 장으로 들어와도 쪽번호는 책 전체 기준이어야
/// 한다("이 책 어디쯤인지"를 알려주는 숫자라서).
void main() {
  setUpAll(() => initTestEnv('preview'));

  Future<BookPreviewController> build({Chapter? chapter}) async {
    final c = BookPreviewController(MockApiClient(), ToastService());
    if (chapter != null) c.applyArguments(chapter);
    await c.load();
    return c;
  }

  test('첫 쪽에서는 이전으로 갈 수 없다', () async {
    final c = await build();

    expect(c.pages, isNotEmpty);
    expect(c.index.value, 0);
    expect(c.hasPrev, isFalse);
    expect(c.hasNext, isTrue);

    c.prev();
    expect(c.index.value, 0, reason: '경계에서 눌러도 넘어가면 안 된다');
  });

  test('마지막 쪽에서는 다음으로 갈 수 없다', () async {
    final c = await build();
    while (c.hasNext) {
      c.next();
    }

    expect(c.index.value, c.pages.length - 1);
    expect(c.hasNext, isFalse);

    c.next();
    expect(c.index.value, c.pages.length - 1);
  });

  test('쪽 표시는 "책 전체에서 몇 쪽 / 전체 몇 쪽"이다', () async {
    final c = await build();
    final p = c.page!;

    expect(c.pageLabel, '${p.pageNumber} / ${p.totalPages}쪽');
    expect(
      p.totalPages,
      greaterThan(p.pageNumber),
      reason: '전체 쪽수가 현재 쪽보다 작으면 표시가 뒤집힌다',
    );
  });

  test('장을 골라 들어오면 그 장의 쪽만 나온다 — 쪽번호는 책 전체 기준', () async {
    final chapters = await MockApiClient().chapters();
    final first = chapters.first;
    final c = await build(chapter: first);

    expect(c.pages, isNotEmpty);
    expect(
      c.pages.every((p) => p.chapterOrder == first.order),
      isTrue,
      reason: '다른 장의 쪽이 섞이면 안 된다',
    );
    expect(c.title, '${first.order}장 미리보기');

    // 앞의 표지·목차 몫만큼 밀려 있어야 한다(1쪽부터 시작하지 않는다).
    expect(c.pages.first.pageNumber, greaterThan(1));
  });

  test('장을 고르지 않으면 책 전체를 처음부터 본다', () async {
    final c = await build();

    expect(c.title, '책 미리보기');
    expect(c.pages.map((p) => p.chapterOrder).toSet().length, greaterThan(1));
  });
}
