import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { MediaKind } from 'src/common/const/media-kind.enum';
import { MediaSource } from 'src/common/const/media-source.enum';
import { BookModel } from 'src/book/entities/book.entity';

/**
 * [신규] 이미지·MP3·MP4. DB BYTEA가 아니라 object_key.
 * (`erd/new-erd.dbml` media_asset) — updated_at 없음
 */
@Entity('media_asset')
@Index('ix_media_asset_book', ['bookId', 'kind'])
export class MediaAssetModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  @Column({ type: 'enum', enum: MediaKind })
  kind: MediaKind;

  @Column({ type: 'enum', enum: MediaSource })
  source: MediaSource;

  /** 비공개 객체 저장소 키 */
  @Column({ name: 'object_key', type: 'varchar', length: 500 })
  objectKey: string;

  @Column({ name: 'mime_type', type: 'varchar', length: 100 })
  mimeType: string;

  @Column({ name: 'byte_size', type: 'bigint' })
  byteSize: string;

  @Column({ type: 'varchar', length: 128, nullable: true })
  checksum: string | null;

  @Column({ name: 'duration_ms', type: 'int', nullable: true })
  durationMs: number | null;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
