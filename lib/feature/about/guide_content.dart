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
      title: '작성 완료',
      description: '목차를 마치면 나의 자서전에서 미리보고 내려받을 수 있어요.',
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
          title: '나의 자서전',
          summary: '진행을 확인하고 책처럼 미리보거나 파일로 내려받습니다.',
          bullets: [
            '「자서전」 메뉴에서 내 책을 고릅니다.',
            '미리보기로 책 형태로 읽습니다.',
            '전자책·오디오북은 안내에 따라 만들 수 있습니다.',
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
  ];
}
