import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { ChapterReviewModel } from 'src/review/entities/chapter-review.entity';
import { MediaAssetModel } from './media-asset.entity';

/**
 * [신규] 문단 사이 사진 배치.
 * (`erd/new-erd.dbml` media_placement)
 */
@Entity('media_placement')
@Index('ux_media_placement_order', ['chapterReviewId', 'paragraphIndex', 'sortOrder'], {
  unique: true,
})
export class MediaPlacementModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ChapterReviewModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'chapter_review_id' })
  chapterReview: ChapterReviewModel;

  @Column({ name: 'chapter_review_id', type: 'uuid' })
  chapterReviewId: string;

  @ManyToOne(() => MediaAssetModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'media_asset_id' })
  mediaAsset: MediaAssetModel;

  @Column({ name: 'media_asset_id', type: 'uuid' })
  mediaAssetId: string;

  /** 이 문단 뒤에 놓는다 */
  @Column({ name: 'paragraph_index', type: 'int' })
  paragraphIndex: number;

  /** 앞 문장 식별자 — 본문 개정 시 재배치 단서 */
  @Column({ type: 'varchar', length: 200, nullable: true })
  anchor: string | null;

  @Column({ name: 'sort_order', type: 'smallint', default: 0 })
  sortOrder: number;

  /** G3 사용자 작성 사진 설명 */
  @Column({ type: 'text', nullable: true })
  caption: string | null;
}
