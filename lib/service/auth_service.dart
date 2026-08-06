import 'dart:typed_data';

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

  /// 프로필 사진 바이트. 없으면 null → 이니셜 아바타.
  final Rxn<Uint8List> avatarBytes = Rxn<Uint8List>();

  bool get isLoggedIn => Storage.isLoggedIn;

  /// 표시용 이름. 아직 못 불러왔으면 빈 문자열.
  String get displayName => user.value?.givenName ?? '';

  /// 세션을 저장하고 사용자 정보를 메모리에 올린다.
  ///
  /// ⚠️ 자기소개 완료 표시는 **서버가 진실**이다(`needs_intro`). 로그인할
  ///    때마다 로컬 표시를 그 값에 맞춘다 — 앱을 지웠다 다시 깔면 로컬
  ///    표시가 사라지는데, 그대로 두면 이미 확정한 목차를 또 만들라고 하고
  ///    확정에서 409로 막혀 갇힌다.
  ///
  /// [loginProvider]는 `kakao` | `phone` | `credentials`. 웹 구매 안내에서
  /// 카카오 로그인 가능 여부를 알려 줄 때 쓴다.
  Future<void> applySession(
    AuthSession session, {
    String? loginProvider,
  }) async {
    await Storage.saveTokens(
      session.tokens.accessToken,
      session.tokens.refreshToken,
    );
    if (loginProvider != null) {
      await Storage.saveLoginProvider(loginProvider);
    }
    if (!session.needsIntro) {
      await Storage.markIntroDone();
    }
    user.value = session.user;
    await _loadAvatarIfNeeded();
  }

  /// 카카오로 로그인한 세션이면 true. 없으면 전화번호 없는 계정으로 추정.
  bool get isKakaoLogin {
    if (Storage.loginProvider == 'kakao') return true;
    final u = user.value;
    if (u == null) return false;
    return u.phone.isEmpty;
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
      await _loadAvatarIfNeeded();
      return true;
    } on ApiException catch (e) {
      if (e.code == 'TOKEN_EXPIRED' && await _refresh()) {
        return restore();
      }
      await Storage.clearSession();
      avatarBytes.value = null;
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

  /// 서버에서 사용자 정보를 다시 읽어 화면에 반영한다.
  ///
  /// 성함은 **자기소개(i1)에서 서버에 저장**되므로, 로그인 시점의 사용자에는
  /// 아직 이름이 없다. 목차를 확정한 뒤 이걸 부르지 않으면 홈 인사말이
  /// "님, 오늘의 질문"으로 뜬다.
  Future<void> reload() async {
    try {
      user.value = await _api.me();
      await _loadAvatarIfNeeded();
    } on ApiException {
      // 이름을 못 읽어도 화면은 계속 쓸 수 있어야 한다. 다음 앱 시작 때
      // restore()가 다시 시도한다.
    }
  }

  /// 로컬에 이미 알고 있는 [User]를 갱신한다 (credentials/avatar 업로드 직후).
  void updateUser(User next) {
    user.value = next;
  }

  Future<void> setAvatarBytes(Uint8List? bytes) async {
    avatarBytes.value = bytes;
  }

  Future<void> _loadAvatarIfNeeded() async {
    final u = user.value;
    if (u == null || !u.hasAvatar) {
      avatarBytes.value = null;
      return;
    }
    try {
      final bytes = await _api.fetchAvatarBytes();
      avatarBytes.value = bytes == null ? null : Uint8List.fromList(bytes);
    } on ApiException {
      avatarBytes.value = null;
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
    avatarBytes.value = null;
  }
}
