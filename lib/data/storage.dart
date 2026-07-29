import 'package:get_storage/get_storage.dart';

/// 로컬 저장소 래퍼 — 세션 토큰과 온보딩 통과 여부를 들고 있는다.
///
/// GetStorage를 직접 부르는 곳을 여기 하나로 묶어서, 나중에 보안 저장소
/// (flutter_secure_storage 등)로 바꿀 때 이 파일만 고치면 되게 했다.
abstract final class Storage {
  static const _keyAccessToken = 'll.access';
  static const _keyIntroDone = 'll.intro_done';

  static late final GetStorage _box;

  static Future<void> init() async {
    await GetStorage.init();
    _box = GetStorage();
  }

  static String? get accessToken => _box.read<String>(_keyAccessToken);

  /// 자기소개 → 목차 확정까지 끝냈는지.
  /// 스플래시가 로그인/자기소개/홈 중 어디로 보낼지 정하는 근거다.
  static bool get introDone => _box.read<bool>(_keyIntroDone) ?? false;

  static bool get isLoggedIn => accessToken != null;

  static Future<void> saveSession(String accessToken) =>
      _box.write(_keyAccessToken, accessToken);

  static Future<void> markIntroDone() => _box.write(_keyIntroDone, true);

  static Future<void> clearSession() async {
    await _box.remove(_keyAccessToken);
    await _box.remove(_keyIntroDone);
  }
}
