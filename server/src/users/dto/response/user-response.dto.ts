import { ApiProperty } from '@nestjs/swagger';

import { AppUserModel } from 'src/users/entities/app-user.entity';

export class UserResponseDto {
  @ApiProperty({ example: 'a3f1…' })
  id: string;

  @ApiProperty({ example: '김영희', description: '가입 직후엔 빈 문자열' })
  name: string;

  @ApiProperty({
    example: 'user@kakao.com',
    nullable: true,
    description: '카카오 등에서 받은 이메일. 없으면 null',
  })
  email: string | null;

  @ApiProperty({ example: '01012345678', nullable: true })
  phone: string | null;

  @ApiProperty({ example: false })
  child_linked: boolean;

  @ApiProperty({
    example: 'kimyounghee',
    nullable: true,
    description: '아이디/비밀번호 로그인용 아이디. 없으면 null',
  })
  login_id: string | null;

  @ApiProperty({
    example: false,
    description: '아이디·비밀번호가 설정돼 있으면 true',
  })
  has_password: boolean;

  @ApiProperty({
    example: true,
    description: '프로필 사진이 있으면 true. 이미지는 GET /users/me/avatar',
  })
  has_avatar: boolean;

  static from(user: AppUserModel): UserResponseDto {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      child_linked: user.childLinked,
      login_id: user.loginId,
      has_password: Boolean(user.passwordHash),
      has_avatar: Boolean(user.avatarObjectKey),
    };
  }
}
