import 'package:get/get.dart';

// ── A · 온보딩 · 로그인 ────────────────────────────────────────
import 'package:life_legacy/feature/splash/binding.dart';
import 'package:life_legacy/feature/splash/splash_view.dart';
import 'package:life_legacy/feature/index/binding.dart';
import 'package:life_legacy/feature/index/index_view.dart';
import 'package:life_legacy/feature/login/binding.dart';
import 'package:life_legacy/feature/login/login_view.dart';
import 'package:life_legacy/feature/login/phone_view.dart';
import 'package:life_legacy/feature/login/code_view.dart';
import 'package:life_legacy/feature/auth/binding.dart' as auth_binding;
import 'package:life_legacy/feature/auth/auth_view.dart';

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
import 'package:life_legacy/feature/book/book_detail_view.dart';
import 'package:life_legacy/feature/book/preview_binding.dart';
import 'package:life_legacy/feature/book/preview_view.dart';
import 'package:life_legacy/feature/book/complete_view.dart';

// ── 챕터 리뷰 ──────────────────────────────────────────────────
import 'package:life_legacy/feature/review/binding.dart';
import 'package:life_legacy/feature/review/review_view.dart';
import 'package:life_legacy/feature/audiobook/binding.dart';
import 'package:life_legacy/feature/audiobook/audiobook_view.dart';

// ── 알림 센터 ──────────────────────────────────────────────────
import 'package:life_legacy/feature/notifications/binding.dart';
import 'package:life_legacy/feature/notifications/notifications_view.dart';

// ── G · 사진 첨부 / 사진첩 ────────────────────────────────────
import 'package:life_legacy/feature/photo/binding.dart' as photo_binding;
import 'package:life_legacy/feature/photo/g1_suggest_view.dart';
import 'package:life_legacy/feature/photo/g2_pick_view.dart';
import 'package:life_legacy/feature/photo/g3_caption_view.dart';
import 'package:life_legacy/feature/photo/g25_place_view.dart';
import 'package:life_legacy/feature/photo/g4_done_view.dart';
import 'package:life_legacy/feature/photo/photo_album_view.dart';
import 'package:life_legacy/feature/photo/chapter_album_view.dart';
import 'package:life_legacy/feature/photo/chapter_read_view.dart';

// ── F · 설정 ───────────────────────────────────────────────────
import 'package:life_legacy/feature/settings/binding.dart';
import 'package:life_legacy/feature/settings/settings_view.dart';
import 'package:life_legacy/feature/settings/profile_view.dart';
import 'package:life_legacy/feature/settings/address_view.dart';
import 'package:life_legacy/feature/settings/credentials_view.dart';
import 'package:life_legacy/feature/print_order/print_order_binding.dart';
import 'package:life_legacy/feature/print_order/print_order_view.dart';
import 'package:life_legacy/feature/print_order/print_order_success_view.dart';
import 'package:life_legacy/feature/about/about_view.dart';
import 'package:life_legacy/feature/about/guide_view.dart';
import 'package:life_legacy/feature/login/password_login_view.dart';
import 'package:life_legacy/feature/login/consents_view.dart';
import 'package:life_legacy/feature/purchase/purchase_view.dart';
import 'package:life_legacy/feature/purchase/purchase_detail_view.dart';
import 'package:life_legacy/feature/purchase/coupon_view.dart';
import 'package:life_legacy/feature/legal/legal_document_view.dart';
import 'package:life_legacy/feature/support/binding.dart';
import 'package:life_legacy/feature/support/faq_view.dart';
import 'package:life_legacy/feature/support/qna_view.dart';

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
      name: AppRoutes.index,
      page: () => const IndexView(),
      binding: IndexBinding(),
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
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: auth_binding.AuthBinding(),
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
      name: AppRoutes.bookDetail,
      page: () => const BookDetailView(),
      binding: BookDetailBinding(),
    ),
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
    GetPage(
      name: AppRoutes.bookReview,
      page: () => const ReviewView(),
      binding: ReviewBinding(),
    ),
    GetPage(
      name: AppRoutes.bookAudiobook,
      page: () => const AudiobookView(),
      binding: AudiobookBinding(),
    ),
    GetPage(
      name: AppRoutes.printOrder,
      page: () => const PrintOrderView(),
      binding: PrintOrderBinding(),
    ),
    GetPage(
      name: AppRoutes.printOrderSuccess,
      page: () => const PrintOrderSuccessView(),
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
    GetPage(
      name: AppRoutes.settingsCredentials,
      page: () => const CredentialsView(),
      binding: CredentialsBinding(),
    ),
    GetPage(
      name: AppRoutes.passwordLogin,
      page: () => const PasswordLoginView(),
      binding: PasswordLoginBinding(),
    ),
    GetPage(
      name: AppRoutes.consents,
      page: () => const ConsentsView(),
      binding: ConsentsBinding(),
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutView(),
    ),
    GetPage(
      name: AppRoutes.guide,
      page: () => const GuideView(),
    ),
    GetPage(
      name: AppRoutes.purchase,
      page: () => const PurchaseView(),
    ),
    GetPage(
      name: AppRoutes.purchaseDetail,
      page: () => const PurchaseDetailView(),
    ),
    GetPage(
      name: AppRoutes.purchaseCoupon,
      page: () => const CouponView(),
      binding: CouponBinding(),
    ),
    GetPage(
      name: AppRoutes.legal,
      page: () => const LegalDocumentView(),
    ),
    GetPage(
      name: AppRoutes.settingsFaq,
      page: () => const FaqView(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: AppRoutes.settingsQna,
      page: () => const QnaView(),
      binding: QnaBinding(),
    ),

    // ── G · 사진 첨부 / 사진첩 ───────────────────────────────
    GetPage(
      name: AppRoutes.bookPhotoSuggest,
      page: () => const G1SuggestView(),
      binding: photo_binding.PhotoAttachBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotoPick,
      page: () => const G2PickView(),
      binding: photo_binding.PhotoAttachBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotoCaption,
      page: () => const G3CaptionView(),
      binding: photo_binding.PhotoAttachBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotoPlace,
      page: () => const G25PlaceView(),
      binding: photo_binding.PhotoAttachBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotoDone,
      page: () => const G4DoneView(),
      binding: photo_binding.PhotoAttachBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotos,
      page: () => const PhotoAlbumView(),
      binding: photo_binding.PhotoAlbumBinding(),
    ),
    GetPage(
      name: AppRoutes.bookPhotosChapter,
      page: () => const ChapterAlbumView(),
      binding: photo_binding.ChapterPhotoDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.bookChapterRead,
      page: () => const ChapterReadAlbumView(),
      binding: photo_binding.ChapterPhotoDetailBinding(),
    ),
  ];
}
