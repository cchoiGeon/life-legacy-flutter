import 'package:get/get.dart';

// ── A · 온보딩 · 로그인 ────────────────────────────────────────
import 'package:life_legacy/feature/splash/binding.dart';
import 'package:life_legacy/feature/splash/splash_view.dart';
import 'package:life_legacy/feature/login/binding.dart';
import 'package:life_legacy/feature/login/login_view.dart';
import 'package:life_legacy/feature/login/phone_view.dart';
import 'package:life_legacy/feature/login/code_view.dart';

// ── B · 자기소개 → 목차 ────────────────────────────────────────
import 'package:life_legacy/feature/intro/binding.dart';
import 'package:life_legacy/feature/intro/intro_view.dart';
import 'package:life_legacy/feature/intro/toc_binding.dart';
import 'package:life_legacy/feature/intro/toc_loading_view.dart';
import 'package:life_legacy/feature/intro/toc_view.dart';

// ── C · 홈 ─────────────────────────────────────────────────────
import 'package:life_legacy/feature/home/binding.dart';
import 'package:life_legacy/feature/home/home_view.dart';

// ── D · 작성 ───────────────────────────────────────────────────
import 'package:life_legacy/feature/write/binding.dart';
import 'package:life_legacy/feature/write/write_view.dart';

// ── E · 나의 자서전 ────────────────────────────────────────────
import 'package:life_legacy/feature/book/binding.dart';
import 'package:life_legacy/feature/book/book_view.dart';
import 'package:life_legacy/feature/book/preview_binding.dart';
import 'package:life_legacy/feature/book/preview_view.dart';
import 'package:life_legacy/feature/book/complete_view.dart';

// ── 알림 센터 ──────────────────────────────────────────────────
import 'package:life_legacy/feature/notifications/binding.dart';
import 'package:life_legacy/feature/notifications/notifications_view.dart';

// ── F · 설정 ───────────────────────────────────────────────────
import 'package:life_legacy/feature/settings/binding.dart';
import 'package:life_legacy/feature/settings/settings_view.dart';
import 'package:life_legacy/feature/settings/profile_view.dart';
import 'package:life_legacy/feature/settings/address_view.dart';

part 'app_routes.dart';

/// 라우트 테이블.
///
/// 화면 번호는 Figma `실제 UI · 통합 앱`(node 134:2)의 프레임 번호다.
/// 시안의 22개 프레임 중 여러 개는 **같은 화면의 다른 상태**라서
/// (03/04 입력 전·후, 05/06 정상·에러, 07/08 음성·키보드,
///  11/12 데이터 있음·없음, 13/14 대기·녹음 중) 라우트는 그보다 적다.
abstract final class AppPages {
  static final List<GetPage> pages = [
    // ── A ────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.phone,
      page: () => const PhoneView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.code,
      page: () => const CodeView(),
      binding: LoginBinding(),
    ),

    // ── B ────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.intro,
      page: () => const IntroView(),
      binding: IntroBinding(),
    ),
    GetPage(
      name: AppRoutes.tocLoading,
      page: () => const TocLoadingView(),
      binding: TocBinding(),
    ),
    GetPage(
      name: AppRoutes.toc,
      page: () => const TocView(),
      binding: TocBinding(),
    ),

    // ── 탭 4개 ───────────────────────────────────────────────
    // 탭 전환에 애니메이션을 주지 않는다 — 시안이 탭바 고정 레이아웃이라
    // 슬라이드가 들어가면 탭바까지 같이 움직여 보인다.
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.write,
      page: () => const WriteView(),
      binding: WriteBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.book,
      page: () => const BookView(),
      binding: BookBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.noTransition,
    ),

    // ── 알림 센터 ────────────────────────────────────────────
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),

    // ── E 하위 ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.bookPreview,
      page: () => const BookPreviewView(),
      binding: BookPreviewBinding(),
    ),
    GetPage(
      name: AppRoutes.bookComplete,
      page: () => const BookCompleteView(),
      binding: BookPreviewBinding(),
    ),

    // ── F 하위 ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.settingsProfile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsAddress,
      page: () => const AddressView(),
      binding: AddressBinding(),
    ),
  ];
}
