/** 앱 FAQ — 웹 `faq.ts`를 전화 인증·앱 흐름에 맞게 축약한 읽기 전용 콘텐츠 */

export interface FaqItem {
  question: string;
  answer: string;
}

export interface FaqSection {
  id: string;
  label: string;
  items: FaqItem[];
}

export const FAQ_CATEGORIES = [
  { id: 'start', label: '시작·가입' },
  { id: 'intro', label: '자기소개·목차' },
  { id: 'write', label: '작성·전송·저장' },
  { id: 'voice', label: '음성 입력' },
  { id: 'mypage', label: '나의 자서전' },
  { id: 'preview', label: '미리보기·내보내기' },
  { id: 'account', label: '계정·설정' },
  { id: 'other', label: '기타' },
] as const;

export const FAQ_SECTIONS: FaqSection[] = [
  {
    id: 'start',
    label: '시작·가입',
    items: [
      {
        question: '회원가입은 어떻게 하나요?',
        answer:
          '전화번호로 인증 문자를 보낸 뒤, 화면에 안내된 번호로 인증 문자를 보내 주세요. 인증이 끝나면 이름과 약관 동의로 가입을 마칩니다.',
      },
      {
        question: '무료로 시작할 수 있나요?',
        answer:
          '네. 계정 만들고 자기소개·목차 확인 후 자서전 작성을 바로 시작할 수 있습니다.',
      },
      {
        question: '카카오 로그인은 되나요?',
        answer:
          '카카오 로그인은 준비 중입니다. 지금은 전화번호 인증으로 이용해 주세요.',
      },
    ],
  },
  {
    id: 'intro',
    label: '자기소개·목차',
    items: [
      {
        question: '자기소개는 왜 하나요?',
        answer:
          '답변을 바탕으로 맞춤 목차를 만듭니다. 나중에 목차에서 이름을 바꾸거나 순서를 조정할 수 있습니다.',
      },
      {
        question: '목차가 마음에 안 들어요.',
        answer:
          '목차 화면에서 이름을 바꾸거나, 장을 추가·삭제·순서 변경한 뒤 확정해 주세요.',
      },
    ],
  },
  {
    id: 'write',
    label: '작성·전송·저장',
    items: [
      {
        question: '답을 보내면 어떻게 되나요?',
        answer:
          '답을 보내면 AI가 이어서 물을 꼬리질문을 준비하고, 답변을 모아 장 단위 원고로 다듬습니다.',
      },
      {
        question: '질문을 건너뛸 수 있나요?',
        answer:
          '네. 작성 화면의 「건너뛰기」로 해당 질문을 넘어갈 수 있습니다.',
      },
      {
        question: '중간에 나가도 되나요?',
        answer:
          '네. 작성 중인 초안은 자동으로 저장됩니다. 홈이나 작성 탭에서 이어서 쓸 수 있어요.',
      },
    ],
  },
  {
    id: 'voice',
    label: '음성 입력',
    items: [
      {
        question: '음성이 안 돼요.',
        answer:
          '기기 설정에서 마이크 권한을 허용해 주세요. 허용 후에도 안 되면 키보드로 입력해 주세요.',
      },
      {
        question: '말한 내용이 틀리게 나와요.',
        answer:
          '인식된 글자를 확인·수정한 뒤 전송해 주세요. 자동으로 저장되지 않습니다.',
      },
    ],
  },
  {
    id: 'mypage',
    label: '나의 자서전',
    items: [
      {
        question: '진행률은 어디서 보나요?',
        answer:
          '홈과 「나의 자서전」에서 전체 진행과 장별 완료 현황을 확인할 수 있습니다.',
      },
      {
        question: '장 리뷰는 언제 하나요?',
        answer:
          '그 장의 질문을 모두 마치면 리뷰에서 종합 원고를 읽고 저장할 수 있습니다.',
      },
    ],
  },
  {
    id: 'preview',
    label: '미리보기·내보내기',
    items: [
      {
        question: '전자책은 언제 받을 수 있나요?',
        answer:
          '리뷰를 저장한 장부터 전자책 미리보기·다운로드 자격이 생깁니다. 책 상세에서 전자책을 열어 주세요.',
      },
      {
        question: '오디오북은 어떻게 만들어요?',
        answer:
          '책 상세의 오디오북에서 목소리·BGM을 고른 뒤 생성을 요청하면 됩니다. 플랜에 따라 횟수가 다를 수 있어요.',
      },
    ],
  },
  {
    id: 'account',
    label: '계정·설정',
    items: [
      {
        question: '배송지는 어디서 바꿔요?',
        answer:
          '설정 → 인쇄본 배송지에서 수령인·연락처·주소를 저장할 수 있습니다.',
      },
      {
        question: '오늘의 질문 알림을 끄고 싶어요.',
        answer:
          '설정에서 「오늘의 질문 알림」 스위치를 끄면 됩니다. 실제 푸시 발송은 준비 중일 수 있어요.',
      },
    ],
  },
  {
    id: 'other',
    label: '기타',
    items: [
      {
        question: '원하는 답이 없어요.',
        answer:
          'QnA에서 문의를 남겨 주세요. 답변이 오면 「내 문의」에서 확인할 수 있습니다.',
      },
    ],
  },
];
