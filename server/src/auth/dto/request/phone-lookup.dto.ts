import { ApiProperty } from '@nestjs/swagger';
import { Matches } from 'class-validator';

export class PhoneLookupDto {
  @ApiProperty({ example: '01012345678', description: '숫자만 11자리' })
  @Matches(/^\d{11}$/, { message: '전화번호는 숫자 11자리입니다' })
  phone: string;
}
