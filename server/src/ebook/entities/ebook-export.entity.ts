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
import { MediaAssetModel } from 'src/media/entities/media-asset.entity';

/**
 * [신규] 전자책 생성 결과. reviewed 장 전부.
 * (`erd/new-erd.dbml` ebook_export)
 */
@Entity('ebook_export')
@Index('ix_ebook_export_book', ['bookId', 'format', 'createdAt'])
export class EbookExportModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  /** pdf | docx */
  @Column({ type: 'varchar', length: 10 })
  format: string;

  /** [{chapter_id, version}] */
  @Column({ name: 'chapter_snapshot', type: 'jsonb' })
  chapterSnapshot: unknown;

  /** default | user */
  @Column({ name: 'cover_kind', type: 'varchar', length: 10, default: 'default' })
  coverKind: string;

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
