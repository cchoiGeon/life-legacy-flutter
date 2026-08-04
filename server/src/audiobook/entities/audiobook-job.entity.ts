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
import { BgmTrackModel } from './bgm-track.entity';

/**
 * [신규] 챕터 단위 오디오북 생성 job.
 * (`erd/new-erd.dbml` audiobook_job)
 */
@Entity('audiobook_job')
@Index('ix_audiobook_job_chapter', ['bookId', 'userChapterId', 'createdAt'])
export class AudiobookJobModel {
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

  /** 생성에 쓴 chapter_review.version */
  @Column({ name: 'source_version', type: 'int' })
  sourceVersion: number;

  @Column({ name: 'voice_code', type: 'varchar', length: 50 })
  voiceCode: string;

  @ManyToOne(() => BgmTrackModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'bgm_track_id' })
  bgmTrack: BgmTrackModel | null;

  @Column({ name: 'bgm_track_id', type: 'uuid', nullable: true })
  bgmTrackId: string | null;

  @Column({
    type: 'enum',
    enum: JobStatus,
    default: JobStatus.PENDING,
  })
  status: JobStatus;

  @Column({ type: 'smallint', default: 0 })
  progress: number;

  @Column({ name: 'error_code', type: 'varchar', length: 60, nullable: true })
  errorCode: string | null;

  @Column({
    name: 'idempotency_key',
    type: 'varchar',
    length: 120,
    unique: true,
    nullable: true,
  })
  idempotencyKey: string | null;

  /** 완성 MP3 로컬/객체 키 (job_part 요약) */
  @Column({ name: 'object_key', type: 'varchar', length: 500, nullable: true })
  objectKey: string | null;

  @Column({ name: 'byte_size', type: 'bigint', nullable: true })
  byteSize: string | null;

  @Column({ name: 'mime_type', type: 'varchar', length: 100, nullable: true })
  mimeType: string | null;

  @Column({ name: 'cost_snapshot', type: 'jsonb', nullable: true })
  costSnapshot: unknown | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
