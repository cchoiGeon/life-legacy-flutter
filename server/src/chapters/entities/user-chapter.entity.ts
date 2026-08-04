import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { BookModel } from 'src/book/entities/book.entity';
import { ChapterTemplateModel } from 'src/catalog/entities/chapter-template.entity';
import { ChapterSource } from '../const/chapter-source.enum';
import { ChapterStatus } from '../const/chapter-status.enum';

/**
 * 목차 확정 시점에 카탈로그를 **책별로 복제**한 것.
 * 소유권은 book.owner_user_id를 거쳐 확인한다 — user_id를 여기 두지 않는다.
 */
@Entity('user_chapter')
@Unique('ux_user_chapter_order', ['book', 'sortOrder'])
@Index('ix_user_chapter_status', ['book', 'status'])
export class UserChapterModel extends BaseModel {
  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  /** 출처. 카탈로그에서 지워져도 남게 nullable */
  @ManyToOne(() => ChapterTemplateModel, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'chapter_template_id' })
  chapterTemplate: ChapterTemplateModel | null;

  @Column({
    name: 'source_type',
    type: 'enum',
    enum: ChapterSource,
    default: ChapterSource.TEMPLATE,
  })
  sourceType: ChapterSource;

  /** 1부터. "제1장"의 숫자. 사용자가 순서를 바꾸면 다시 매긴다 */
  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  /** 복제 시점의 제목 */
  @Column({ type: 'varchar', length: 100 })
  title: string;

  @Column({ type: 'enum', enum: ChapterStatus, default: ChapterStatus.LOCKED })
  status: ChapterStatus;

  /** 캐시. user_question 개수 */
  @Column({ name: 'question_count', type: 'smallint', default: 0 })
  questionCount: number;

  /** 캐시. answered + skipped 개수 */
  @Column({ name: 'answered_count', type: 'smallint', default: 0 })
  answeredCount: number;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt: Date | null;
}
