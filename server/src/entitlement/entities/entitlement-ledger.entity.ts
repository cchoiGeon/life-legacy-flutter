import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';
import { BookModel } from 'src/book/entities/book.entity';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';

/**
 * [신규] 생성 한도 소모·복구 이력.
 * (`erd/new-erd.dbml` entitlement_ledger)
 */
@Entity('entitlement_ledger')
@Index('ix_ledger_usage', ['userId', 'feature', 'createdAt'])
export class EntitlementLedgerModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => BookModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'book_id' })
  book: BookModel | null;

  @Column({ name: 'book_id', type: 'uuid', nullable: true })
  bookId: string | null;

  @ManyToOne(() => UserChapterModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'user_chapter_id' })
  userChapter: UserChapterModel | null;

  @Column({ name: 'user_chapter_id', type: 'uuid', nullable: true })
  userChapterId: string | null;

  @Column({ type: 'varchar', length: 30 })
  feature: string;

  /** 차감 -1, 복구 +1 */
  @Column({ type: 'smallint' })
  delta: number;

  @Column({ type: 'varchar', length: 60 })
  reason: string;

  @Column({ name: 'idempotency_key', type: 'varchar', length: 120, unique: true })
  idempotencyKey: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
