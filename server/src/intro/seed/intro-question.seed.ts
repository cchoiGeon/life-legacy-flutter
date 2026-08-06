import { ConditionAxis } from 'src/common/const/condition-axis.enum';
import { IntroAnswerType } from '../const/intro-answer-type.enum';

export type IntroChoiceSeed = {
  label: string;
  axisValue: boolean | null;
  /** 선택 직후 같은 화면에 뜨는 상세. 없으면 생략 */
  details?: { label: string }[];
};

export type IntroQuestionSeed = {
  code: string;
  text: string;
  subtitle: string | null;
  hint: string | null;
  answerType: IntroAnswerType;
  skippable: boolean;
  axis: ConditionAxis;
  choices: IntroChoiceSeed[];
};

/**
 * 자기소개 문항 — api-spec §2.1.
 * i1(성함)은 가입 이름으로 옮겼다.
 * i2·i6는 서버에 따로 두되, 앱 UI는 한 화면으로 합친다.
 */
export const INTRO_QUESTION_SEED: IntroQuestionSeed[] = [
  {
    code: 'i2',
    text: '성별과 생년월일을\n알려주세요',
    subtitle: '책에서 부르는 말과 나이 맞춤 질문에 써요',
    hint: null,
    answerType: IntroAnswerType.CHOICE,
    skippable: false,
    axis: ConditionAxis.ALWAYS,
    choices: [
      { label: '남', axisValue: null },
      { label: '여', axisValue: null },
    ],
  },
  {
    code: 'i6',
    text: '생년월일',
    subtitle: null,
    hint: null,
    answerType: IntroAnswerType.DATE,
    skippable: false,
    axis: ConditionAxis.ALWAYS,
    choices: [],
  },
  {
    code: 'i3',
    text: '결혼은\n하셨나요?',
    subtitle: '가족 이야기를 여쭤볼 때 참고해요',
    hint: null,
    answerType: IntroAnswerType.CHOICE,
    skippable: true,
    axis: ConditionAxis.MARRIAGE,
    choices: [
      { label: '예', axisValue: true },
      { label: '아니오', axisValue: false },
    ],
  },
  {
    code: 'i4',
    text: '자녀가\n있으신가요?',
    subtitle: '자녀 이야기를 여쭤볼지 정해요',
    hint: null,
    answerType: IntroAnswerType.CHOICE,
    skippable: true,
    axis: ConditionAxis.CHILDREN,
    choices: [
      { label: '예', axisValue: true },
      { label: '아니오', axisValue: false },
    ],
  },
  {
    code: 'i5',
    text: '학교는 어디까지\n다니셨나요?',
    subtitle: '학창 시절 질문을 고를 때 써요',
    hint: null,
    answerType: IntroAnswerType.CHOICE,
    skippable: false,
    axis: ConditionAxis.COLLEGE,
    choices: [
      {
        label: '초등학교',
        axisValue: false,
        details: [{ label: '초등학교' }, { label: '국민학교' }],
      },
      { label: '중학교', axisValue: false },
      { label: '고등학교', axisValue: false },
      {
        label: '대학교 이상',
        axisValue: true,
        details: [
          { label: '학사' },
          { label: '석사' },
          { label: '박사' },
        ],
      },
    ],
  },
];
