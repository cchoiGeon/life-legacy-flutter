part of 'app_pages.dart';

/// 라우트 경로 상수. 문자열을 화면에서 직접 쓰지 않는다.
abstract final class AppRoutes {
  // A · 온보딩 · 로그인
  static const splash = '/'; // 01
  static const login = '/login'; // 02
  static const phone = '/login/phone'; // 03·04
  static const code = '/login/code'; // 05·06

  // B · 자기소개 → 목차
  static const intro = '/intro'; // 07·08
  static const tocLoading = '/intro/loading'; // 09
  static const toc = '/intro/toc'; // 10

  // 탭
  static const home = '/home'; // 11·12
  static const write = '/write'; // 13~18
  static const book = '/book'; // 19
  static const settings = '/settings'; // 22

  /// 홈 드롭다운의 "전체 보기"에서 들어온다.
  static const notifications = '/notifications'; // 13 알림 센터

  // E 하위
  static const bookPreview = '/book/preview'; // 20
  static const bookComplete = '/book/complete'; // 21
}
