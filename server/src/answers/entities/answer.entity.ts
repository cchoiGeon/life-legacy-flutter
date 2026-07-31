import { Column, Entity, JoinColumn, OneToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { InputMode, PolishStatus } from '../const/answer.enum';

/**
 * 질문 1개 = 묶음 1개. (원질문, 1차 답변, 꼬리질문, 꼬리답변, 윤문 결과)
 *
 * 사용자에게 보이는 것은 firstText(와 꼬리답변)뿐이다. polishedText가 처음
 * 눈에 띄는 곳은 자서전 미리보기(book_page)다.
 *
 * 건너뛴 질문은 이 행을 만들지 않는다 — user_question.status=skipped로만 남는다.
 */
@Entity('answer')
export class AnswerModel extends BaseModel {
  @OneToOne(() => UserQuestionModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_question_id' })
  userQuestion: UserQuestionModel;

  /** 답변 당시의 질문 문구 스냅샷 */
  @Column({ name: 'question_text', type: 'varchar', length: 500 })
  questionText: string;

  /** 사용자 원문. 음성이면 받아쓴 결과 그대로 */
  @Column({ name: 'first_text', type: 'text' })
  firstText: string;

  @Column({ name: 'first_input_mode', type: 'enum', enum: InputMode })
  firstInputMode: InputMode;

  @Column({ name: 'first_spoken_seconds', type: 'smallint', nullable: true })
  firstSpokenSeconds: number | null;

  /** AI 작가체 윤문 결과. 작성 화면에서는 보여주지 않는다 */
  @Column({ name: 'polished_text', type: 'text', nullable: true })
  polishedText: string | null;

  @Column({
    name: 'polish_status',
    type: 'enum',
    enum: PolishStatus,
    default: PolishStatus.OK,
  })
  polishStatus: PolishStatus;

  @Column({ name: 'polish_attempts', type: 'smallint', default: 0 })
  polishAttempts: number;

  @Column({ name: 'answered_at', type: 'timestamptz', default: () => 'now()' })
  answeredAt: Date;
}
