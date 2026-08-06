import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

const PLAN_CODES = ['T1', 'T2', 'T3', 'T4'] as const;

export class CreateCouponDto {
  @ApiProperty({ example: 'WELCOME-T1', description: '교환 코드 (대소문자 무시)' })
  @IsString()
  @MinLength(4)
  @MaxLength(40)
  @Matches(/^[A-Za-z0-9_-]+$/, {
    message: '영문·숫자·_-만 사용할 수 있어요',
  })
  code: string;

  @ApiProperty({ example: 'T1', enum: PLAN_CODES })
  @IsIn(PLAN_CODES)
  plan_code: (typeof PLAN_CODES)[number];

  @ApiPropertyOptional({
    example: 100,
    description: '최대 교환 횟수. 없으면 무제한',
    nullable: true,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  max_redemptions?: number | null;

  @ApiPropertyOptional({
    example: '2026-12-31T23:59:59.000Z',
    nullable: true,
  })
  @IsOptional()
  @IsDateString()
  expires_at?: string | null;

  @ApiPropertyOptional({ example: '사전신청 100명', nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string | null;

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  @IsBoolean()
  is_active?: boolean;
}
