import { Column, Entity } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { ConditionAxis } from 'src/common/const/condition-axis.enum';

/** 5문항 고정. 문항이 늘면 이 표에 줄만 늘린다 */
@Entity('intro_question')
export class IntroQuestionModel extends BaseModel {
  /** i1 ~ i5. API의 question_id */
  @Column({ type: 'varchar', length: 10, unique: true })
  code: string;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  /** \n이 줄바꿈 위치다 — 시안이 끊어 놓은 자리를 그대로 준다 */
  @Column({ type: 'varchar', length: 200 })
  text: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  subtitle: string | null;

  /** choices가 없을 때만 쓰는 placeholder */
  @Column({ type: 'varchar', length: 100, nullable: true })
  hint: string | null;

  /** i3=marriage, i4=children, i5=college, i1·i2=always(케이스와 무관) */
  @Column({ type: 'enum', enum: ConditionAxis, default: ConditionAxis.ALWAYS })
  axis: ConditionAxis;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
