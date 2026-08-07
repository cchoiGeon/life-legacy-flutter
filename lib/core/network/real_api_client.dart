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
  Future<AuthSession> loginWithKakao(
    String kakaoAccessToken, {
    String? name,
    String? email,
  }) async {
    final body = await _post('/auth/kakao', {
      'kakao_access_token': kakaoAccessToken,
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
    });

    return AuthSession.fromJson(body!);
  }

  @override
  Future<AuthSession> loginWithCredentials({
    required String loginId,
    required String password,
  }) async {
    final body = await _post('/auth/login', {
      'login_id': loginId,
      'password': password,
    });

    return AuthSession.fromJson(body!);
  }

  @override
  Future<User> setCredentials({
    required String loginId,
    required String password,
  }) async {
    final body = await _post('/auth/credentials', {
      'login_id': loginId,
      'password': password,
    });

    return User.fromJson(body!);
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
  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final form = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/me/avatar',
        data: form,
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<List<int>?> fetchAvatarBytes() async {
    try {
      final response = await _dio.get<List<int>>(
        '/users/me/avatar',
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (s) => s != null && (s == 200 || s == 404),
        ),
      );
      if (response.statusCode == 404) return null;
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _toApiException(e);
    }
  }

  @override
  Future<void> logout() => _post('/auth/logout', null);

  // ══════════════════════════════════════════════════════════
  // OCTOMO 인증 (신규)
  // ══════════════════════════════════════════════════════════

  @override
  Future<PhoneLookupResult> lookupPhone(String phone) async {
    final body = await _post('/auth/phone/lookup', {'phone': phone});
    return PhoneLookupResult.fromJson(body!);
  }

  @override
  Future<OctomoChallenge> requestOctomoChallenge(String phone) async {
    final body = await _post('/auth/octomo/challenge', {'phone': phone});
    return OctomoChallenge.fromJson(body!);
  }

  @override
  Future<OctomoVerifyResult> verifyOctomo(
    String sessionId, {
    bool link = false,
  }) async {
    final body = await _post('/auth/octomo/verify', {
      'session_id': sessionId,
      if (link) 'link': true,
    });
    return OctomoVerifyResult.fromJson(body!);
  }

  @override
  Future<AuthSession> signUp({
    required String signupToken,
    required String name,
    required List<ConsentAgreement> consents,
  }) async {
    final body = await _post('/auth/signup', {
      'signup_token': signupToken,
      'name': name,
      'consents': consents.map((c) => c.toJson()).toList(),
    });
    return AuthSession.fromJson(body!);
  }

  @override
  Future<List<ConsentDocument>> consentDocuments({
    bool consentOnly = false,
  }) async {
    final q = consentOnly ? '?consent_only=1' : '';
    final items = await _getItems('/consents/documents$q');
    return items.map(ConsentDocument.fromJson).toList();
  }

  @override
  Future<ConsentDocument> consentDocument(String key) async {
    final body = await _get('/consents/documents/$key');
    return ConsentDocument.fromJson(body!);
  }

  @override
  Future<AuthSession> saveConsents(List<ConsentAgreement> consents) async {
    final body = await _post('/auth/consents', {
      'consents': consents.map((c) => c.toJson()).toList(),
    });
    return AuthSession.fromJson(body!);
  }

  @override
  Future<AuthSession> linkPhone(String sessionId) async {
    final body = await _post('/auth/phone/link', {
      'session_id': sessionId,
    });
    return AuthSession.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<IntroQuestion>> introQuestions() async {
    final items = await _getItems('/intro/questions');

    return items.map(IntroQuestion.fromJson).toList();
  }

  @override
  Future<WritingPlanResult> writingPlan() async {
    final body = await _get('/intro/writing-plan');
    return WritingPlanResult.fromJson(body!);
  }

  @override
  Future<WritingPlanResult> updateWritingPlan(WritingPlan plan) async {
    final body = await _put('/intro/writing-plan', plan.toJson());
    return WritingPlanResult.fromJson(body!);
  }

  @override
  Future<TocGenerateResult> generateToc(
    List<IntroAnswerSubmission> answers,
  ) async {
    final body = await _post('/intro/answers', {
      'answers': [for (final a in answers) a.toJson()],
    });

    return TocGenerateResult.fromJson(body!);
  }

  @override
  Future<List<CatalogChapter>> catalogChapters(String bookId) async {
    final items = await _getItems('/catalog/chapters?book_id=$bookId');
    return items.map(CatalogChapter.fromJson).toList();
  }

  @override
  Future<List<Chapter>> saveTocDraft({
    required String bookId,
    required List<TocDraftChapter> chapters,
  }) async {
    final body = await _patch('/intro/toc/draft', {
      'book_id': bookId,
      'chapters': [for (final c in chapters) c.toJson()],
    });
    final list = body?['chapters'] as List? ?? const [];
    return list
        .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TocConfirmResult> confirmToc({
    required String bookId,
    required List<Chapter> chapters,
  }) async {
    final body = await _post('/intro/toc/confirm', {
      'book_id': bookId,
      'chapter_ids': [for (final c in chapters) c.id],
    });
    return TocConfirmResult.fromJson(body!);
  }

  @override
  Future<IntroProfile> introProfile() async {
    final body = await _get('/intro/profile');

    return IntroProfile.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  @override
  Future<HomeSummary> home(String bookId) async {
    final body = await _get('/books/$bookId/home');

    return HomeSummary.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // 작성
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<Chapter>> chapters(String bookId) async {
    final items = await _getItems('/books/$bookId/chapters');

    return items.map(Chapter.fromJson).toList();
  }

  @override
  Future<Question?> currentQuestion(String bookId) async {
    final body = await _get('/books/$bookId/questions/current');
    if (body == null) return null;
    return Question.fromJson(body);
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
  Future<FollowupAdvanceResult> submitFollowupAnswer({
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

    return FollowupAdvanceResult.fromJson(body!);
  }

  @override
  Future<Question?> skipQuestion(String questionId) async {
    final body = await _post('/questions/$questionId/skip', null);

    return _nextQuestion(body!);
  }

  @override
  Future<AnswerDraft> saveAnswerDraft({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    final body = await _put('/questions/$questionId/draft', {
      'text': text,
      'input_mode': inputMode.wire,
      if (spokenSeconds != null) 'spoken_seconds': spokenSeconds,
    });
    return AnswerDraft.fromJson(body!);
  }

  @override
  Future<AnswerDraft?> answerDraft(String questionId) async {
    final body = await _get('/questions/$questionId/draft');
    if (body == null) return null;
    return AnswerDraft.fromJson(body);
  }

  @override
  Future<void> deleteAnswerDraft(String questionId) async {
    await _send(() => _dio.delete<dynamic>('/questions/$questionId/draft'));
  }

  @override
  Future<ChapterReview?> chapterReview(String bookId, String chapterId) async {
    final body = await _get('/books/$bookId/chapters/$chapterId/review');
    if (body == null) return null;
    return ChapterReview.fromJson(body);
  }

  @override
  Future<ChapterReview> synthesizeReview(String bookId, String chapterId) async {
    final body = await _post(
      '/books/$bookId/chapters/$chapterId/review/synthesize',
      null,
    );
    return ChapterReview.fromJson(body!);
  }

  @override
  Future<ChapterReview> saveReview({
    required String bookId,
    required String chapterId,
    required int version,
    String? body,
    String status = 'reviewed',
  }) async {
    final response = await _patch('/books/$bookId/chapters/$chapterId/review', {
      'version': version,
      'status': status,
      if (body != null) 'body': body,
    });
    return ChapterReview.fromJson(response!);
  }

  @override
  Future<ReviewMedia> uploadReviewMedia({
    required String bookId,
    required String chapterId,
    required int paragraphIndex,
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
    String? caption,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(bytes, filename: filename),
        'paragraph_index': paragraphIndex,
        if (caption != null) 'caption': caption,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/books/$bookId/chapters/$chapterId/review/media',
        data: form,
      );
      final media = response.data?['media'];
      if (media is! Map<String, dynamic>) {
        throw const ApiException('사진을 올리지 못했어요');
      }
      return ReviewMedia.fromJson(media);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> deleteReviewMedia({
    required String bookId,
    required String chapterId,
    required String placementId,
  }) async {
    await _send(
      () => _dio.delete<dynamic>(
        '/books/$bookId/chapters/$chapterId/review/media/$placementId',
      ),
    );
  }

  @override
  Future<List<int>> fetchReviewMediaBytes({
    required String bookId,
    required String chapterId,
    required String placementId,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        '/books/$bookId/chapters/$chapterId/review/media/$placementId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<AiPhotoResult> generateReviewAiPhoto({
    required String bookId,
    required String chapterId,
    bool regenerate = false,
  }) async {
    final body = await _post(
      '/books/$bookId/chapters/$chapterId/review/images/generate',
      {'regenerate': regenerate},
    );
    return AiPhotoResult.fromJson(body ?? const {});
  }

  @override
  Future<ChapterCompletion> chapterCompletion(
    String bookId,
    String chapterId,
  ) async {
    final body = await _get('/books/$bookId/chapters/$chapterId/completion');
    return ChapterCompletion.fromJson(body!);
  }

  @override
  Future<void> updateReviewMedia({
    required String bookId,
    required String chapterId,
    required String placementId,
    String? caption,
    int? paragraphIndex,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/books/$bookId/chapters/$chapterId/review/media/$placementId',
        data: {
          if (caption != null) 'caption': caption,
          if (paragraphIndex != null) 'paragraph_index': paragraphIndex,
        },
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<BookPhotosResponse> bookPhotos(String bookId) async {
    final body = await _get('/books/$bookId/photos');
    return BookPhotosResponse.fromJson(body ?? const {});
  }

  @override
  Future<ChapterPhotosDetail> chapterPhotosDetail(
    String bookId,
    String chapterId,
  ) async {
    final body = await _get('/books/$bookId/photos/$chapterId');
    return ChapterPhotosDetail.fromJson(body!);
  }

  @override
  Future<VoiceAudio> synthesizeSpeech({
    required String text,
    String? voiceCode,
  }) async {
    try {
      final response = await _dio.post<List<int>>(
        '/voice/tts',
        data: {
          'text': text,
          if (voiceCode != null) 'voice_code': voiceCode,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return VoiceAudio(
        bytes: response.data ?? const [],
        durationMs: _headerInt(response.headers, 'x-voice-duration-ms'),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<SttResult> transcribeAudio({
    required List<int> bytes,
    required String filename,
    String contentType = 'audio/mp4',
    int? durationMs,
  }) async {
    try {
      final form = FormData.fromMap({
        'audio': MultipartFile.fromBytes(bytes, filename: filename),
        if (durationMs != null) 'duration_ms': durationMs,
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/voice/stt',
        data: form,
      );
      return SttResult.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<VoiceAudio> voiceSample({String? voiceCode}) async {
    try {
      final response = await _dio.get<List<int>>(
        '/voice/sample',
        queryParameters: {
          if (voiceCode != null) 'voice_code': voiceCode,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return VoiceAudio(bytes: response.data ?? const []);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<VoiceAudio> reviewTts({
    required String bookId,
    required String chapterId,
    int fromParagraph = 0,
    int chunkSize = 2,
    String? voiceCode,
  }) async {
    try {
      final response = await _dio.post<List<int>>(
        '/books/$bookId/chapters/$chapterId/review/tts',
        data: {
          'from_paragraph': fromParagraph,
          'chunk_size': chunkSize,
          if (voiceCode != null) 'voice_code': voiceCode,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final next = _headerInt(response.headers, 'x-next-paragraph');
      return VoiceAudio(
        bytes: response.data ?? const [],
        durationMs: _headerInt(response.headers, 'x-voice-duration-ms'),
        nextParagraph: next == -1 ? null : next,
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  int? _headerInt(Headers headers, String name) {
    final raw = headers.value(name);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<BookListItem>> books() async {
    final items = await _getItems('/books');
    return items.map(BookListItem.fromJson).toList();
  }

  @override
  Future<Book> book(String bookId) async {
    final body = await _get('/books/$bookId');

    return Book.fromJson(body!);
  }

  @override
  Future<List<BookPage>> bookPages(String bookId) async {
    final items = await _getItems('/books/$bookId/pages');

    return items.map(BookPage.fromJson).toList();
  }

  @override
  Future<EbookEligibility> ebookEligibility(String bookId) async {
    final body = await _get('/books/$bookId/ebook/eligibility');
    return EbookEligibility.fromJson(body!);
  }

  @override
  Future<PlanEntitlements> entitlements(String bookId) async {
    final body = await _get('/books/$bookId/entitlements');
    return PlanEntitlements.fromJson(body!);
  }

  @override
  Future<CouponRedeemResult> redeemCoupon(String code) async {
    final body = await _post('/coupons/redeem', {'code': code.trim()});
    return CouponRedeemResult.fromJson(body!);
  }

  @override
  Future<EbookExportResult> generateEbook(String bookId) async {
    final body = await _post('/books/$bookId/ebook/generate', null);
    return EbookExportResult.fromJson(body!);
  }

  @override
  Future<List<int>> downloadEbookFile(String bookId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/books/$bookId/ebook/file',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<List<String>> suggestEbookTitles(String bookId) async {
    final body = await _post('/books/$bookId/ebook/titles/suggest', null);
    return ((body?['titles'] as List?) ?? const [])
        .map((e) => e as String)
        .toList();
  }

  @override
  Future<void> updateEbookMetadata(
    String bookId, {
    required String title,
  }) async {
    await _patch('/books/$bookId/ebook/metadata', {'title': title});
  }

  @override
  Future<AudiobookOverview> audiobook(String bookId) async {
    final body = await _get('/books/$bookId/audiobook');
    return AudiobookOverview.fromJson(body!);
  }

  @override
  Future<List<AudiobookVoice>> audiobookVoices(String bookId) async {
    final body = await _get('/books/$bookId/audiobook/voices');
    final items = (body?['items'] as List?) ?? const [];
    return items
        .map((e) => AudiobookVoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<int>> audiobookVoicePreview(
    String bookId,
    String voiceCode,
  ) async {
    try {
      final response = await _dio.post<List<int>>(
        '/books/$bookId/audiobook/voice-preview',
        data: {'voice_code': voiceCode},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<List<AudiobookBgmTrack>> audiobookBgms(String bookId) async {
    final body = await _get('/books/$bookId/audiobook/bgms');
    final items = (body?['items'] as List?) ?? const [];
    return items
        .map((e) => AudiobookBgmTrack.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AudiobookJobCreated> createAudiobookJob({
    required String bookId,
    required String chapterId,
    required String voiceCode,
    required String idempotencyKey,
    String? bgmTrackId,
  }) async {
    final body = await _post(
      '/books/$bookId/audiobook/chapters/$chapterId/jobs',
      {
        'voice_code': voiceCode,
        'idempotency_key': idempotencyKey,
        if (bgmTrackId != null) 'bgm_track_id': bgmTrackId,
      },
    );
    return AudiobookJobCreated.fromJson(body!);
  }

  @override
  Future<AudiobookJobStatus> audiobookJob(String bookId, String jobId) async {
    final body = await _get('/books/$bookId/audiobook/jobs/$jobId');
    return AudiobookJobStatus.fromJson(body!);
  }

  @override
  Future<AudiobookJobStatus> cancelAudiobookJob(
    String bookId,
    String jobId,
  ) async {
    final body = await _post(
      '/books/$bookId/audiobook/jobs/$jobId/cancel',
      null,
    );
    return AudiobookJobStatus.fromJson(body!);
  }

  @override
  Future<List<int>> audiobookChapterAudio(
    String bookId,
    String chapterId, {
    bool download = false,
  }) async {
    try {
      final path = download
          ? '/books/$bookId/audiobook/chapters/$chapterId/downloads'
          : '/books/$bookId/audiobook/chapters/$chapterId/stream';
      final response = download
          ? await _dio.post<List<int>>(
              path,
              options: Options(responseType: ResponseType.bytes),
            )
          : await _dio.get<List<int>>(
              path,
              options: Options(responseType: ResponseType.bytes),
            );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw _toApiException(e);
    }
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

  @override
  Future<List<AppNotification>> markNotificationRead(String id) async {
    final body = await _post('/notifications/$id/read', null);

    return (body!['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> registerDevicePushToken({
    required String platform,
    required String token,
  }) async {
    await _post('/device-push-tokens', {
      'platform': platform,
      'token': token,
    });
  }

  @override
  Future<void> revokeDevicePushToken(String token) async {
    await _delete('/device-push-tokens/${Uri.encodeComponent(token)}');
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

  @override
  Future<PrintOrderResult> createPrintOrder({
    required String bookId,
    required int quantity,
    String? note,
  }) async {
    final body = await _post('/print-orders', {
      'book_id': bookId,
      'quantity': quantity,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });

    return PrintOrderResult.fromJson(body!);
  }

  // ══════════════════════════════════════════════════════════
  // FAQ · QnA
  // ══════════════════════════════════════════════════════════

  @override
  Future<FaqCatalog> faq() async {
    final body = await _get('/faq');

    return FaqCatalog.fromJson(body!);
  }

  @override
  Future<List<PublishedQna>> publishedQna() async {
    final items = await _getItems('/qna/published');

    return items.map(PublishedQna.fromJson).toList();
  }

  @override
  Future<List<QnaItem>> myQna() async {
    final items = await _getItems('/qna/me');

    return items.map(QnaItem.fromJson).toList();
  }

  @override
  Future<QnaItem> createQna({
    required String question,
    String? category,
  }) async {
    final body = await _post('/qna', {
      'question': question,
      if (category != null) 'category': category,
    });

    return QnaItem.fromJson(body!);
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

  Future<Map<String, dynamic>?> _delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

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
