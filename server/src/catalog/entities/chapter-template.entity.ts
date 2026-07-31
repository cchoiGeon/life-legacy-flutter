import { Column, Entity } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { ConditionAxis } from 'src/common/const/condition-axis.enum';

/**
 * 대주제 10개. 이 중 **3개만 조건부**다 —
 *   code 4  20대 시절-대학생활  condition=college
 *   code 6  결혼 이야기         condition=marriage
 *   code 7  자녀 이야기         condition=children
 * 나머지 7개는 always(36문항).
 *
 * 케이스별 목차를 따로 저장하지 않는 이유: 대주제를 하나 추가할 때 8개
 * 케이스를 모두 손대야 하는 구조를 피하려는 것이다. 목차 =
 * chapter_template 중 condition을 사용자 축이 만족하는 것들.
 */
@Entity('chapter_template')
export class ChapterTemplateModel extends BaseModel {
  /** 1~10. 문서의 대주제 번호 */
  @Column({ type: 'smallint', unique: true })
  code: number;

  @Column({ type: 'varchar', length: 100 })
  title: string;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  @Column({ type: 'enum', enum: ConditionAxis, default: ConditionAxis.ALWAYS })
  condition: ConditionAxis;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
