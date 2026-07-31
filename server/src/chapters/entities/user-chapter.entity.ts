import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { ChapterTemplateModel } from 'src/catalog/entities/chapter-template.entity';
import { ChapterStatus } from '../const/chapter-status.enum';

/**
 * 목차 확정 시점에 카탈로그를 **사용자별로 복제**한 것.
 *   이유 1: 질문 문구 수정이 다른 사용자에게 번지면 안 된다
 *   이유 2: 카탈로그가 바뀌어도 쓰기 시작한 자서전은 흔들리면 안 된다
 *
 * 장 순차 잠금 —
 *   목차 확정 시 sortOrder=1만 writing, 나머지 locked.
 *   한 장이 done이 되면 다음 장 하나만 writing으로 연다.
 *   writing은 사용자당 최대 1개다(앱이 이 가정 위에 서 있다).
 */
@Entity('user_chapter')
@Unique('ux_user_chapter_order', ['user', 'sortOrder'])
@Index('ix_user_chapter_status', ['user', 'status'])
export class UserChapterModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  /** 출처. 카탈로그에서 지워져도 남게 nullable */
  @ManyToOne(() => ChapterTemplateModel, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'chapter_template_id' })
  chapterTemplate: ChapterTemplateModel | null;

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
