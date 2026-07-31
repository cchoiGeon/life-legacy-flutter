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

  /** 선택지 문항일 때. 텍스트 문항이면 null */
  @ManyToOne(() => IntroChoiceModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'intro_choice_id' })
  introChoice: IntroChoiceModel | null;

  /** 고르거나 적은 **원본 문자열**. 판정용으로 접지 않는다 */
  @Column({ name: 'value_text', type: 'varchar', length: 200 })
  valueText: string;
}
