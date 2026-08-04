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

import { AppUserModel } from 'src/users/entities/app-user.entity';

/**
 * 사용자 1 : N 책. (`erd/new-erd.dbml` 다권 계약)
 *
 * v1은 `user_id`가 PK였다. 이제 `id`가 PK이고 소유는 `owner_user_id`.
 * status 컬럼은 두지 않는다 — user_chapter / chapter_review에서 파생한다.
 */
@Entity('book')
@Index('ix_book_owner', ['ownerUserId', 'createdAt'])
export class BookModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'owner_user_id', type: 'uuid' })
  ownerUserId: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'owner_user_id' })
  owner: AppUserModel;

  @Column({ type: 'varchar', length: 100, default: '나의 이야기' })
  title: string;

  @Column({ name: 'author_name', type: 'varchar', length: 50 })
  authorName: string;

  @Column({ name: 'page_count', type: 'int', default: 0 })
  pageCount: number;

  /** v1은 항상 0. 사진 첨부는 리뷰 화면 범위 */
  @Column({ name: 'photo_count', type: 'int', default: 0 })
  photoCount: number;

  /**
   * 모든 장이 done. 산출물 자격(reviewed)과 다른 캐시값.
   * 목록 UX용 — 정식 status는 파생값(§6.1).
   */
  @Column({ name: 'is_complete', type: 'boolean', default: false })
  isComplete: boolean;

  @Column({ name: 'generated_at', type: 'timestamptz', nullable: true })
  generatedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
