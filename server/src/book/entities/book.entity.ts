import { Column, Entity, JoinColumn, OneToOne, PrimaryColumn } from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';

/**
 * chapterCount / questionCount는 user_chapter에서 집계한다 — 여기 복사하지
 * 않는다. 두 곳에 두면 어긋난 채로 굳는다.
 */
@Entity('book')
export class BookModel {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => AppUserModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ type: 'varchar', length: 100, default: '나의 이야기' })
  title: string;

  @Column({ name: 'author_name', type: 'varchar', length: 50 })
  authorName: string;

  @Column({ name: 'page_count', type: 'int', default: 0 })
  pageCount: number;

  /** v1은 항상 0. 사진 첨부는 2차 */
  @Column({ name: 'photo_count', type: 'int', default: 0 })
  photoCount: number;

  /** 모든 장이 done */
  @Column({ name: 'is_complete', type: 'boolean', default: false })
  isComplete: boolean;

  /** 마지막으로 쪽을 다시 나눈 시각 */
  @Column({ name: 'generated_at', type: 'timestamptz', nullable: true })
  generatedAt: Date | null;
}
