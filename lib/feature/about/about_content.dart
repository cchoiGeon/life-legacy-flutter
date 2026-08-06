/// 소개 — 웹 랜딩(landing.ts) 카피를 앱용으로 축약.
abstract final class AboutContent {
  static const title = '소개';
  static const subtitle = '말로 이야기하면 자서전이 됩니다';
  static const intro =
      '기로기는 AI와 대화하며 인생 이야기를 남기는 '
      '음성인식 자서전 서비스입니다. 말하거나 타이핑하면, AI가 맞춤 목차·질문을 '
      '만들고 답변을 자서전 문체로 다듬어 줍니다.';

  static const websiteUrl = 'https://www.lifelegacy.co.kr';
  static const websiteLabel = 'www.lifelegacy.co.kr';

  static const features = <({String title, String description})>[
    (
      title: '음성인식 입력',
      description: '말로 편하게 이야기하세요. AI가 자동으로 텍스트로 변환합니다.',
    ),
    (
      title: 'AI 맞춤 질문',
      description: '당신의 이야기에 맞는 질문을 AI가 자동으로 생성합니다.',
    ),
    (
      title: '자동 문체 다듬기',
      description: '답변을 자서전에 어울리는 문체로 자동 변환합니다.',
    ),
    (
      title: '전자책 & 인쇄본',
      description: '완성된 자서전을 PDF 전자책 또는 인쇄본으로 받으세요.',
    ),
    (
      title: '개인정보 보호',
      description: '암호화된 데이터 처리로 소중한 기록을 안전하게 보관합니다.',
    ),
    (
      title: '빠른 제작',
      description: '기존 수개월 소요에서 몇 주 내 자서전 완성이 가능합니다.',
    ),
  ];

  static const howItWorks = <({int step, String title, String description})>[
    (
      step: 1,
      title: '자기소개 입력',
      description: '간단한 자기소개를 텍스트 또는 음성으로 입력하세요.',
    ),
    (
      step: 2,
      title: '맞춤 목차 생성',
      description: 'AI가 당신의 이야기에 맞는 목차를 자동으로 만들어드립니다.',
    ),
    (
      step: 3,
      title: '질문에 답하기',
      description: '각 목차별 질문에 음성 또는 텍스트로 편하게 답변하세요.',
    ),
    (
      step: 4,
      title: '자서전 완성',
      description: 'AI가 답변을 다듬어 멋진 자서전으로 완성해드립니다.',
    ),
  ];

  static const freeTrialNote =
      '결제 없이 무료로 첫 장까지 체험해 보실 수 있어요.';

  static const reviewsIntro =
      '현장 프로그램 설문에서 받은 목소리를 바탕으로 정리했습니다';
  static const reviewsScore = '4.1';
  static const reviewsScoreMax = '5.0';
  static const reviewsScoreLabel = '프로그램 만족도';

  static const reviews = <String>[
    '가족과 성장 환경을 적으며 옛 추억으로 돌아갈 수 있어 좋았습니다. '
        '잊고 있던 장면이 하나씩 떠올랐어요.',
    '어머니에 대한 질문이 가장 기억에 남습니다. 말로 이야기하니 글보다 편했고, '
        '정리된 문장도 내가 하려던 말과 비슷했어요.',
    '완성된 이야기를 자녀에게도 들려주고 싶습니다. 혼자 참여하는 편이 더 편했고, '
        '집에서도 이어서 써 보고 싶다는 생각이 들었어요.',
    '과거를 떠올리고 생각을 정리하는 일이 쉽지는 않았습니다. '
        '그래도 질문을 따라가다 보니 제 삶이 하나씩 이야기로 남더라고요.',
  ];

  static const pricingIntro = '무료로 첫 장을 써 보고, 필요에 맞는 티어를 선택하세요';
  static const pricingNote =
      '티어별 사용량 제한·결제 연동은 오픈 일정에 맞춰 순차 적용됩니다.';

  static const plans = <
      ({
        String code,
        String name,
        String description,
        String price,
        String? originalPrice,
        bool recommended,
      })>[
    (
      code: 'FREE',
      name: '무료',
      description: '챕터1까지 — 목차 생성·작성·노트북 리뷰',
      price: '무료',
      originalPrice: null,
      recommended: false,
    ),
    (
      code: 'T1',
      name: 'T1',
      description: '전자책 + 오디오북',
      price: '₩39,000',
      originalPrice: '₩50,000',
      recommended: true,
    ),
    (
      code: 'T2',
      name: 'T2',
      description: 'T1 + AI 영상 자서전',
      price: '₩69,000',
      originalPrice: '₩80,000',
      recommended: false,
    ),
    (
      code: 'T3',
      name: 'T3',
      description: 'T1 + 인쇄책(A5, 4권부터)',
      price: '₩99,000~',
      originalPrice: '₩120,000',
      recommended: false,
    ),
    (
      code: 'T4',
      name: 'T4',
      description: '전체 포함 (T1+T2+T3)',
      price: '₩129,000~',
      originalPrice: '₩160,000',
      recommended: false,
    ),
  ];

  static const privacyPrinciples = <({String title, String body})>[
    (
      title: '로그인 보호',
      body:
          '비밀번호는 암호화하여 저장하고, 본인 세션에서만 내 기록에 접근할 수 있습니다.',
    ),
    (
      title: '목적 외 사용 제한',
      body: '입력하신 내용은 자서전 작성·다듬기 목적 외에는 사용하지 않습니다.',
    ),
    (
      title: '데이터 주권',
      body: '언제든 내 기록의 열람·삭제를 요청할 수 있습니다.',
    ),
  ];
}
