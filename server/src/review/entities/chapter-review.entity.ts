import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { ReviewStatus } from 'src/common/const/review-status.enum';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';

/**
 * [신규] 챕터 종합 원고. reviewed의 단일 정의.
 * (`erd/new-erd.dbml` chapter_review)
 */
@Entity('chapter_review')
export class ChapterReviewModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => UserChapterModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_chapter_id' })
  userChapter: UserChapterModel;

  @Column({ name: 'user_chapter_id', type: 'uuid', unique: true })
  userChapterId: string;

  /** 현재 원고. 웹에서 사용자가 직접 고칠 수 있다 */
  @Column({ type: 'text' })
  body: string;

  /** AI 종합 초안 원본. body를 고쳐도 남긴다 */
  @Column({ name: 'ai_draft', type: 'text', nullable: true })
  aiDraft: string | null;

  /** body가 바뀔 때마다 올린다 */
  @Column({ type: 'int', default: 1 })
  version: number;

  @Column({
    type: 'enum',
    enum: ReviewStatus,
    default: ReviewStatus.DRAFT,
  })
  status: ReviewStatus;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
