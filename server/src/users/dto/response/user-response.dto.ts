import { ApiProperty } from '@nestjs/swagger';

import { AppUserModel } from 'src/users/entities/app-user.entity';

export class UserResponseDto {
  @ApiProperty({ example: 'a3f1…' })
  id: string;

  @ApiProperty({ example: '김영희', description: '가입 직후엔 빈 문자열' })
  name: string;

  @ApiProperty({ example: '01012345678', nullable: true })
  phone: string | null;

  @ApiProperty({ example: false })
  child_linked: boolean;

  static from(user: AppUserModel): UserResponseDto {
    return {
      id: user.id,
      name: user.name,
      phone: user.phone,
      child_linked: user.childLinked,
    };
  }
}
