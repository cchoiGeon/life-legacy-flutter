import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

import { AccessTokenGuard } from 'src/auth/guard/access-token.guard';
import { CreateCouponDto } from './dto/request/create-coupon.dto';
import { UpdateCouponDto } from './dto/request/update-coupon.dto';
import { CouponResponseDto } from './dto/response/coupon-response.dto';
import { CouponService } from './services/coupon.service';

/**
 * 쿠폰 발급·관리. 웹 admin 연동 예정.
 * 지금은 AccessTokenGuard만 건다 — 관리자 역할 가드는 추후 추가.
 */
@ApiTags('Admin Coupons API')
@ApiBearerAuth('access-token')
@UseGuards(AccessTokenGuard)
@Controller('admin/coupons')
export class AdminCouponController {
  constructor(private readonly coupons: CouponService) {}

  @ApiOperation({ summary: '쿠폰 발급' })
  @ApiResponse({ status: 201, type: CouponResponseDto })
  @Post()
  async create(@Body() dto: CreateCouponDto) {
    return this.coupons.create(dto);
  }

  @ApiOperation({ summary: '쿠폰 목록' })
  @ApiResponse({ status: 200, type: CouponResponseDto, isArray: true })
  @Get()
  async list() {
    return { items: await this.coupons.list() };
  }

  @ApiOperation({ summary: '쿠폰 상세' })
  @ApiResponse({ status: 200, type: CouponResponseDto })
  @Get(':id')
  async get(@Param('id', ParseUUIDPipe) id: string) {
    return this.coupons.get(id);
  }

  @ApiOperation({ summary: '쿠폰 수정' })
  @ApiResponse({ status: 200, type: CouponResponseDto })
  @Patch(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCouponDto,
  ) {
    return this.coupons.update(id, dto);
  }

  @ApiOperation({ summary: '쿠폰 비활성' })
  @ApiResponse({ status: 200, type: CouponResponseDto })
  @Delete(':id')
  async deactivate(@Param('id', ParseUUIDPipe) id: string) {
    return this.coupons.deactivate(id);
  }
}
