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
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';
import { AudiobookJobModel } from './audiobook-job.entity';

/**
 * [신규] 오디오북 청크 단위.
 * (`erd/new-erd.dbml` audiobook_job_part)
 */
@Entity('audiobook_job_part')
@Index('ux_audiobook_part_seq', ['audiobookJobId', 'seq'], { unique: true })
export class AudiobookJobPartModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AudiobookJobModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'audiobook_job_id' })
  audiobookJob: AudiobookJobModel;

  @Column({ name: 'audiobook_job_id', type: 'uuid' })
  audiobookJobId: string;

  @Column({ type: 'smallint' })
  seq: number;

  @Column({ name: 'text_length', type: 'int' })
  textLength: number;

  @Column({
    type: 'enum',
    enum: JobStatus,
    default: JobStatus.PENDING,
  })
  status: JobStatus;

  @ManyToOne(() => MediaAssetModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAssetModel | null;

  @Column({ name: 'media_asset_id', type: 'uuid', nullable: true })
  mediaAssetId: string | null;

  @Column({ name: 'error_code', type: 'varchar', length: 60, nullable: true })
  errorCode: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
