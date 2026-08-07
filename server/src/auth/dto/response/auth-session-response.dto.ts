import { ApiProperty } from '@nestjs/swagger';

import { UserResponseDto } from 'src/users/dto/response/user-response.dto';

export class AuthSessionResponseDto {
  @ApiProperty({ example: 'eyJ…' })
  access_token: string;

  @ApiProperty({ example: 'rt_…' })
  refresh_token: string;

  @ApiProperty({ example: 3600 })
  expires_in: number;

  @ApiProperty({
    example: true,
    description:
      '자기소개·목차 확정을 아직 안 했으면 true. 앱 분기의 유일한 근거',
  })
  needs_intro: boolean;

  @ApiProperty({
    example: true,
    description:
      '필수 약관 동의가 user_consent에 없으면 true. 있으면 동의 화면을 건너뛴다',
  })
  needs_consents: boolean;

  @ApiProperty({
    example: true,
    description:
      '전화번호가 없으면 true. 카카오 가입 직후 전화 인증(연결)이 필요하다',
  })
  needs_phone: boolean;

  @ApiProperty({ type: UserResponseDto })
  user: UserResponseDto;
}
