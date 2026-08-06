import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/** 관리자가 발급하는 플랜 쿠폰. 코드 1개 = T1~T4 중 하나. */
@Entity('coupon')
export class CouponModel extends BaseModel {
  /** 교환 시 대소문자 무시. 저장 시 대문자로 정규화한다. */
  @Index('ux_coupon_code', { unique: true })
  @Column({ type: 'varchar', length: 40 })
  code: string;

  /** T1 | T2 | T3 | T4 */
  @Column({ name: 'plan_code', type: 'varchar', length: 10 })
  planCode: string;

  /** null이면 횟수 제한 없음 */
  @Column({ name: 'max_redemptions', type: 'int', nullable: true })
  maxRedemptions: number | null;

  @Column({ name: 'redemption_count', type: 'int', default: 0 })
  redemptionCount: number;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;
}
