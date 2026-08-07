import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';
import { DevicePushTokenModel } from 'src/users/entities/device-push-token.entity';
import { RegisterDevicePushTokenDto } from '../dto/request/register-device-push-token.dto';

@Injectable()
export class DevicePushTokensService {
  constructor(
    @InjectRepository(DevicePushTokenModel)
    private readonly tokens: Repository<DevicePushTokenModel>,
  ) {}

  /**
   * 같은 토큰이 이미 있으면 소유자·플랫폼·last_used_at만 갱신한다(upsert).
   * 다른 사용자 기기에서 재로그인한 경우도 토큰을 이 사용자로 옮긴다.
   */
  async register(
    userId: string,
    dto: RegisterDevicePushTokenDto,
  ): Promise<void> {
    const now = new Date();
    const existing = await this.tokens.findOne({
      where: { token: dto.token },
      relations: { user: true },
    });

    if (existing) {
      existing.user = { id: userId } as AppUserModel;
      existing.platform = dto.platform;
      existing.lastUsedAt = now;
      existing.revokedAt = null;
      await this.tokens.save(existing);
      return;
    }

    await this.tokens.save(
      this.tokens.create({
        user: { id: userId } as AppUserModel,
        platform: dto.platform,
        token: dto.token,
        lastUsedAt: now,
        revokedAt: null,
      }),
    );
  }

  async revoke(userId: string, token: string): Promise<void> {
    const row = await this.tokens.findOne({
      where: { token, user: { id: userId } },
    });
    if (!row || row.revokedAt) return;

    row.revokedAt = new Date();
    await this.tokens.save(row);
  }

  async revokeAllByUser(userId: string): Promise<void> {
    await this.tokens.update(
      { user: { id: userId }, revokedAt: IsNull() },
      { revokedAt: new Date() },
    );
  }

  async listActiveForUser(userId: string): Promise<DevicePushTokenModel[]> {
    return await this.tokens.find({
      where: { user: { id: userId }, revokedAt: IsNull() },
    });
  }

  async markUsed(tokenIds: string[]): Promise<void> {
    if (tokenIds.length === 0) return;
    await this.tokens.update(tokenIds, { lastUsedAt: new Date() });
  }

  async revokeByTokenValues(tokenValues: string[]): Promise<void> {
    if (tokenValues.length === 0) return;
    await this.tokens.update(
      { token: In(tokenValues) },
      { revokedAt: new Date() },
    );
  }
}
