import 'package:life_legacy/feature/about/about_content.dart';

/// T1~T4 구매 안내 카피. 결제는 웹에서만 가능하다.
abstract final class PurchaseContent {
  static const websiteUrl = AboutContent.websiteUrl;
  static const websiteLabel = AboutContent.websiteLabel;

  static const listTitle = '플랜 구매';
  static const listSubtitle = '첫 장은 무료로 써 보고, 이후 장은 플랜을 선택해 주세요';

  static const paywallBannerTitle = '다음 장을 이어 쓰려면 플랜이 필요해요';
  static const paywallBannerBody =
      '1장까지는 무료로 체험할 수 있어요. 2장부터는 웹에서 플랜을 구매해 주세요.';

  static const webOnlyTitle = '웹에서 구매할 수 있어요';
  static const webOnlyLead = '현재는 앱에서 바로 결제할 수 없고, 웹사이트에서 구매할 수 있어요.';

  static const credentialsNeeded =
      '웹사이트에 접속하려면 아이디·비밀번호 등록이 필요해요. '
      '아직 만들지 않으셨다면 웹에서 등록하거나, 앱 설정의 「아이디·비밀번호 만들기」를 이용해 주세요.';

  static const kakaoAlsoOk =
      '카카오톡으로 로그인한 분은 웹에서도 카카오톡으로 로그인할 수 있어요. '
      '다만 아이디·비밀번호도 함께 등록해 두시는 것을 권장해요.';

  static const openWebsiteLabel = '웹사이트 열기';

  static const plans = <PurchasePlan>[
    PurchasePlan(
      code: 'T1',
      name: 'T1',
      tagline: '전자책 + 오디오북',
      price: '₩39,000',
      originalPrice: '₩50,000',
      recommended: true,
      features: [
        '전자책 · 오디오북',
        '2장부터 전체 장 작성',
        'STT · TTS · AI 글쓰기 무제한',
        '질문 무제한',
        '사진 업로드 기본 10장',
        'AI 사진 생성 챕터별 1장',
      ],
    ),
    PurchasePlan(
      code: 'T2',
      name: 'T2',
      tagline: 'T1 + AI 영상 자서전',
      price: '₩69,000',
      originalPrice: '₩80,000',
      recommended: false,
      features: [
        'T1 구성 전부 포함',
        'AI 영상 자서전',
        '사진 업로드 무제한',
        'STT · TTS · AI 글쓰기 무제한',
      ],
    ),
    PurchasePlan(
      code: 'T3',
      name: 'T3',
      tagline: 'T1 + 인쇄책 (A5, 4권부터)',
      price: '₩99,000~',
      originalPrice: '₩120,000',
      recommended: false,
      features: [
        'T1 구성 전부 포함',
        '인쇄책 (A5 · 표지 · 컬러본 · 100p)',
        '4권부터 기준 가격',
        '사진 업로드 기본 10장',
      ],
    ),
    PurchasePlan(
      code: 'T4',
      name: 'T4',
      tagline: '전체 포함 (T1 + T2 + T3)',
      price: '₩129,000~',
      originalPrice: '₩160,000',
      recommended: false,
      features: [
        '전자책 · 오디오북',
        'AI 영상 자서전',
        '인쇄책',
        '사진 업로드 무제한',
        'STT · TTS · AI 글쓰기 무제한',
      ],
    ),
  ];

  static PurchasePlan? planByCode(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final p in plans) {
      if (p.code == upper) return p;
    }
    return null;
  }
}

class PurchasePlan {
  const PurchasePlan({
    required this.code,
    required this.name,
    required this.tagline,
    required this.price,
    required this.originalPrice,
    required this.recommended,
    required this.features,
  });

  final String code;
  final String name;
  final String tagline;
  final String price;
  final String originalPrice;
  final bool recommended;
  final List<String> features;
}
