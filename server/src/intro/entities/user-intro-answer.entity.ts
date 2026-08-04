import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { IntroChoiceModel } from './intro-choice.entity';
import { IntroQuestionModel } from './intro-question.entity';

@Entity('user_intro_answer')
@Unique('ux_user_intro_answer', ['user', 'introQuestion'])
export class UserIntroAnswerModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @ManyToOne(() => IntroQuestionModel, {
    onDelete: 'RESTRICT',
    nullable: false,
  })
  @JoinColumn({ name: 'intro_question_id' })
  introQuestion: IntroQuestionModel;

  @ManyToOne(() => IntroChoiceModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'intro_choice_id' })
  introChoice: IntroChoiceModel | null;

  @ManyToOne(() => IntroChoiceModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'detail_choice_id' })
  detailChoice: IntroChoiceModel | null;

  @Column({ name: 'value_text', type: 'varchar', length: 200, default: '' })
  valueText: string;

  @Column({ name: 'value_json', type: 'jsonb', nullable: true })
  valueJson: string[] | null;

  @Column({ name: 'is_skipped', type: 'boolean', default: false })
  isSkipped: boolean;
}
