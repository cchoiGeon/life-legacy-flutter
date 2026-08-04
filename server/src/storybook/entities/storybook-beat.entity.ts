import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { JobStatus } from 'src/common/const/job-status.enum';
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { StorybookJobModel } from './storybook-job.entity';

/**
 * [신규] 스토리북 요약 비트. ERD상 timestamps 없음.
 * (`erd/new-erd.dbml` storybook_beat)
 */
@Entity('storybook_beat')
@Index('ux_storybook_beat_seq', ['storybookJobId', 'seq'], { unique: true })
export class StorybookBeatModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => StorybookJobModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'storybook_job_id' })
  storybookJob: StorybookJobModel;

  @Column({ name: 'storybook_job_id', type: 'uuid' })
  storybookJobId: string;

  @Column({ type: 'smallint' })
  seq: number;

  @Column({ type: 'text' })
  narration: string;

  @Column({ type: 'jsonb', nullable: true })
  facts: unknown | null;

  @Column({ name: 'visual_prompt', type: 'text', nullable: true })
  visualPrompt: string | null;

  /** image | video */
  @Column({ name: 'media_type', type: 'varchar', length: 10 })
  mediaType: string;

  @Column({ name: 'audio_duration_ms', type: 'int', nullable: true })
  audioDurationMs: number | null;

  @ManyToOne(() => MediaAssetModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAssetModel | null;

  @Column({ name: 'media_asset_id', type: 'uuid', nullable: true })
  mediaAssetId: string | null;

  @Column({
    type: 'enum',
    enum: JobStatus,
    default: JobStatus.PENDING,
  })
  status: JobStatus;

  @Column({ name: 'error_code', type: 'varchar', length: 60, nullable: true })
  errorCode: string | null;
}
