import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';

/// 로그인 상태를 앱 전역에서 들고 있는 서비스.
///
/// IAM_flutter의 AuthService와 역할이 같다. 화면은 `Get.find<AuthService>()`로
/// 현재 사용자를 읽고, 로그인·로그아웃은 반드시 여기를 거친다.
class AuthService extends GetxService {
  AuthService(this._api);

  final ApiClient _api;

  final Rxn<User> user = Rxn<User>();

  bool get isLoggedIn => Storage.isLoggedIn;

  /// 표시용 이름. 아직 못 불러왔으면 빈 문자열.
  String get displayName => user.value?.givenName ?? '';

  /// 세션을 저장하고 사용자 정보를 메모리에 올린다.
  Future<void> applySession(AuthSession session) async {
    await Storage.saveTokens(
      session.tokens.accessToken,
      session.tokens.refreshToken,
    );
    user.value = session.user;
  }

  /// 앱 시작 시 저장된 토큰으로 사용자 정보를 복구한다.
  ///
  /// 액세스 토큰은 1시간짜리라 앱을 하루만 안 열어도 만료돼 있다. 그때마다
  /// 로그인 화면으로 보내면 시니어 사용자는 전화번호와 인증번호를 매번 다시
  /// 받아야 한다 — 만료면 리프레시로 한 번 되살려 본다.
  ///
  /// 리프레시까지 실패해야 세션을 버린다.
  Future<bool> restore() async {
    if (!Storage.isLoggedIn) return false;
    try {
      user.value = await _api.me();
      return true;
    } on ApiException catch (e) {
      if (e.code == 'TOKEN_EXPIRED' && await _refresh()) {
        return restore();
      }
      await Storage.clearSession();
      return false;
    }
  }

  /// 저장된 리프레시 토큰으로 새 토큰 한 쌍을 받아 갈아 끼운다.
  ///
  /// ⚠️ 서버가 리프레시 토큰도 회전시키므로 **둘 다** 저장해야 한다.
  ///    액세스 토큰만 갈아 끼우면 다음 갱신에서 폐기된 토큰을 들고 간다.
  Future<bool> _refresh() async {
    final token = Storage.refreshToken;
    if (token == null || token.isEmpty) return false;
    try {
      final next = await _api.refreshTokens(token);
      await Storage.saveTokens(next.accessToken, next.refreshToken);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> logout() async {
    // 서버 로그아웃이 실패해도 로컬 세션은 반드시 지운다.
    try {
      await _api.logout();
    } on ApiException {
      // 무시 — 아래에서 로컬 정리는 그대로 진행한다.
    }
    await Storage.clearSession();
    user.value = null;
  }
}
