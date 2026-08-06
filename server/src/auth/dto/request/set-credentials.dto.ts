import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

/**
 * 카카오/전화로 가입한 사용자가 설정에서 아이디·비밀번호를 처음 만들 때.
 * 이미 credentials가 있으면 거부한다(변경은 별도 API).
 */
export class SetCredentialsDto {
  @ApiProperty({
    example: 'kimyounghee',
    description: '영문·숫자·._- 3~50자',
  })
  @IsString()
  @MinLength(3)
  @MaxLength(50)
  @Matches(/^[a-zA-Z0-9._-]+$/, {
    message: '아이디는 영문·숫자·._-만 사용할 수 있어요',
  })
  login_id: string;

  @ApiProperty({ example: 'secret12', description: '비밀번호 (6자 이상)' })
  @IsString()
  @MinLength(6)
  @MaxLength(100)
  password: string;
}
