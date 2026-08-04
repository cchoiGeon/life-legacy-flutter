import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';
import { BookModel } from './book.entity';

/**
 * done 장의 polishedText를 이어 붙여 서버가 쪽을 나눈 결과.
 * 책이 범위다 — user_id를 두지 않는다.
 */
@Entity('book_page')
@Unique('ux_book_page_number', ['book', 'pageNumber'])
@Index('ix_book_page_chapter', ['userChapter'])
export class BookPageModel extends BaseModel {
  @ManyToOne(() => BookModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'book_id' })
  book: BookModel;

  @Column({ name: 'book_id', type: 'uuid' })
  bookId: string;

  @ManyToOne(() => UserChapterModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_chapter_id' })
  userChapter: UserChapterModel;

  /** 책 전체 통쪽수. 장마다 1로 돌아가지 않는다 */
  @Column({ name: 'page_number', type: 'int' })
  pageNumber: number;

  /** string[]. 문단 단위 */
  @Column({ type: 'jsonb' })
  paragraphs: string[];
}
