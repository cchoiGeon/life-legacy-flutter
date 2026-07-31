import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class KakaoLoginDto {
  @ApiProperty({ example: 'kakao-access-token' })
  @IsString()
  @MinLength(1)
  kakao_access_token: string;
}
