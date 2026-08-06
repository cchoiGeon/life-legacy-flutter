import { ApiProperty } from '@nestjs/swagger';

export class RedeemCouponResponseDto {
  @ApiProperty({ example: 'T1', description: '부여(또는 유지)된 플랜' })
  plan_code: string;

  @ApiProperty({ example: 'T1 플랜이 적용됐어요' })
  message: string;
}
