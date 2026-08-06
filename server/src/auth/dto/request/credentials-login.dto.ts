import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class CredentialsLoginDto {
  @ApiProperty({ example: 'kimyounghee', description: '로그인 아이디' })
  @IsString()
  @MinLength(3)
  @MaxLength(50)
  login_id: string;

  @ApiProperty({ example: 'secret12', description: '비밀번호 (6자 이상)' })
  @IsString()
  @MinLength(6)
  @MaxLength(100)
  password: string;
}
