import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { InputMode } from '../const/answer.enum';
import { AnswerModel } from './answer.entity';

/**
 * v1 사양은 질문당 꼬리질문 **정확히 1회**다. 그래도 별도 표로 두는 이유 —
 * answer에 컬럼으로 박으면 2회로 늘릴 때 마이그레이션이 필요하지만,
 * seq만 늘리면 스키마가 그대로다.
 */
@Entity('answer_followup')
@Unique('ux_answer_followup_seq', ['answer', 'seq'])
export class AnswerFollowupModel extends BaseModel {
  @ManyToOne(() => AnswerModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'answer_id' })
  answer: AnswerModel;

  /** v1은 항상 1 */
  @Column({ type: 'smallint', default: 1 })
  seq: number;

  /** AI가 만든 꼬리질문. 요약+공감+질문 한 덩어리 */
  @Column({ name: 'question_text', type: 'text' })
  questionText: string;

  @Column({ name: 'answer_text', type: 'text' })
  answerText: string;

  @Column({ name: 'input_mode', type: 'enum', enum: InputMode })
  inputMode: InputMode;

  @Column({ name: 'spoken_seconds', type: 'smallint', nullable: true })
  spokenSeconds: number | null;
}
