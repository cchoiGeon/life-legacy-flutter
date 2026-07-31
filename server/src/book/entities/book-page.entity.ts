import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { UserChapterModel } from 'src/chapters/entities/user-chapter.entity';

/**
 * done 장의 polishedText를 이어 붙여 서버가 쪽을 나눈 결과.
 * 장이 완료될 때마다 그 장의 쪽을 다시 만든다(기존 행 삭제 후 재삽입).
 * 앱은 받은 대로 그리기만 한다.
 */
@Entity('book_page')
@Unique('ux_book_page_number', ['user', 'pageNumber'])
@Index('ix_book_page_chapter', ['userChapter'])
export class BookPageModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

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
