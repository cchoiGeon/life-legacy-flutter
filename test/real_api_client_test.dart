import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/real_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'support/test_env.dart';

/// 서버 계약(`docs/api-spec.md`)을 앱 모델로 옮기는 규칙을 잠근다.
///
/// 여기서 틀리면 화면은 멀쩡히 그려지는데 값이 비거나 엉뚱해진다 —
/// 목업으로는 절대 드러나지 않는 종류의 버그다.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter();

  /// 경로 → (상태코드, 본문)
  final Map<String, (int, Object?)> routes = {};

  /// 마지막으로 보낸 요청 — "무엇을 보냈는지"를 확인한다.
  RequestOptions? lastRequest;

  void on(String path, {int status = 200, Object? body}) {
    routes[path] = (status, body);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    final route = routes[options.path];
    if (route == null) {
      return ResponseBody.fromString('{}', 404);
    }

    final (status, body) = route;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() => initTestEnv('real_api'));

  (RealApiClient, _FakeAdapter) build() {
    final adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test/v1'))
      ..httpClientAdapter = adapter;
    return (RealApiClient(dio), adapter);
  }

  group('목록 응답', () {
    test('items 껍질을 벗겨서 돌려준다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/books/b1/chapters',
        body: {
          'items': [
            {
              'id': 'c1',
              'order': 1,
              'title': '탄생과 유아기 시절',
              'status': 'writing',
              'answered_count': 2,
              'question_count': 5,
              'next_question_text': '다음 질문',
            },
          ],
        },
      );

      final chapters = await api.chapters('b1');

      expect(chapters, hasLength(1));
      expect(chapters.first.title, '탄생과 유아기 시절');
      expect(chapters.first.status, ChapterStatus.writing);
      expect(chapters.first.nextQuestionText, '다음 질문');
    });

    test('자기소개 문항의 선택지도 그대로 실려 온다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/intro/questions',
        body: {
          'items': [
            {
              'id': 'i5',
              'order': 5,
              'text': '학교는 어디까지\n다니셨나요?',
              'subtitle': '학창 시절 질문을 고를 때 써요',
              'hint': null,
              'choices': ['초등학교', '중학교', '고등학교', '대학교 이상'],
            },
          ],
        },
      );

      final questions = await api.introQuestions();

      // 선택지가 비면 앱이 4지선다를 텍스트 입력으로 그린다.
      expect(questions.first.choices, hasLength(4));
      expect(questions.first.type, IntroAnswerType.choice);
    });
  });

  group('본문 없는 응답', () {
    test('204면 "더 답할 질문이 없다"로 읽는다', () async {
      final (api, adapter) = build();
      adapter.on('/books/b1/questions/current', status: 204);

      // 이걸 예외로 처리하면 앱이 완성 화면 대신 오류를 띄운다.
      expect(await api.currentQuestion('b1'), isNull);
    });

    test('204인 목차 확정은 성공으로 본다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/intro/toc/confirm',
        body: {
          'book_id': 'b1',
          'first_question_id': null,
          'chapters': [],
        },
      );

      await expectLater(
        api.confirmToc(bookId: 'b1', chapters: const []),
        completes,
      );
    });
  });

  group('에러 변환', () {
    test('서버 code·message를 그대로 ApiException으로 옮긴다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/auth/phone/verify',
        status: 401,
        body: {'code': 'INVALID_CODE', 'message': '인증번호가 일치하지 않아요'},
      );

      await expectLater(
        api.verifyCode(phone: '01012345678', code: '000000'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'INVALID_CODE')
              // 앱은 이 문장을 토스트에 그대로 띄운다.
              .having((e) => e.message, 'message', '인증번호가 일치하지 않아요'),
        ),
      );
    });

    test('본문이 없는 실패도 사용자에게 보여줄 문장을 만든다', () async {
      final (api, adapter) = build();
      adapter.on('/books/b1/home', status: 500);

      await expectLater(
        api.home('b1'),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', isNotEmpty),
        ),
      );
    });
  });

  group('작성 흐름', () {
    test('1차 답변은 입력 방식과 말한 시간을 함께 보낸다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/questions/q1/answer',
        body: {
          'followup': {'id': 'f1', 'text': '이어서 여쭤볼게요'},
        },
      );

      final followup = await api.submitAnswer(
        questionId: 'q1',
        text: '제주도에 갔습니다',
        inputMode: ComposeMode.voice,
        spokenSeconds: 42,
      );

      expect(followup.id, 'f1');
      final sent = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(sent['input_mode'], 'voice');
      expect(sent['spoken_seconds'], 42);
    });

    test('꼬리답변을 저장하면 다음 질문이 온다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/questions/q1/followup/f1/answer',
        body: {
          'next_question': {
            'id': 'q2',
            'chapter_id': 'c1',
            'order': 2,
            'text': '다음 질문',
            'answer': null,
          },
          'chapter_completed': false,
        },
      );

      final advance = await api.submitFollowupAnswer(
        questionId: 'q1',
        followupId: 'f1',
        text: '성산일출봉이었습니다',
        inputMode: ComposeMode.keyboard,
      );

      expect(advance.needsAnotherFollowup, isFalse);
      expect(advance.nextQuestion?.id, 'q2');
    });

    test('중간 라운드면 followup이 온다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/questions/q1/followup/f1/answer',
        body: {
          'followup': {'id': 'f2', 'seq': 2, 'text': '조금 더 들려주세요'},
          'next_question': null,
          'chapter_completed': false,
        },
      );

      final advance = await api.submitFollowupAnswer(
        questionId: 'q1',
        followupId: 'f1',
        text: '첫 꼬리 답',
        inputMode: ComposeMode.keyboard,
      );

      expect(advance.needsAnotherFollowup, isTrue);
      expect(advance.followup?.id, 'f2');
      expect(advance.followup?.seq, 2);
      expect(advance.nextQuestion, isNull);
    });

    test('모든 장을 끝내면 다음 질문이 null이다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/questions/q1/followup/f1/answer',
        body: {'next_question': null, 'chapter_completed': true},
      );

      final advance = await api.submitFollowupAnswer(
        questionId: 'q1',
        followupId: 'f1',
        text: '끝',
        inputMode: ComposeMode.keyboard,
      );

      // 앱은 nextQuestion null을 "다 끝났다"로 읽고 자서전 화면으로 간다.
      expect(advance.needsAnotherFollowup, isFalse);
      expect(advance.nextQuestion, isNull);
      expect(advance.chapterCompleted, isTrue);
    });

    test('키보드로 적으면 말한 시간을 아예 빼고 보낸다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/questions/q1/answer',
        body: {
          'followup': {'id': 'f1', 'text': '…'},
        },
      );

      await api.submitAnswer(
        questionId: 'q1',
        text: '적었습니다',
        inputMode: ComposeMode.keyboard,
      );

      final sent = adapter.lastRequest!.data as Map<String, dynamic>;
      // 0을 보내면 "0초 말했다"로 읽힌다.
      expect(sent.containsKey('spoken_seconds'), isFalse);
    });
  });

  group('자기소개 제출', () {
    test('구조화 답변으로 보내고 book_id·목차를 받는다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/intro/answers',
        body: {
          'book_id': 'b1',
          'case_key': 'legacy_college_married_children',
          'chapters': [
            {
              'id': 'c1',
              'order': 1,
              'title': '탄생과 유아기 시절',
              'status': 'writing',
              'answered_count': 0,
              'question_count': 5,
              'next_question_text': null,
            },
          ],
        },
      );

      final result = await api.generateToc(const [
        IntroAnswerSubmission(questionId: 'i2', value: '여'),
        IntroAnswerSubmission(questionId: 'i6', value: '1955-03-12'),
      ]);

      expect(result.bookId, 'b1');
      expect(result.chapters, hasLength(1));
      final sent = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(sent['answers'], [
        {'question_id': 'i2', 'value': '여'},
        {'question_id': 'i6', 'value': '1955-03-12'},
      ]);
    });

    test('목차 확정은 앱이 재배열한 순서 그대로 보낸다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/intro/toc/confirm',
        body: {
          'book_id': 'b1',
          'first_question_id': 'q1',
          'chapters': [],
        },
      );

      await api.confirmToc(
        bookId: 'b1',
        chapters: [
          const Chapter(
            id: 'c2',
            order: 2,
            title: '나중 장',
            status: ChapterStatus.locked,
            answeredCount: 0,
            questionCount: 5,
          ),
          const Chapter(
            id: 'c1',
            order: 1,
            title: '먼저 장',
            status: ChapterStatus.writing,
            answeredCount: 0,
            questionCount: 5,
          ),
        ],
      );

      final sent = adapter.lastRequest!.data as Map<String, dynamic>;
      expect(sent['book_id'], 'b1');
      expect(sent['chapter_ids'], ['c2', 'c1']);
    });
  });

  group('챕터 완료', () {
    test('completion 응답을 모델로 읽는다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/books/b1/chapters/c2/completion',
        body: {
          'chapter_id': 'c2',
          'chapter_order': 2,
          'chapter_title': '가족',
          'question_count': 6,
          'answered_count': 5,
          'skipped_count': 1,
          'review_status': null,
          'next_chapter': {'id': 'c3', 'order': 3, 'title': '청소년기'},
          'actions': {'review': true, 'hub': true},
        },
      );

      final c = await api.chapterCompletion('b1', 'c2');
      expect(c.chapterOrder, 2);
      expect(c.needsReview, isTrue);
      expect(c.nextChapter?.title, '청소년기');
      expect(c.canReview, isTrue);
    });
  });

  group('인증', () {
    test('세션에서 토큰 두 개와 needs_intro를 읽는다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/auth/phone/verify',
        body: {
          'access_token': 'at',
          'refresh_token': 'rt',
          'expires_in': 3600,
          'needs_intro': true,
          'user': {
            'id': 'u1',
            'name': '김영희',
            'phone': '01012345678',
            'child_linked': false,
          },
        },
      );

      final session = await api.verifyCode(
        phone: '01012345678',
        code: '482915',
      );

      expect(session.tokens.accessToken, 'at');
      expect(session.tokens.refreshToken, 'rt');
      expect(session.needsIntro, isTrue);
      expect(session.user.name, '김영희');
    });

    test('인증번호 발송은 서버가 준 두 시간을 그대로 읽는다', () async {
      final (api, adapter) = build();
      adapter.on(
        '/auth/phone/code',
        body: {'expires_in': 180, 'resend_after': 30},
      );

      final challenge = await api.requestVerificationCode('01012345678');

      expect(challenge.expiresIn, const Duration(seconds: 180));
      expect(challenge.resendAfter, const Duration(seconds: 30));
    });
  });
}
