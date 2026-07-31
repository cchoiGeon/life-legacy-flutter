import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/** 만료 건은 배치로 삭제한다 */
@Entity('phone_verification')
@Index('ix_phone_verification_lookup', ['phone', 'createdAt'])
export class PhoneVerificationModel extends BaseModel {
  @Column({ type: 'varchar', length: 11 })
  phone: string;

  /** 평문 저장 금지 */
  @Column({ name: 'code_hash', type: 'varchar', length: 255 })
  codeHash: string;

  /** API의 expires_in 계산 근거 */
  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  /** API의 resend_after 계산 근거 */
  @Column({ name: 'resend_available_at', type: 'timestamptz' })
  resendAvailableAt: Date;

  /** 5회를 넘기면 폐기한다 */
  @Column({ name: 'attempt_count', type: 'smallint', default: 0 })
  attemptCount: number;

  @Column({ name: 'consumed_at', type: 'timestamptz', nullable: true })
  consumedAt: Date | null;
}
