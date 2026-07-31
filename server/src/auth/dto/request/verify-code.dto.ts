import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class VerifyCodeDto {
  @ApiProperty({ example: '01012345678' })
  @Matches(/^\d{11}$/, { message: '전화번호는 숫자 11자리입니다' })
  phone: string;

  @ApiProperty({ example: '482915', description: '숫자 6자리' })
  @Matches(/^\d{6}$/, { message: '인증번호는 숫자 6자리입니다' })
  code: string;
}
