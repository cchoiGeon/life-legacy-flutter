import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';

import { AppUserModel } from '../entities/app-user.entity';

@Injectable()
export class AppUserRepository {
  constructor(
    @InjectRepository(AppUserModel)
    private readonly repository: Repository<AppUserModel>,
  ) {}

  async findById(id: string): Promise<AppUserModel | null> {
    return await this.repository.findOne({
      where: { id, deletedAt: IsNull() },
    });
  }

  async findByPhone(phone: string): Promise<AppUserModel | null> {
    return await this.repository.findOne({
      where: { phone, deletedAt: IsNull() },
    });
  }

  async findByLoginId(loginId: string): Promise<AppUserModel | null> {
    return await this.repository.findOne({
      where: { loginId, deletedAt: IsNull() },
    });
  }

  async create(
    phone: string | null,
    opts?: { name?: string; email?: string | null },
  ): Promise<AppUserModel> {
    return await this.repository.save(
      this.repository.create({
        phone,
        name: opts?.name?.trim() ?? '',
        email: opts?.email?.trim() || null,
      }),
    );
  }

  async save(user: AppUserModel): Promise<AppUserModel> {
    return await this.repository.save(user);
  }
}
