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

import { BookModel } from 'src/book/entities/book.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';

/**
 * 종이책(인쇄본) 신청 stub — 앱 결제는 없고 신청만 접수한다.
 */
@Entity('print_order')
@Index('ix_print_order_user', ['userId'])
@Index('ix_print_order_book', ['bookId'])
export class PrintOrderModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  /** requested | cancelled — 결제 연동 전 stub */
  @Column({ type: 'varchar', length: 30, default: 'requested' })
  status: string;

  /** 신청 시점 배송지 스냅샷 (JSON) */
  @Column({ name: 'address_snapshot', type: 'jsonb' })
  addressSnapshot: Record<string, string>;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
