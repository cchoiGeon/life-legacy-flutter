import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';

/**
 * API의 time_label("오늘 오전 9:00")은 createdAt을 **서버가 포맷한** 값이다.
 * 기기 시계가 틀어지면 상대 시각이 엉뚱해지므로 앱에서 계산하지 않는다.
 */
@Entity('notification')
@Index('ix_notification_user_recent', ['user', 'createdAt'])
export class NotificationModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  /** daily_question | chapter_done | book_ready */
  @Column({ type: 'varchar', length: 30 })
  type: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  /** 눌렀을 때 갈 질문 */
  @ManyToOne(() => UserQuestionModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'link_user_question_id' })
  linkUserQuestion: UserQuestionModel | null;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt: Date | null;
}
