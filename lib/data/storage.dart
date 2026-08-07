import 'package:get_storage/get_storage.dart';

/// 로컬 저장소 래퍼 — 세션 토큰과 온보딩 통과 여부를 들고 있는다.
///
/// GetStorage를 직접 부르는 곳을 여기 하나로 묶어서, 나중에 보안 저장소
/// (flutter_secure_storage 등)로 바꿀 때 이 파일만 고치면 되게 했다.
abstract final class Storage {
  static const _keyAccessToken = 'll.access';
  static const _keyRefreshToken = 'll.refresh';
  static const _keyIntroDone = 'll.intro_done';
  static const _keyPhone = 'll.phone';
  static const _keyCurrentBookId = 'll.current_book_id';
  static const _keyWriteTutorialDone = 'll.write_tutorial_done';
  static const _keyLoginProvider = 'll.login_provider';
  static const _keyQuestionFontLevel = 'll.question_font_level';
  static const _keyFcmToken = 'll.fcm_token';
  static const _keyPushPermissionAsked = 'll.push_permission_asked';

  static late final GetStorage _box;

  static Future<void> init() async {
    await GetStorage.init();
    _box = GetStorage();
  }

  static String? get accessToken => _box.read<String>(_keyAccessToken);

  /// 액세스 토큰이 만료됐을 때 새로 받아오는 데 쓴다.
  ///
  /// ⚠️ 액세스 토큰보다 훨씬 오래(60일) 살아 있어서 새어 나가면 피해가 크다.
  ///    GetStorage는 평문 파일이다 — flutter_secure_storage로 옮길 때
  ///    가장 먼저 옮겨야 할 값이 이것이다.
  static String? get refreshToken => _box.read<String>(_keyRefreshToken);

  /// 자기소개 → 목차 확정까지 끝냈는지.
  /// 스플래시가 로그인/자기소개/홈 중 어디로 보낼지 정하는 근거다.
  static bool get introDone => _box.read<bool>(_keyIntroDone) ?? false;

  /// 작성 튜토리얼을 끝까지 보거나 건너뛰었는지 (기기 로컬).
  static bool get writeTutorialDone =>
      _box.read<bool>(_keyWriteTutorialDone) ?? false;

  /// 질문 글자 크기 단계 (0=작게 … 기본 1=보통 … 3=더 크게).
  static int get questionFontLevel =>
      _box.read<int>(_keyQuestionFontLevel) ?? 1;

  /// 마지막으로 인증에 사용한 전화번호.
  static String? get phone => _box.read<String>(_keyPhone);

  /// 현재 작업 중인 책. `/books/{id}/…` 호출에 쓴다.
  static String? get currentBookId => _box.read<String>(_keyCurrentBookId);

  /// 마지막 로그인 수단 — `kakao` | `phone` | `credentials`.
  static String? get loginProvider => _box.read<String>(_keyLoginProvider);

  /// 마지막 등록한 FCM 토큰 (로그아웃 폐기용).
  static String? get fcmToken => _box.read<String>(_keyFcmToken);

  /// OS 알림 권한을 이미 물어봤는지 (거절 후 반복 프롬프트 방지).
  static bool get pushPermissionAsked =>
      _box.read<bool>(_keyPushPermissionAsked) ?? false;

  static bool get isLoggedIn => accessToken != null;

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _box.write(_keyAccessToken, accessToken);
    await _box.write(_keyRefreshToken, refreshToken);
  }

  static Future<void> savePhone(String phone) =>
      _box.write(_keyPhone, phone);

  static Future<void> markIntroDone() => _box.write(_keyIntroDone, true);

  static Future<void> markWriteTutorialDone() =>
      _box.write(_keyWriteTutorialDone, true);

  static Future<void> saveQuestionFontLevel(int level) =>
      _box.write(_keyQuestionFontLevel, level);

  static Future<void> saveCurrentBookId(String bookId) =>
      _box.write(_keyCurrentBookId, bookId);

  static Future<void> saveLoginProvider(String provider) =>
      _box.write(_keyLoginProvider, provider);

  static Future<void> saveFcmToken(String token) =>
      _box.write(_keyFcmToken, token);

  static Future<void> clearFcmToken() => _box.remove(_keyFcmToken);

  static Future<void> markPushPermissionAsked() =>
      _box.write(_keyPushPermissionAsked, true);

  static Future<void> clearSession() async {
    await _box.remove(_keyAccessToken);
    await _box.remove(_keyRefreshToken);
    await _box.remove(_keyIntroDone);
    // 전화번호는 유지 — 재로그인 시 입력란에 자동으로 채운다.
    await _box.remove(_keyCurrentBookId);
    await _box.remove(_keyLoginProvider);
    await _box.remove(_keyFcmToken);
  }
}
