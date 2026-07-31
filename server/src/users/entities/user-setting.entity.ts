import { Column, Entity, JoinColumn, OneToOne, PrimaryColumn } from 'typeorm';

import { AppUserModel } from './app-user.entity';

/** v1에서 켜고 끌 수 있는 건 "오늘의 질문 알림" 하나뿐이다 */
@Entity('user_setting')
export class UserSettingModel {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => AppUserModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'daily_question_alarm', type: 'boolean', default: true })
  dailyQuestionAlarm: boolean;
}
