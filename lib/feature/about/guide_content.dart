/// 사용설명서 — 웹 guide.ts를 Flutter 앱 흐름에 맞게 가공.
abstract final class GuideContent {
  static const title = '사용 설명서';
  static const subtitle =
      '기로기로 자서전을 쓰는 방법을 순서대로 안내합니다.';
  static const intro =
      '기로기는 AI와 대화하며 인생 이야기를 남기는 서비스입니다. '
      '말하거나 타이핑하면, AI가 맞춤 목차·질문을 만들고 답변을 자서전 문체로 다듬어 줍니다.';

  static const flowSteps = <({int step, String title, String description})>[
    (
      step: 1,
      title: '회원가입·로그인',
      description:
          '카카오·전화 또는 아이디·비밀번호로 로그인합니다. 아이디 가입은 웹에서도 할 수 있어요.',
    ),
    (
      step: 2,
      title: '자기소개',
      description: '몇 가지 질문에 답하면 AI가 맞춤 목차를 만듭니다.',
    ),
    (
      step: 3,
      title: '목차 확정',
      description: '제안된 목차를 확인하고 작성을 시작합니다.',
    ),
    (
      step: 4,
      title: '질문에 답하기',
      description:
          '답변 → 확인·전송 → AI 문단 검토 → 「이 문단으로 저장」순으로 진행합니다.',
    ),
    (
      step: 5,
      title: '작성 완료 · 전자책',
      description:
          '목차를 마치면 미리보고 PDF로 저장·공유할 수 있어요. 종이책은 완성 화면에서 신청합니다.',
    ),
  ];

  static const bookMakingSteps =
      <({int step, String title, String duration, String description})>[
    (
      step: 1,
      title: '인터뷰 진행',
      duration: '20일~30일',
      description: '인터뷰를 천천히 완료해 주세요. 모두 끝나면 다음 단계로 넘어갈 수 있어요.',
    ),
    (
      step: 2,
      title: '전자책 신청',
      duration: '1분',
      description:
          '인터뷰가 끝나면 전자책 미리보기·신청으로 이어집니다. 신청 후에는 인터뷰 추가·수정이 어려워요.',
    ),
    (
      step: 3,
      title: '전자책 편집',
      duration: '1~3시간',
      description: '책에 들어갈 사진을 추가하고, 필요 시 글 내용을 직접 수정해 주세요.',
    ),
    (
      step: 4,
      title: '실물책 신청',
      duration: '2분 · T3/T4',
      description:
          '전자책 편집 후 「종이책으로 주문하기」로 배송지를 넣고 신청합니다. 결제는 웹에서 진행해요.',
    ),
  ];

  static const sections =
      <({String title, String summary, List<String> bullets})>[
        (
          title: '로그인',
          summary: '서비스를 쓰려면 계정이 필요합니다.',
          bullets: [
            '카카오 또는 전화번호로 시작할 수 있습니다.',
            '웹에서 만든 아이디·비밀번호로도 로그인할 수 있습니다.',
            '카카오·전화로 가입했다면 설정에서 아이디·비밀번호를 만들 수 있습니다.',
          ],
        ),
        (
          title: '자기소개·목차',
          summary: '나를 소개하면 AI가 맞춤 목차를 만듭니다.',
          bullets: [
            '질문에 말하거나 타이핑으로 답합니다.',
            '목차 초안이 나오면 제목을 다듬거나 장을 조정할 수 있습니다.',
            '목차를 확정하면 홈과 작성 화면에서 질문이 이어집니다.',
          ],
        ),
        (
          title: '질문에 답하기',
          summary: '한 질문씩 답하고, AI가 정리한 문단을 확인한 뒤 저장합니다.',
          bullets: [
            '마이크나 키보드로 답한 뒤 확인·전송합니다.',
            'AI가 「정리된 문단」을 만들면 검토한 뒤 저장합니다.',
            '답하고 싶지 않은 질문은 건너뛸 수 있습니다.',
          ],
        ),
        (
          title: '나의 자서전 · 미리보기',
          summary: '책처럼 미리보고 PDF로 저장·공유합니다.',
          bullets: [
            '「자서전」 메뉴에서 내 책을 고릅니다.',
            '전자책 미리보기에서 쪽을 넘기며 읽습니다.',
            '「공유」로 휴대폰의 공유 기능을 통해 PDF를 보낼 수 있습니다.',
            '「PDF 저장」으로 파일을 열어 기기에 보관할 수 있습니다.',
          ],
        ),
        (
          title: '종이책 주문',
          summary: '완성 후 인쇄본을 신청할 수 있습니다.',
          bullets: [
            '완성 화면의 「종이책으로 주문하기」로 들어갑니다.',
            '설정에 등록한 인쇄본 배송지를 사용합니다.',
            '부수를 고른 뒤 신청하면 접수가 완료됩니다.',
            '앱에서는 결제가 되지 않아요. 웹사이트에서 결제를 이어 주세요.',
          ],
        ),
        (
          title: '플랜 · 결제',
          summary: '무료로 1장을 써 보고, 이후는 웹에서 플랜을 구매합니다.',
          bullets: [
            'FREE는 1장까지 체험할 수 있어요.',
            'T1~T4 플랜 안내와 「책이 만들어지는 순서」는 플랜 구매 화면에서 볼 수 있어요.',
            '결제는 www.lifelegacy.co.kr 웹에서만 진행됩니다.',
            '쿠폰이 있으면 앱의 「쿠폰 코드 등록」으로 바로 플랜을 적용할 수 있어요.',
          ],
        ),
      ];

  static const tips = <({String title, String body})>[
    (
      title: '마이크',
      body: '말하면 글자로 바뀌어 입력창에 들어갑니다. 기기에서 마이크를 허용해 주세요.',
    ),
    (
      title: '다시 생성하기',
      body: '정리된 문단이 마음에 들지 않으면 다시 생성해 달라고 요청할 수 있습니다.',
    ),
    (
      title: '무료 체험',
      body: '결제 없이 첫 장까지 체험할 수 있습니다. 더 많은 장은 안내된 플랜을 따릅니다.',
    ),
    (
      title: 'PDF 공유',
      body: '미리보기·완성 화면에서 공유를 누르면 카카오톡·메일 등 기기 공유 시트가 열려요.',
    ),
    (
      title: '환불',
      body: '환불 규정은 플랜 구매 화면 하단과 설정의 환불정책에서 확인할 수 있어요.',
    ),
  ];
}
