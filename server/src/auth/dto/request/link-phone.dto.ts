import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

/** 카카오 등 phone 없는 계정에 OCTOMO 인증 세션으로 번호 연결 */
export class LinkPhoneDto {
  @ApiProperty({ example: 'session-uuid' })
  @IsString()
  @MinLength(1)
  session_id: string;
}
