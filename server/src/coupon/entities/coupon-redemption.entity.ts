import { Column, Entity, Index, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { CouponModel } from './coupon.entity';

/** 사용자·쿠폰당 1회 교환. */
@Entity('coupon_redemption')
@Unique('ux_coupon_redemption_user', ['couponId', 'userId'])
@Index('ix_coupon_redemption_user', ['userId'])
export class CouponRedemptionModel extends BaseModel {
  @ManyToOne(() => CouponModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'coupon_id' })
  coupon: CouponModel;

  @Column({ name: 'coupon_id', type: 'uuid' })
  couponId: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  /** 교환 당시 부여된 플랜 (쿠폰 plan_code 스냅샷) */
  @Column({ name: 'plan_code', type: 'varchar', length: 10 })
  planCode: string;

  @Column({
    name: 'redeemed_at',
    type: 'timestamptz',
    default: () => 'CURRENT_TIMESTAMP',
  })
  redeemedAt: Date;
}
