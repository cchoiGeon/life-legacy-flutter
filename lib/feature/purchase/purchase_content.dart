import 'package:life_legacy/feature/about/about_content.dart';

/// FREE + T1~T4 구매 안내 카피. 결제는 웹에서만 가능하다.
abstract final class PurchaseContent {
  static const websiteUrl = AboutContent.websiteUrl;
  static const websiteLabel = AboutContent.websiteLabel;

  static const listTitle = '플랜 구매';
  static const listHeroTitle = '런칭 할인가로 만나보세요';
  static const listSubtitle = '소중한 사람들에게 따뜻한 이야기를 선물하세요';

  static const paywallBannerTitle = '다음 장을 이어 쓰려면 플랜이 필요해요';
  static const paywallBannerBody =
      '1장까지는 무료로 체험할 수 있어요. 2장부터는 웹에서 플랜을 구매해 주세요.';

  static const webOnlyTitle = '웹에서 구매할 수 있어요';
  static const webOnlyLead =
      '현재는 앱에서 바로 결제할 수 없고, 웹사이트에서 구매할 수 있어요.';
  static const webOnlyStickyHint =
      '*달마다 결제되지 않아요. 한 번 결제로 책을 완성할 수 있어요.';
  static const webPayCta = '웹에서 결제하기';

  static const credentialsNeeded =
      '웹사이트에 접속하려면 아이디·비밀번호 등록이 필요해요. '
      '아직 만들지 않으셨다면 웹에서 등록하거나, 앱 설정의 「아이디·비밀번호 만들기」를 이용해 주세요.';

  static const kakaoAlsoOk =
      '카카오톡으로 로그인한 분은 웹에서도 카카오톡으로 로그인할 수 있어요. '
      '다만 아이디·비밀번호도 함께 등록해 두시는 것을 권장해요.';

  static const openWebsiteLabel = '웹사이트 열기';

  static const bookProcessTitle = '책이 만들어지는 순서';

  static const bookProcessSteps =
      <({int step, String title, String duration, String body, String? warning, bool premiumOnly})>[
    (
      step: 1,
      title: '인터뷰 진행',
      duration: '20일~30일',
      body: '인터뷰를 천천히 완료해 주세요. 모두 끝나면 다음 단계로 넘어갈 수 있어요.',
      warning: null,
      premiumOnly: false,
    ),
    (
      step: 2,
      title: '전자책 신청',
      duration: '1분',
      body: '인터뷰가 끝나면 전자책 신청 버튼을 눌러주세요. (홈 화면 우측 상단)',
      warning: '전자책 신청 후에는 인터뷰 추가/삭제/수정이 불가능해요.',
      premiumOnly: false,
    ),
    (
      step: 3,
      title: '전자책 편집',
      duration: '1~3시간',
      body: '책에 들어갈 사진을 추가하고, 필요 시 글 내용을 직접 수정해 주세요.',
      warning: null,
      premiumOnly: false,
    ),
    (
      step: 4,
      title: '실물책 신청',
      duration: '2분',
      body: '전자책 편집 완료 후, 실물책 신청 버튼을 눌러주세요. (전자책 보기 화면 우측 하단)',
      warning: '실물책 신청 후에는 내용 수정/ 사진 추가/ 신청 정보 수정이 불가능해요.',
      premiumOnly: true,
    ),
  ];

  static const refundSummaryTitle = '환불 규정';
  static const refundSummaryBody =
      '디지털 콘텐츠 특성상 제공이 시작된 이후에는 원칙적으로 환불이 제한될 수 있어요. '
      '자세한 내용은 환불정책을 확인해 주세요.';
  static const refundFullLabel = '환불정책 전문 보기';

  static const productFaqTitle = '상품 상세 · FAQ';
  static const productFaqs = <({String q, String a})>[
    (
      q: '앱에서 바로 결제할 수 있나요?',
      a: '지금은 앱에서 결제할 수 없어요. 웹사이트에서 구매하거나, 쿠폰 코드로 플랜을 등록해 주세요.',
    ),
    (
      q: '무료(FREE)로 어디까지 쓸 수 있나요?',
      a: '1장까지 인터뷰·작성을 체험할 수 있어요. 2장부터는 T1 이상 플랜이 필요해요.',
    ),
    (
      q: '전자책과 종이책의 차이는요?',
      a: '전자책(PDF)은 T1 이상에서, 종이책(인쇄본) 신청은 T3·T4에서 안내해요. 앱에서는 신청만 받고 결제는 웹에서 진행해요.',
    ),
    (
      q: '쿠폰은 어떻게 쓰나요?',
      a: '플랜 구매 화면의 「쿠폰 코드 등록」에서 코드를 입력하면 해당 플랜이 바로 적용돼요.',
    ),
  ];

  static const plans = <PurchasePlan>[
    PurchasePlan(
      code: 'FREE',
      name: '무료',
      tagline: '1장까지 체험',
      price: '무료',
      originalPrice: '',
      recommended: false,
      isFree: true,
      maxProcessStep: 1,
      stepCaption: '인터뷰(1장)까지 체험할 수 있어요',
      features: [
        '1장까지 작성 · 리뷰',
        '목차 생성 · AI 질문',
        'STT · TTS 체험',
        '전자책·인쇄본은 유료 플랜에서',
      ],
    ),
    PurchasePlan(
      code: 'T1',
      name: 'T1',
      tagline: '전자책 + 오디오북',
      price: '₩39,000',
      originalPrice: '₩50,000',
      recommended: true,
      isFree: false,
      maxProcessStep: 3,
      stepCaption: '전자책 신청·편집까지 가능해요',
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
      isFree: false,
      maxProcessStep: 3,
      stepCaption: '전자책까지 + AI 영상 자서전',
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
      isFree: false,
      maxProcessStep: 4,
      stepCaption: '실물책 신청까지 가능해요',
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
      isFree: false,
      maxProcessStep: 4,
      stepCaption: '전자책·영상·실물책 모두 포함',
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
    required this.isFree,
    required this.maxProcessStep,
    required this.stepCaption,
  });

  final String code;
  final String name;
  final String tagline;
  final String price;
  final String originalPrice;
  final bool recommended;
  final List<String> features;
  final bool isFree;

  /// 「책이 만들어지는 순서」에서 이 플랜으로 가능한 마지막 단계(1~4).
  final int maxProcessStep;
  final String stepCaption;
}
