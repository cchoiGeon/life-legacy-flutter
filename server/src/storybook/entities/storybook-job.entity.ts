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

import { JobStatus } from 'src/common/const/job-status.enum';
import { BookModel } from 'src/book/entities/book.entity';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';

/**
 * [신규] 스토리북 MP4 job. 웹 전용.
 * (`erd/new-erd.dbml` storybook_job)
 */
@Entity('storybook_job')
@Index('ix_storybook_job_chapter', ['bookId', 'userChapterId', 'createdAt'])
export class StorybookJobModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  @ManyToOne(() => UserChapterModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_chapter_id' })
  userChapter: UserChapterModel;

  @Column({ name: 'user_chapter_id', type: 'uuid' })
  userChapterId: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'requested_by' })
  requestedByUser: AppUserModel;

  @Column({ name: 'requested_by', type: 'uuid' })
  requestedBy: string;

  @Column({ name: 'source_version', type: 'int' })
  sourceVersion: number;

  /** hybrid | video_only | image_only */
  @Column({ name: 'media_mode', type: 'varchar', length: 12, default: 'hybrid' })
  mediaMode: string;

  @Column({ name: 'model_snapshot', type: 'jsonb', nullable: true })
  modelSnapshot: unknown | null;

  @Column({
    type: 'enum',
    enum: JobStatus,
    default: JobStatus.PENDING,
  })
  status: JobStatus;

  /** script | audio | media | mux */
  @Column({ type: 'varchar', length: 20, nullable: true })
  stage: string | null;

  @ManyToOne(() => MediaAssetModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAssetModel | null;

  @Column({ name: 'media_asset_id', type: 'uuid', nullable: true })
  mediaAssetId: string | null;

  @Column({ name: 'error_code', type: 'varchar', length: 60, nullable: true })
  errorCode: string | null;

  @Column({ name: 'cost_snapshot', type: 'jsonb', nullable: true })
  costSnapshot: unknown | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
