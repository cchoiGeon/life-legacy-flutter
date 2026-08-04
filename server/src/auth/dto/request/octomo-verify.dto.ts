import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class OctomoVerifyDto {
  @ApiProperty({ example: 'avs_8f21', description: 'OCTOMO 인증 세션 ID' })
  @IsUUID()
  session_id: string;
}
