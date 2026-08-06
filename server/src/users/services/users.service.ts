import {
  createReadStream,
  existsSync,
  mkdirSync,
  unlinkSync,
  writeFileSync,
} from 'node:fs';
import { join } from 'node:path';

import { Injectable, StreamableFile } from '@nestjs/common';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { UserResponseDto } from '../dto/response/user-response.dto';
import { AppUserModel } from '../entities/app-user.entity';
import { AppUserRepository } from '../repositories/app-user.repository';

const AVATAR_MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED_MIME = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
]);

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

  async uploadAvatar(
    userId: string,
    file: Express.Multer.File,
  ): Promise<UserResponseDto> {
    if (!file?.buffer?.length) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    if (file.size > AVATAR_MAX_BYTES) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }
    const mime = (file.mimetype || '').toLowerCase();
    if (!ALLOWED_MIME.has(mime)) {
      throw new ApiException(ERROR_CODE.COMMON.INVALID_REQUEST);
    }

    const user = await this.getOrThrow(userId);
    const ext = mime.includes('png')
      ? 'png'
      : mime.includes('webp')
        ? 'webp'
        : 'jpg';

    const dir = join(process.cwd(), 'storage', 'avatars');
    mkdirSync(dir, { recursive: true });

    const relativeKey = join('storage', 'avatars', `${userId}.${ext}`);
    const absolute = join(process.cwd(), relativeKey);

    if (user.avatarObjectKey) {
      const prev = join(process.cwd(), user.avatarObjectKey);
      if (existsSync(prev) && prev !== absolute) {
        try {
          unlinkSync(prev);
        } catch {
          // 이전 파일 삭제 실패는 업로드를 막지 않는다
        }
      }
    }

    writeFileSync(absolute, file.buffer);
    user.avatarObjectKey = relativeKey;
    await this.appUserRepository.save(user);

    return UserResponseDto.from(user);
  }

  async getAvatarStream(userId: string): Promise<{
    file: StreamableFile;
    contentType: string;
  }> {
    const user = await this.getOrThrow(userId);
    if (!user.avatarObjectKey) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const absolute = join(process.cwd(), user.avatarObjectKey);
    if (!existsSync(absolute)) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const lower = user.avatarObjectKey.toLowerCase();
    const contentType = lower.endsWith('.png')
      ? 'image/png'
      : lower.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';

    return {
      file: new StreamableFile(createReadStream(absolute)),
      contentType,
    };
  }
}
