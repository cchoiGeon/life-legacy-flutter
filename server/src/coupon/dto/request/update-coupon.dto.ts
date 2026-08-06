import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

const PLAN_CODES = ['T1', 'T2', 'T3', 'T4'] as const;

/** 코드(code)는 변경하지 않는다 — 이미 배포된 쿠폰과 충돌한다. */
export class UpdateCouponDto {
  @ApiPropertyOptional({ example: 'T2', enum: PLAN_CODES })
  @IsOptional()
  @IsIn(PLAN_CODES)
  plan_code?: (typeof PLAN_CODES)[number];

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsInt()
  @Min(1)
  max_redemptions?: number | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsDateString()
  expires_at?: string | null;

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}
