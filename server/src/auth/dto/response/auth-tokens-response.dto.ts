import { ApiProperty } from '@nestjs/swagger';

export class AuthTokensResponseDto {
  @ApiProperty({ example: 'eyJ…' })
  access_token: string;

  @ApiProperty({ example: 'rt_…' })
  refresh_token: string;

  @ApiProperty({ example: 3600 })
  expires_in: number;
}
