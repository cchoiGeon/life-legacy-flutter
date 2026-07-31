import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({ example: 'rt_...' })
  @IsString()
  @MinLength(1)
  refresh_token: string;
}
