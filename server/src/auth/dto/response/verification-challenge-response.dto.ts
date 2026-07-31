import { ApiProperty } from '@nestjs/swagger';

/**
 * api-spec §1.1.
 *
 * 두 시간을 **따로** 준다 — 만료와 재발송 대기는 다른 값이다.
 */
export class VerificationChallengeResponseDto {
  @ApiProperty({ example: 180, description: '인증번호 유효 초' })
  expires_in: number;

  @ApiProperty({ example: 30, description: '"다시 받기"가 열리기까지 대기 초' })
  resend_after: number;
}
