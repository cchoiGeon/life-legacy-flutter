import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsUUID } from 'class-validator';

export class OctomoVerifyDto {
  @ApiProperty({ example: 'avs_8f21', description: 'OCTOMO 인증 세션 ID' })
  @IsUUID()
  session_id: string;

  /** true면 로그인된 계정에 번호 연결용 — 다른 계정으로 세션 전환하지 않음 */
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  link?: boolean;
}
