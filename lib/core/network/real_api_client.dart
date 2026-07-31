import 'package:dio/dio.dart';

import 'package:life_legacy/data/data_manager.dart';

import 'api_client.dart';

/// 실제 서버 구현 — `docs/api-spec.md` 계약을 그대로 옮긴 것.
///
/// ⚠️ 응답은 **래퍼가 없다.** 단건은 리소스 그대로, 목록은 `items`로만 감싼다.
///    서버가 앱 계약에 맞춘 결과라 여기서 벗겨 낼 껍질이 하나뿐이다.
///
/// ⚠️ 실패 응답은 `{ code, message }`이고 `message`는 **사용자에게 그대로
///    보여줄 한국어 문장**이다. 화면은 그 문장을 토스트에 바로 띄운다.
class RealApiClient implements ApiClient {
  RealApiClient(this._dio);

  final Dio _dio;

  // ══════════════════════════════════════════════════════════
  // 인증
  // ══════════════════════════════════════════════════════════

  @override
  Future<VerificationChallenge> requestVerificationCode(String phone) async {
    final body = await _post('/auth/phone/code', {'phone': phone});

    return VerificationChallenge.fromJson(body!);
  }

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    final body = await _post('/auth/phone/verify', {
      'phone': phone,
      'code': code,
    });

    return AuthSession.fromJson(body!);
  }

  @override
  Future<AuthSession> loginWithKakao() async {
    // 카카오 SDK를 아직 붙이지 않아 빈 토큰을 보낸다. 서버도 스텁이라
    // 검증하지 않는다 — SDK가 붙으면 여기에 실제 토큰이 들어간다.
    final body = await _post('/auth/kakao', {'kakao_access_token': 'stub'});

    return AuthSession.fromJson(body!);
  }

  @override
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final body = await _post('/auth/refresh', {'refresh_token': refreshToken});

    return AuthTokens.fromJson(body!);
  }

  @override
  Future<User> me() async {
    final body = await _get('/users/me');

    return User.fromJson(body!);
  }

  @override
  Future<void> logout() => _post('/auth/logout', null);

  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<IntroQuestion>> introQuestions() async {
    final items = await _getItems('/intro/questions');

    return items.map(IntroQuestion.fromJson).toList();
  }

  @override
  Future<List<Chapter>> generateToc(Map<String, String> answers) async {
    final body = await _post('/intro/answers', {
      'answers': [
        for (final entry in answers.entries)
          {'question_id': entry.key, 'value': entry.value},
      ],
    });

    // 응답에 case_key도 오지만 화면이 쓰지 않는다 — 목차만 꺼낸다.
    return (body!['chapters'] as List)
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> confirmToc(List<Chapter> chapters) => _post(
    '/intro/toc/confirm',
    // 사용자가 "순서 바꾸기"로 재배열한 그대로 보낸다. 서버가 이 순서대로
    // order를 다시 매긴다.
    {'chapter_ids': [for (final c in chapters) c.id]},
  );

  @override
  Future<IntroProfile> introProfile() async {
    final body = await _get('/intro/profile');

    return IntroProfile.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  @override
  Future<HomeSummary> home() async {
    final body = await _get('/home');

    return HomeSummary.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 작성
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<Chapter>> chapters() async {
    final items = await _getItems('/chapters');

    return items.map(Chapter.fromJson).toList();
  }

  @override
  Future<Question?> currentQuestion() async {
    final body = await _get('/questions/current');

    // ⚠️ 204 No Content = 모든 장을 끝냈다는 뜻이다. 예외로 다루면 앱이
    //    완성 화면 대신 오류를 띄운다.
    return body == null ? null : Question.fromJson(body);
  }

  @override
  Future<Question> question(String questionId) async {
    final body = await _get('/questions/$questionId');

    return Question.fromJson(body!);
  }

  @override
  Future<Question> updateQuestionText({
    required String questionId,
    required String text,
  }) async {
    final body = await _patch('/questions/$questionId', {'text': text});

    return Question.fromJson(body!);
  }

  @override
  Future<Followup> submitAnswer({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    final body = await _post(
      '/questions/$questionId/answer',
      _answerBody(text, inputMode, spokenSeconds),
    );

    return Followup.fromJson(body!['followup'] as Map<String, dynamic>);
  }

  @override
  Future<Question?> submitFollowupAnswer({
    required String questionId,
    required String followupId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    final body = await _post(
      '/questions/$questionId/followup/$followupId/answer',
      _answerBody(text, inputMode, spokenSeconds),
    );

    return _nextQuestion(body!);
  }

  @override
  Future<Question?> skipQuestion(String questionId) async {
    final body = await _post('/questions/$questionId/skip', null);

    return _nextQuestion(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  @override
  Future<Book> book() async {
    final body = await _get('/book');

    return Book.fromJson(body!);
  }

  @override
  Future<List<BookPage>> bookPages() async {
    final items = await _getItems('/book/pages');

    return items.map(BookPage.fromJson).toList();
  }

  // ══════════════════════════════════════════════════════════
  // 알림
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<AppNotification>> notifications() async {
    final items = await _getItems('/notifications');

    return items.map(AppNotification.fromJson).toList();
  }

  @override
  Future<List<AppNotification>> markAllNotificationsRead() async {
    final body = await _post('/notifications/read-all', null);

    return (body!['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ══════════════════════════════════════════════════════════
  // 설정
  // ══════════════════════════════════════════════════════════

  @override
  Future<AppSettings> settings() async {
    final body = await _get('/settings');

    return AppSettings.fromJson(body!);
  }

  @override
  Future<AppSettings> updateSettings(AppSettings next) async {
    final body = await _patch('/settings', next.toJson());

    return AppSettings.fromJson(body!);
  }

  @override
  Future<Address> shippingAddress() async {
    final body = await _get('/shipping-address');

    return Address.fromJson(body!);
  }

  @override
  Future<Address> updateShippingAddress(Address next) async {
    final body = await _put('/shipping-address', next.toJson());

    return Address.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 공통
  // ══════════════════════════════════════════════════════════

  /// 음성이면 말한 시간을 싣고, 키보드면 **키 자체를 뺀다.**
  /// 0을 보내면 서버가 "0초 말했다"로 읽는다.
  Map<String, dynamic> _answerBody(
    String text,
    ComposeMode inputMode,
    int? spokenSeconds,
  ) => {
    'text': text,
    'input_mode': inputMode.wire,
    if (inputMode == ComposeMode.voice && spokenSeconds != null)
      'spoken_seconds': spokenSeconds,
  };

  Question? _nextQuestion(Map<String, dynamic> body) {
    final next = body['next_question'];

    // null이면 모든 장을 끝냈다는 뜻이다.
    return next == null ? null : Question.fromJson(next as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>?> _get(String path) =>
      _send(() => _dio.get<dynamic>(path));

  Future<Map<String, dynamic>?> _post(String path, Object? data) =>
      _send(() => _dio.post<dynamic>(path, data: data));

  Future<Map<String, dynamic>?> _patch(String path, Object? data) =>
      _send(() => _dio.patch<dynamic>(path, data: data));

  Future<Map<String, dynamic>?> _put(String path, Object? data) =>
      _send(() => _dio.put<dynamic>(path, data: data));

  Future<List<Map<String, dynamic>>> _getItems(String path) async {
    final body = await _get(path);

    return ((body?['items'] as List?) ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  /// dio 예외를 앱이 아는 [ApiException]으로 바꾼다.
  ///
  /// 화면이 dio 타입을 직접 알지 않도록 변환을 여기 한 곳에 모은다.
  Future<Map<String, dynamic>?> _send(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      final data = response.data;

      // 204 No Content — 본문이 비어 있다.
      if (data == null || (data is String && data.isEmpty)) {
        return null;
      }

      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return ApiException(
        data['message'] as String,
        code: data['code'] as String?,
      );
    }

    // 서버가 형태를 못 갖춘 실패(끊김·타임아웃·5xx 빈 본문)도 사용자에게는
    // 읽을 수 있는 한 문장이어야 한다.
    return ApiException(
      switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => '응답이 늦어지고 있어요. 다시 시도해 주세요',
        DioExceptionType.connectionError => '인터넷 연결을 확인해 주세요',
        _ => '잠시 문제가 생겼어요. 다시 시도해 주세요',
      },
      code: 'SERVER_ERROR',
    );
  }
}
