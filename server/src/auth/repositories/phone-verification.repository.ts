import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';

import { PhoneVerificationModel } from '../entities/phone-verification.entity';

@Injectable()
export class PhoneVerificationRepository {
  constructor(
    @InjectRepository(PhoneVerificationModel)
    private readonly repository: Repository<PhoneVerificationModel>,
  ) {}

  /** 가장 최근에 발급한, 아직 쓰지 않은 인증번호 */
  async findLatestPending(phone: string): Promise<PhoneVerificationModel | null> {
    return await this.repository.findOne({
      where: { phone, consumedAt: IsNull() },
      order: { createdAt: 'DESC' },
    });
  }

  /** 최근 한 시간 발급 횟수 — api-spec §0.5의 전화번호당 5회 제한 */
  async countIssuedSince(phone: string, since: Date): Promise<number> {
    return await this.repository
      .createQueryBuilder('v')
      .where('v.phone = :phone', { phone })
      .andWhere('v.created_at >= :since', { since })
      .getCount();
  }

  async create(
    input: Pick<
      PhoneVerificationModel,
      'phone' | 'codeHash' | 'expiresAt' | 'resendAvailableAt'
    >,
  ): Promise<PhoneVerificationModel> {
    return await this.repository.save(this.repository.create(input));
  }

  async save(
    verification: PhoneVerificationModel,
  ): Promise<PhoneVerificationModel> {
    return await this.repository.save(verification);
  }
}
