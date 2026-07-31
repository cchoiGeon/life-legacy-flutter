import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { UserQuestionModel } from 'src/chapters/entities/user-question.entity';
import { AiTaskKind } from '../const/ai-task-kind.enum';

/**
 * 실패 두 종(FOLLOWUP_FAILED / POLISH_FAILED)이 얼마나 자주 나는지가 이
 * 서비스의 체감 품질을 좌우한다. 재시도 횟수와 원인을 남긴다.
 *
 * ⚠️ 본문(프롬프트·응답)은 남기지 않는다 — 민감 개인정보다.
 */
@Entity('ai_generation_log')
@Index('ix_ai_log_question', ['userQuestion', 'kind'])
@Index('ix_ai_log_time', ['createdAt'])
export class AiGenerationLogModel extends BaseModel {
  @ManyToOne(() => UserQuestionModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_question_id' })
  userQuestion: UserQuestionModel;

  @Column({ type: 'enum', enum: AiTaskKind })
  kind: AiTaskKind;

  @Column({ type: 'varchar', length: 60 })
  model: string;

  @Column({ name: 'prompt_template_version', type: 'int', nullable: true })
  promptTemplateVersion: number | null;

  @Column({ type: 'smallint', default: 1 })
  attempt: number;

  @Column({ type: 'boolean' })
  succeeded: boolean;

  @Column({ name: 'error_code', type: 'varchar', length: 60, nullable: true })
  errorCode: string | null;

  @Column({ name: 'input_tokens', type: 'int', nullable: true })
  inputTokens: number | null;

  @Column({ name: 'output_tokens', type: 'int', nullable: true })
  outputTokens: number | null;

  @Column({ name: 'latency_ms', type: 'int', nullable: true })
  latencyMs: number | null;
}
