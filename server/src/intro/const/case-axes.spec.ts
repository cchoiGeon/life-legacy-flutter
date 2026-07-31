import { ConditionAxis } from 'src/common/const/condition-axis.enum';
import { isChapterIncluded } from './case-axes';

/**
 * 케이스 8종이 결국 이 함수 하나로 갈린다.
 * `docs/목차-케이스.md`의 장 수가 그대로 나오는지 잰다.
 */
describe('isChapterIncluded', () => {
  const ALL_CONDITIONS = [
    ConditionAxis.ALWAYS,
    ConditionAxis.ALWAYS,
    ConditionAxis.ALWAYS,
    ConditionAxis.COLLEGE,
    ConditionAxis.ALWAYS,
    ConditionAxis.MARRIAGE,
    ConditionAxis.CHILDREN,
    ConditionAxis.ALWAYS,
    ConditionAxis.ALWAYS,
    ConditionAxis.ALWAYS,
  ];

  const countChapters = (axes: {
    hasCollege: boolean;
    hasMarriage: boolean;
    hasChildren: boolean;
  }) => ALL_CONDITIONS.filter((c) => isChapterIncluded(c, axes)).length;

  it.each([
    ['대학O 결혼O 자녀O', true, true, true, 10],
    ['대학O 결혼O 자녀X', true, true, false, 9],
    ['대학O 결혼X 자녀X', true, false, false, 8],
    ['대학X 결혼O 자녀O', false, true, true, 9],
    ['대학X 결혼O 자녀X', false, true, false, 8],
    ['대학X 결혼X 자녀X', false, false, false, 7],
    ['대학O 결혼X 자녀O', true, false, true, 9],
    ['대학X 결혼X 자녀O', false, false, true, 8],
  ])('%s → %s장', (_label, hasCollege, hasMarriage, hasChildren, expected) => {
    expect(
      countChapters({
        hasCollege: hasCollege,
        hasMarriage: hasMarriage,
        hasChildren: hasChildren,
      }),
    ).toBe(expected);
  });

  it('조건 없는 대주제는 어떤 축에서도 들어간다', () => {
    const off = { hasCollege: false, hasMarriage: false, hasChildren: false };
    expect(isChapterIncluded(ConditionAxis.ALWAYS, off)).toBe(true);
  });
});
