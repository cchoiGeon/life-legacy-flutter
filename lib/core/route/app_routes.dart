part of 'app_pages.dart';

/// 라우트 경로 상수. 문자열을 화면에서 직접 쓰지 않는다.
abstract final class AppRoutes {
  // A · 온보딩 · 로그인
  static const splash = '/'; // 01
  static const index = '/index'; // 01 — 랜딩 (신규, 세션 없음)
  static const login = '/login'; // 02
  static const auth = '/auth'; // 02 — OCTOMO 인증 흐름 (신규)
  static const phone = '/login/phone'; // 03·04
  static const code = '/login/code'; // 05·06

  // B · 자기소개 → 목차
  static const intro = '/intro'; // 07·08
  static const tocLoading = '/intro/loading'; // 09
  static const toc = '/intro/toc'; // 10

  // 탭
  static const home = '/home'; // 11·12
  static const write = '/write'; // 13~18
  static const book = '/book'; // 06 책 허브(목록)
  static const settings = '/settings'; // 22

  /// 홈 드롭다운의 "전체 보기"에서 들어온다.
  static const notifications = '/notifications'; // 13 알림 센터

  // E 하위
  static const bookDetail = '/book/detail'; // 6-1 책 상세(장 목록)
  static const bookPreview = '/book/preview'; // E2
  static const bookComplete = '/book/complete'; // E3
  static const bookReview = '/book/review'; // 05 챕터 리뷰
  static const bookAudiobook = '/book/audiobook'; // 6-1-2 오디오북

  // F 하위
  static const settingsProfile = '/settings/profile'; // F3
  static const settingsAddress = '/settings/address'; // F4
}
