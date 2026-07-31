import { ConditionAxis } from 'src/common/const/condition-axis.enum';

/** 자기소개 답변에서 뽑아낸 세 축 */
export type CaseAxes = {
  hasCollege: boolean;
  hasMarriage: boolean;
  hasChildren: boolean;
};

/**
 * 대주제를 목차에 넣을지 판정한다.
 *
 * 조건부는 셋뿐이고 나머지는 늘 들어간다. **케이스별 목차를 저장하지 않는
 * 이유가 이 함수다** — 대주제를 하나 추가해도 고칠 곳이 여기 한 곳이다.
 */
export function isChapterIncluded(
  condition: ConditionAxis,
  axes: CaseAxes,
): boolean {
  switch (condition) {
    case ConditionAxis.COLLEGE:
      return axes.hasCollege;
    case ConditionAxis.MARRIAGE:
      return axes.hasMarriage;
    case ConditionAxis.CHILDREN:
      return axes.hasChildren;
    case ConditionAxis.ALWAYS:
    default:
      return true;
  }
}
