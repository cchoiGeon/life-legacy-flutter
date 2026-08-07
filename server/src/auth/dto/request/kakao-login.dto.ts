import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class KakaoLoginDto {
  @ApiProperty({ example: 'kakao-access-token' })
  @IsString()
  @MinLength(1)
  kakao_access_token: string;

  /** 카카오 SDK `me()` 닉네임. 없으면 빈 이름으로 가입 */
  @ApiPropertyOptional({ example: '홍길동' })
  @IsOptional()
  @IsString()
  name?: string;

  /** 카카오 계정 이메일(동의 시에만). 없으면 null */
  @ApiPropertyOptional({ example: 'user@kakao.com' })
  @IsOptional()
  @IsEmail()
  email?: string;
}
