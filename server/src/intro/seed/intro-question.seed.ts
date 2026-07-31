import { ConditionAxis } from 'src/common/const/condition-axis.enum';

export type IntroQuestionSeed = {
  code: string;
  text: string;
  subtitle: string;
  hint: string | null;
  axis: ConditionAxis;
  /** [보여줄 글자, 이 선택지가 축을 켜는가] */
  choices: [string, boolean | null][];
};

/**
 * 자기소개 5문항 — 시안 B1~B5.
 *
 * 케이스를 가르는 건 **i3·i4·i5 셋뿐**이다. i1(성함)은 책 표지·호칭용,
 * i2(성별)는 문체 호칭용이라 목차와 무관하다.
 *
 * ⚠️ i5는 4지선다인데 `대학교 이상`만 축을 켠다. 그래도 고른 원본 문자열을
 *    그대로 저장한다 — 나중에 학력별로 질문을 나누고 싶어질 때 데이터가
 *    있어야 한다.
 */
export const INTRO_QUESTION_SEED: IntroQuestionSeed[] = [
  {
    code: 'i1',
    text: '성함을\n알려주세요',
    subtitle: '책 표지에 들어갈 이름이에요',
    hint: '성함을 적어 주세요',
    axis: ConditionAxis.ALWAYS,
    choices: [],
  },
  {
    code: 'i2',
    text: '성별을\n알려주세요',
    subtitle: '책에서 부르는 말을 정할 때 써요',
    hint: null,
    axis: ConditionAxis.ALWAYS,
    choices: [['여성', null], ['남성', null]],
  },
  {
    code: 'i3',
    text: '결혼은\n하셨나요?',
    subtitle: '가족 이야기를 여쭤볼 때 참고해요',
    hint: null,
    axis: ConditionAxis.MARRIAGE,
    choices: [['했어요', true], ['안 했어요', false]],
  },
  {
    code: 'i4',
    text: '자녀가\n있으신가요?',
    subtitle: '자녀 이야기를 여쭤볼지 정해요',
    hint: null,
    axis: ConditionAxis.CHILDREN,
    choices: [['있어요', true], ['없어요', false]],
  },
  {
    code: 'i5',
    text: '학교는 어디까지\n다니셨나요?',
    subtitle: '학창 시절 질문을 고를 때 써요',
    hint: null,
    axis: ConditionAxis.COLLEGE,
    choices: [
      ['초등학교', false],
      ['중학교', false],
      ['고등학교', false],
      ['대학교 이상', true],
    ],
  },
];
