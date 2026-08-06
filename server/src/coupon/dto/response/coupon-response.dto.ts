import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { CouponModel } from '../../entities/coupon.entity';

export class CouponResponseDto {
  @ApiProperty()
  id: string;

  @ApiProperty({ example: 'WELCOME-T1' })
  code: string;

  @ApiProperty({ example: 'T1' })
  plan_code: string;

  @ApiPropertyOptional({ nullable: true, example: 100 })
  max_redemptions: number | null;

  @ApiProperty({ example: 3 })
  redemption_count: number;

  @ApiPropertyOptional({ nullable: true })
  expires_at: string | null;

  @ApiPropertyOptional({ nullable: true })
  note: string | null;

  @ApiProperty()
  is_active: boolean;

  @ApiProperty()
  created_at: string;

  @ApiProperty()
  updated_at: string;

  static from(row: CouponModel): CouponResponseDto {
    return {
      id: row.id,
      code: row.code,
      plan_code: row.planCode,
      max_redemptions: row.maxRedemptions,
      redemption_count: row.redemptionCount,
      expires_at: row.expiresAt?.toISOString() ?? null,
      note: row.note,
      is_active: row.isActive,
      created_at: row.createdAt.toISOString(),
      updated_at: row.updatedAt.toISOString(),
    };
  }
}
