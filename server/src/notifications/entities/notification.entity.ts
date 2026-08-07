import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { BookModel } from 'src/book/entities/book.entity';
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

  /**
   * 다권에서 어느 책의 알림인지.
   * 예전 행은 null일 수 있다 — 그때는 linkUserQuestion → chapter → book으로 보완.
   */
  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'book_id' })
  book: BookModel | null;

  @Column({ name: 'book_id', type: 'uuid', nullable: true })
  bookId: string | null;

  /** daily_question | chapter_done | book_ready */
  @Column({ type: 'varchar', length: 30 })
  type: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  /** 눌렀을 때 갈 질문 (daily_question · chapter_done 보조) */
  @ManyToOne(() => UserQuestionModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'link_user_question_id' })
  linkUserQuestion: UserQuestionModel | null;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt: Date | null;
}
