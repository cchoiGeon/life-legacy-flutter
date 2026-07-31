export type CaseSeed = {
  caseKey: string;
  title: string;
  description: string;
  hasCollege: boolean;
  hasMarriage: boolean;
  hasChildren: boolean;
  sortOrder: number;
};

/**
 * 케이스 8종 — `docs/목차-케이스.md` 기준.
 *
 * 세 축(대학·결혼·자녀)이 **서로 독립**이라 2x2x2 = 8이다.
 * caseKey는 웹(lifelegacy-web)의 case_definition 명명을 그대로 따랐다.
 */
export const CASE_SEED: CaseSeed[] = [
  {
    caseKey: 'legacy_college_married_children',
    title: '대학생활·결혼·자녀 경험',
    description:
      '대학생활, 결혼, 자녀 이야기를 모두 포함하는 기본 자서전 흐름입니다.',
    hasCollege: true,
    hasMarriage: true,
    hasChildren: true,
    sortOrder: 1,
  },
  {
    caseKey: 'legacy_college_married_no_children',
    title: '대학생활·결혼 경험',
    description: '대학생활과 결혼 이야기를 포함하고 자녀 목차는 제외합니다.',
    hasCollege: true,
    hasMarriage: true,
    hasChildren: false,
    sortOrder: 2,
  },
  {
    caseKey: 'legacy_college_single_no_children',
    title: '대학생활 중심의 미혼 경험',
    description:
      '대학생활과 직장생활을 중심으로 구성하고 결혼·자녀 목차는 제외합니다.',
    hasCollege: true,
    hasMarriage: false,
    hasChildren: false,
    sortOrder: 3,
  },
  {
    caseKey: 'legacy_no_college_married_children',
    title: '직장·결혼·자녀 경험',
    description:
      '대학생활 목차를 제외하고 직장, 결혼, 자녀 이야기를 중심으로 구성합니다.',
    hasCollege: false,
    hasMarriage: true,
    hasChildren: true,
    sortOrder: 4,
  },
  {
    caseKey: 'legacy_no_college_married_no_children',
    title: '직장·결혼 경험',
    description:
      '대학생활과 자녀 목차를 제외하고 직장과 결혼 이야기를 중심으로 구성합니다.',
    hasCollege: false,
    hasMarriage: true,
    hasChildren: false,
    sortOrder: 5,
  },
  {
    caseKey: 'legacy_no_college_single_no_children',
    title: '직장 중심의 미혼 경험',
    description:
      '직장생활을 중심으로 구성하고 대학·결혼·자녀 목차는 제외합니다.',
    hasCollege: false,
    hasMarriage: false,
    hasChildren: false,
    sortOrder: 6,
  },
  {
    caseKey: 'legacy_college_single_children',
    title: '대학생활·자녀 경험',
    description: '대학생활과 자녀 이야기를 포함하고 결혼 목차는 제외합니다.',
    hasCollege: true,
    hasMarriage: false,
    hasChildren: true,
    sortOrder: 7,
  },
  {
    caseKey: 'legacy_no_college_single_children',
    title: '직장·자녀 경험',
    description:
      '직장과 자녀 이야기를 중심으로 구성하고 대학·결혼 목차는 제외합니다.',
    hasCollege: false,
    hasMarriage: false,
    hasChildren: true,
    sortOrder: 8,
  },
];
