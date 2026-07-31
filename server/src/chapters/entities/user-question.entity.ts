import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { QuestionTemplateModel } from 'src/catalog/entities/question-template.entity';
import { QuestionStatus } from '../const/question-status.enum';
import { UserChapterModel } from './user-chapter.entity';

/**
 * 문구 수정은 status=pending일 때만 허용한다 — 이미 답한 질문의 문구를
 * 바꾸면 저장된 원고와 어긋난다(API 409 ALREADY_ANSWERED).
 */
@Entity('user_question')
@Unique('ux_user_question_order', ['userChapter', 'sortOrder'])
@Index('ix_user_question_status', ['userChapter', 'status'])
export class UserQuestionModel extends BaseModel {
  @ManyToOne(() => UserChapterModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_chapter_id' })
  userChapter: UserChapterModel;

  @ManyToOne(() => QuestionTemplateModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'question_template_id' })
  questionTemplate: QuestionTemplateModel | null;

  /** 장 안에서의 순번. "질문 3 / 6"의 앞 숫자 */
  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  /** 복제 시점의 문구. 사용자가 고칠 수 있다 */
  @Column({ type: 'varchar', length: 500 })
  text: string;

  @Column({ name: 'is_edited', type: 'boolean', default: false })
  isEdited: boolean;

  @Column({ type: 'enum', enum: QuestionStatus, default: QuestionStatus.PENDING })
  status: QuestionStatus;

  @Column({ name: 'answered_at', type: 'timestamptz', nullable: true })
  answeredAt: Date | null;
}
