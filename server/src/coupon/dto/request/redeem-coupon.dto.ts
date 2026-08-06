import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class RedeemCouponDto {
  @ApiProperty({ example: 'WELCOME-T1' })
  @IsString()
  @MinLength(4)
  @MaxLength(40)
  @Matches(/^[A-Za-z0-9_-]+$/, {
    message: '쿠폰 코드 형식이 올바르지 않아요',
  })
  code: string;
}
