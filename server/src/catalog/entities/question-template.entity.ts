import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { ChapterTemplateModel } from './chapter-template.entity';

/**
 * 총 52문항(대주제별 5~6개). 케이스별로 문구가 달라지지 않으므로 케이스
 * 축으로 복제하지 않는다.
 */
@Entity('question_template')
@Unique('ux_question_template_order', ['chapterTemplate', 'sortOrder'])
export class QuestionTemplateModel extends BaseModel {
  @ManyToOne(() => ChapterTemplateModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'chapter_template_id' })
  chapterTemplate: ChapterTemplateModel;

  @Column({ name: 'sort_order', type: 'smallint' })
  sortOrder: number;

  @Column({ type: 'varchar', length: 500 })
  text: string;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
