import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { DraftPhase, InputMode } from '../const/answer.enum';

/**
 * 확정 전 임시 저장. 확정되면 삭제한다.
 *
 * 실패 처리가 두 갈래다 —
 *   꼬리질문 생성 실패(422 FOLLOWUP_FAILED)
 *     → 이 행을 **삭제**한다. 사용자는 질문부터 다시 답한다.
 *       (아직 한 번밖에 답하지 않은 시점이라 감수한다)
 *   윤문 실패(422 POLISH_FAILED)
 *     → 이 행을 **남긴다**. 앱은 같은 요청을 재전송하고 서버는 멱등하게
 *       처리한다. 두 번 답한 이야기를 날리지 않는다.
 */
@Entity('answer_draft')
export class AnswerDraftModel extends BaseModel {
  @OneToOne(() => UserQuestionModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_question_id' })
  userQuestion: UserQuestionModel;

  @Column({ type: 'enum', enum: DraftPhase, default: DraftPhase.FIRST })
  phase: DraftPhase;

  @Column({ name: 'first_text', type: 'text' })
  firstText: string;

  @Column({ name: 'first_input_mode', type: 'enum', enum: InputMode })
  firstInputMode: InputMode;

  @Column({ name: 'first_spoken_seconds', type: 'smallint', nullable: true })
  firstSpokenSeconds: number | null;

  /** 지금까지 주고받은 꼬리질문 회차 (1…MAX) */
  @Column({ name: 'followup_round', type: 'smallint', default: 0 })
  followupRound: number;

  /**
   * 이미 답한 꼬리 Q-A. 확정 시 answer_followup으로 옮긴다.
   * [{ seq, question, answer, input_mode, spoken_seconds }]
   */
  @Column({ type: 'jsonb', nullable: true })
  followups: Array<{
    seq: number;
    question: string;
    answer: string;
    input_mode: string;
    spoken_seconds: number | null;
  }> | null;

  /** AI가 만든 꼬리질문. phase=followup부터 채워진다 */
  @Column({ name: 'followup_question_text', type: 'text', nullable: true })
  followupQuestionText: string | null;

  /** API 경로의 followup_id. 앱이 되돌려 보낸다 */
  @Column({ name: 'followup_id', type: 'uuid', nullable: true })
  followupId: string | null;
}
