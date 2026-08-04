import { ApiProperty } from '@nestjs/swagger';

/**
 * api-spec §1.7 — 가입 여부와 무관하게 항상 같은 값을 준다.
 */
export class PhoneLookupResponseDto {
  @ApiProperty({ example: 'verify', description: '항상 "verify"' })
  next_step: string;
}
