import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { QnaStatus } from 'src/common/const/qna-status.enum';
import { AppUserModel } from 'src/users/entities/app-user.entity';

/**
 * [신규] 사용자 문의. FAQ 테이블은 만들지 않음.
 * (`erd/new-erd.dbml` qna_question)
 */
@Entity('qna_question')
@Index('ix_qna_status_created', ['status', 'createdAt'])
@Index('ix_qna_user', ['userId'])
export class QnaQuestionModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 30, nullable: true })
  category: string | null;

  @Column({ type: 'text' })
  question: string;

  @Column({
    type: 'enum',
    enum: QnaStatus,
    default: QnaStatus.PENDING,
  })
  status: QnaStatus;

  @Column({ type: 'text', nullable: true })
  answer: string | null;

  @Column({ name: 'answered_by', type: 'varchar', length: 100, nullable: true })
  answeredBy: string | null;

  @Column({ name: 'answered_at', type: 'timestamptz', nullable: true })
  answeredAt: Date | null;

  /** 내부용. 공개 응답에 절대 포함하지 않는다 */
  @Column({ name: 'admin_note', type: 'text', nullable: true })
  adminNote: string | null;

  @Column({ name: 'published_at', type: 'timestamptz', nullable: true })
  publishedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
