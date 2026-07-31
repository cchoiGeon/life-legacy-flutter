import 'dart:async';

import 'package:dio/dio.dart';

import 'package:life_legacy/data/data_manager.dart';

/// 액세스 토큰을 실어 보내고, 만료되면 **한 번** 되살려 재시도한다.
///
/// 액세스 토큰은 1시간짜리라 앱을 하루만 안 열어도 만료돼 있다. 그때마다
/// 로그인 화면으로 보내면 시니어 사용자는 전화번호와 인증번호를 매번 다시
/// 받아야 한다.
///
/// ⚠️ 갱신 요청 자체에는 토큰을 싣지 않고, 401이 나도 다시 갱신하지 않는다.
///    그러지 않으면 리프레시가 죽었을 때 무한히 서로를 부른다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio, {required this.onSessionExpired});

  final Dio _dio;

  /// 리프레시까지 실패했을 때. 화면을 로그인으로 돌려보내는 자리다.
  final Future<void> Function() onSessionExpired;

  /// 갱신이 겹치지 않게 하나로 묶는다. 화면 여럿이 동시에 401을 받으면
  /// 리프레시가 그만큼 날아가고, 회전 때문에 뒤엣것이 전부 실패한다.
  Future<bool>? _refreshing;

  static const _refreshPath = '/auth/refresh';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = Storage.accessToken;
    if (token != null && options.path != _refreshPath) {
      options.headers['authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        _codeOf(err) == 'TOKEN_EXPIRED' &&
        err.requestOptions.path != _refreshPath;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final refreshed = await (_refreshing ??= _refresh());
    _refreshing = null;

    if (!refreshed) {
      await onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      // 갱신된 토큰으로 원래 요청을 그대로 한 번 더 보낸다.
      final options = err.requestOptions;
      options.headers['authorization'] = 'Bearer ${Storage.accessToken}';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refresh() async {
    final refreshToken = Storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.post<dynamic>(
        _refreshPath,
        data: {'refresh_token': refreshToken},
      );
      final tokens = AuthTokens.fromJson(
        response.data as Map<String, dynamic>,
      );

      // ⚠️ 서버가 리프레시 토큰도 회전시킨다. 액세스만 갈아 끼우면 다음
      //    갱신에서 폐기된 토큰을 들고 간다.
      await Storage.saveTokens(tokens.accessToken, tokens.refreshToken);
      return true;
    } on DioException {
      return false;
    }
  }

  String? _codeOf(DioException err) {
    final data = err.response?.data;

    return data is Map<String, dynamic> ? data['code'] as String? : null;
  }
}
