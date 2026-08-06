import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { UserId } from 'src/auth/decorator/user.decorator';
import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { RedeemCouponDto } from './dto/request/redeem-coupon.dto';
import { RedeemCouponResponseDto } from './dto/response/redeem-coupon-response.dto';
import { CouponService } from './services/coupon.service';

@ApiTags('Coupons API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('coupons')
export class CouponController {
  constructor(private readonly coupons: CouponService) {}

  @ApiOperation({ summary: '쿠폰 코드 교환 → T1~T4 플랜 부여' })
  @ApiResponse({ status: 200, type: RedeemCouponResponseDto })
  @HttpCode(200)
  @Post('redeem')
  async redeem(@UserId() userId: string, @Body() dto: RedeemCouponDto) {
    return this.coupons.redeem(userId, dto.code);
  }
}
