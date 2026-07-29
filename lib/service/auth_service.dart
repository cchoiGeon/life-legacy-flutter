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
    await Storage.saveSession(session.accessToken);
    user.value = session.user;
  }

  /// 앱 시작 시 저장된 토큰으로 사용자 정보를 복구한다.
  /// 실패하면 세션을 버린다 — 화면은 로그인으로 보내면 된다.
  Future<bool> restore() async {
    if (!Storage.isLoggedIn) return false;
    try {
      user.value = await _api.me();
      return true;
    } on ApiException {
      await Storage.clearSession();
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
