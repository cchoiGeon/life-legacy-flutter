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
    description: '자기소개·목차 확정을 아직 안 했으면 true. 앱 분기의 유일한 근거',
  })
  needs_intro: boolean;

  @ApiProperty({ type: UserResponseDto })
  user: UserResponseDto;
}
