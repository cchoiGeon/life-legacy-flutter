import { ApiProperty } from '@nestjs/swagger';

export class OctomoChallengeResponseDto {
  @ApiProperty({ example: 'uuid', description: '인증 세션 ID' })
  session_id: string;

  @ApiProperty({ example: '0503xxxxxxx', description: '사용자가 문자를 보낼 수신번호' })
  receiver_number: string;

  @ApiProperty({ example: '3538', description: '보낼 문자 원문' })
  verify_text: string;

  @ApiProperty({ example: 300, description: '세션 유효 초' })
  expires_in: number;

  @ApiProperty({ example: 3, description: '폴링 권장 간격(초)' })
  poll_interval: number;
}
