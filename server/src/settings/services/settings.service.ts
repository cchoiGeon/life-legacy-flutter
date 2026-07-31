import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { ShippingAddressModel } from 'src/users/entities/shipping-address.entity';
import { UserSettingModel } from 'src/users/entities/user-setting.entity';
import { AppSettingsDto, ShippingAddressDto } from '../dto/settings.dto';

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(UserSettingModel)
    private readonly settings: Repository<UserSettingModel>,
    @InjectRepository(ShippingAddressModel)
    private readonly addresses: Repository<ShippingAddressModel>,
  ) {}

  async getSettings(userId: string): Promise<AppSettingsDto> {
    const setting = await this.settings.findOne({ where: { userId } });

    // 없으면 기본값을 돌려준다. 앱이 "없음"과 "못 불러옴"을 구분할 필요가 없다.
    return { daily_question_alarm: setting?.dailyQuestionAlarm ?? true };
  }

  async updateSettings(
    userId: string,
    dto: AppSettingsDto,
  ): Promise<AppSettingsDto> {
    await this.settings.upsert(
      { userId, dailyQuestionAlarm: dto.daily_question_alarm },
      ['userId'],
    );

    return { daily_question_alarm: dto.daily_question_alarm };
  }

  /**
   * 등록 전에도 404가 아니라 빈 문자열이 채워진 객체를 돌려준다 —
   * 앱이 "없음"과 "못 불러옴"을 구분할 필요가 없다.
   */
  async getAddress(userId: string): Promise<ShippingAddressDto> {
    const address = await this.addresses.findOne({ where: { userId } });

    return {
      recipient: address?.recipient ?? '',
      phone: address?.phone ?? '',
      postal_code: address?.postalCode ?? '',
      line1: address?.line1 ?? '',
      line2: address?.line2 ?? '',
    };
  }

  async updateAddress(
    userId: string,
    dto: ShippingAddressDto,
  ): Promise<ShippingAddressDto> {
    await this.addresses.upsert(
      {
        userId,
        recipient: dto.recipient,
        phone: dto.phone,
        postalCode: dto.postal_code,
        line1: dto.line1,
        line2: dto.line2,
      },
      ['userId'],
    );

    return dto;
  }
}
