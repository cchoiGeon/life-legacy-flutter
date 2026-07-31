import { Injectable } from '@nestjs/common';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { UserResponseDto } from '../dto/response/user-response.dto';
import { AppUserModel } from '../entities/app-user.entity';
import { AppUserRepository } from '../repositories/app-user.repository';

@Injectable()
export class UsersService {
  constructor(private readonly appUserRepository: AppUserRepository) {}

  async getMe(userId: string): Promise<UserResponseDto> {
    const user = await this.getOrThrow(userId);

    return UserResponseDto.from(user);
  }

  /** 다른 도메인이 사용자를 집어 갈 때 쓰는 통로 */
  async getOrThrow(userId: string): Promise<AppUserModel> {
    const user = await this.appUserRepository.findById(userId);
    if (!user) {
      throw new ApiException(ERROR_CODE.AUTH.UNAUTHORIZED);
    }

    return user;
  }
}
