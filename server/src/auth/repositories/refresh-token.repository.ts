import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';
import { RefreshTokenModel } from '../entities/refresh-token.entity';

@Injectable()
export class RefreshTokenRepository {
  constructor(
    @InjectRepository(RefreshTokenModel)
    private readonly repository: Repository<RefreshTokenModel>,
  ) {}

  async findLiveByHash(tokenHash: string): Promise<RefreshTokenModel | null> {
    return await this.repository.findOne({
      where: { tokenHash, revokedAt: IsNull() },
      relations: { user: true },
    });
  }

  async issue(
    user: AppUserModel,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<RefreshTokenModel> {
    return await this.repository.save(
      this.repository.create({ user, tokenHash, expiresAt }),
    );
  }

  async revoke(token: RefreshTokenModel): Promise<void> {
    token.revokedAt = new Date();
    await this.repository.save(token);
  }

  /** 로그아웃 — 그 사용자의 살아 있는 토큰을 전부 폐기한다 */
  async revokeAllByUser(userId: string): Promise<void> {
    await this.repository.update(
      { user: { id: userId }, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }
}
