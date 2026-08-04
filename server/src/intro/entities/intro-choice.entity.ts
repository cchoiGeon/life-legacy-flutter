import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { IntroQuestionModel } from './intro-question.entity';

@Entity('intro_choice')
export class IntroChoiceModel extends BaseModel {
  @ManyToOne(() => IntroQuestionModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'intro_question_id' })
  introQuestion: IntroQuestionModel;

  @ManyToOne(() => IntroChoiceModel, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'parent_choice_id' })
  parentChoice: IntroChoiceModel | null;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  @Column({ type: 'varchar', length: 50 })
  label: string;

  @Column({ name: 'axis_value', type: 'boolean', nullable: true })
  axisValue: boolean | null;
}
