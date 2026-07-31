import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

import 'support/test_env.dart';

/// 액세스 토큰은 1시간짜리다. 앱을 며칠 만에 다시 열면 반드시 만료돼 있다.
///
/// 그때 로그인 화면으로 쫓아내면, 시니어 사용자는 전화번호와 인증번호를
/// 다시 받아야 한다. 리프레시 토큰(60일)이 있는 이유가 그것이다.
void main() {
  setUpAll(() => initTestEnv('auth'));

  setUp(() => Storage.clearSession());

  Future<AuthSession> login(MockApiClient api) =>
      api.verifyCode(phone: '01012345678', code: MockApiClient.demoCode);

  test('로그인하면 액세스 토큰과 리프레시 토큰을 함께 저장한다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);

    await auth.applySession(await login(api));

    expect(Storage.accessToken, isNotEmpty);
    expect(Storage.refreshToken, isNotEmpty);
    expect(auth.isLoggedIn, isTrue);
  });

  test('액세스 토큰이 만료되면 리프레시로 되살린다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);
    await auth.applySession(await login(api));
    final oldToken = Storage.accessToken;

    api.expireAccessToken = true;
    final restored = await auth.restore();

    expect(restored, isTrue, reason: '로그인 화면으로 쫓아내면 안 된다');
    expect(auth.user.value, isNotNull);
    expect(Storage.accessToken, isNot(oldToken), reason: '새 토큰으로 갈아 끼운다');
  });

  test('리프레시 토큰도 만료되면 세션을 버린다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);
    await auth.applySession(await login(api));

    api.expireAccessToken = true;
    api.expireRefreshToken = true;
    final restored = await auth.restore();

    expect(restored, isFalse);
    expect(Storage.accessToken, isNull, reason: '못 쓰는 토큰을 남겨 두지 않는다');
    expect(Storage.refreshToken, isNull);
  });

  test('갱신에 성공하면 리프레시 토큰도 새것으로 바뀐다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);
    await auth.applySession(await login(api));
    final oldRefresh = Storage.refreshToken;

    api.expireAccessToken = true;
    await auth.restore();

    // 서버가 회전(rotation)시킨다 — 옛 토큰은 그 자리에서 폐기된다.
    expect(Storage.refreshToken, isNot(oldRefresh));
  });

  test('저장된 세션이 없으면 갱신을 시도하지 않는다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);

    expect(await auth.restore(), isFalse);
    expect(api.refreshCallCount, 0);
  });

  test('로그아웃하면 두 토큰을 모두 지운다', () async {
    final api = MockApiClient();
    final auth = AuthService(api);
    await auth.applySession(await login(api));

    await auth.logout();

    expect(Storage.accessToken, isNull);
    expect(Storage.refreshToken, isNull);
    expect(auth.user.value, isNull);
  });
}
