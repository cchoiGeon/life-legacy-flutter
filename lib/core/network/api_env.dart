/// 서버 주소와 목업 전환.
///
/// `--dart-define`으로 넘긴다. 기본값은 **목업**이라, 아무 설정 없이
/// 실행하면 지금까지처럼 서버 없이 앱이 돈다.
///
/// ```
/// flutter run --dart-define=USE_MOCK=false
/// flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.lifelegacy.app/v1
/// ```
abstract final class ApiEnv {
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// ⚠️ 안드로이드 에뮬레이터에서 개발 PC는 `localhost`가 아니라 10.0.2.2다.
  ///    에뮬레이터 자신을 가리키는 localhost로 붙으면 연결이 거부된다.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/v1',
  );

  /// AI를 부르는 요청은 서버에서 30~60초까지 걸린다(꼬리질문·윤문).
  /// 기본 타임아웃으로는 정상 응답을 실패로 읽는다.
  static const receiveTimeout = Duration(seconds: 70);
  static const connectTimeout = Duration(seconds: 10);
}
