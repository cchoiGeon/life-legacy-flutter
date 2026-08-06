import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { EntitlementModule } from 'src/entitlement/entitlement.module';
import { AdminCouponController } from './admin-coupon.controller';
import { CouponController } from './coupon.controller';
import { CouponRedemptionModel } from './entities/coupon-redemption.entity';
import { CouponModel } from './entities/coupon.entity';
import { CouponService } from './services/coupon.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([CouponModel, CouponRedemptionModel]),
    AuthGuardModule,
    EntitlementModule,
  ],
  controllers: [CouponController, AdminCouponController],
  providers: [CouponService],
  exports: [CouponService],
})
export class CouponModule {}
