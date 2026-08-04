import { Column, Entity } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { ConditionAxis } from 'src/common/const/condition-axis.enum';
import { IntroAnswerType } from '../const/intro-answer-type.enum';

@Entity('intro_question')
export class IntroQuestionModel extends BaseModel {
  /** i2 ~ i6. API의 question_id */
  @Column({ type: 'varchar', length: 10, unique: true })
  code: string;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  @Column({ type: 'varchar', length: 200 })
  text: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  subtitle: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  hint: string | null;

  @Column({
    name: 'answer_type',
    type: 'enum',
    enum: IntroAnswerType,
    default: IntroAnswerType.CHOICE,
  })
  answerType: IntroAnswerType;

  @Column({ name: 'is_skippable', type: 'boolean', default: false })
  isSkippable: boolean;

  @Column({ type: 'enum', enum: ConditionAxis, default: ConditionAxis.ALWAYS })
  axis: ConditionAxis;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
