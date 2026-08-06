/// 카카오 로그인 네이티브 앱 키.
///
/// Kakao Developers 콘솔 [내 애플리케이션] > [앱 키] > **네이티브 앱 키**를 그대로 쓴다.
///
/// ⚠️ 아래 세 곳의 값이 **전부 같아야** 카카오 로그인 리다이렉트가 동작한다.
///    하나라도 다르면 로그인 버튼을 눌러도 아무 반응이 없거나 카카오톡/브라우저에서
///    앱으로 돌아오지 못한다.
///    1. 여기 `nativeAppKey` (또는 `--dart-define=KAKAO_NATIVE_APP_KEY=...`)
///    2. `android/app/src/main/AndroidManifest.xml`의 `kakao${키}://oauth` scheme
///    3. `ios/Runner/Info.plist`의 `CFBundleURLSchemes`·`LSApplicationQueriesSchemes` 첫 항목
abstract final class KakaoEnv {
  static const nativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
    defaultValue: 'a69208d65071366167d0c2041ebbcdc9',
  );
}
