import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { ShippingAddressModel } from 'src/users/entities/shipping-address.entity';
import { UserSettingModel } from 'src/users/entities/user-setting.entity';
import { SettingsController } from './settings.controller';
import { SettingsService } from './services/settings.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserSettingModel, ShippingAddressModel]),
    AuthGuardModule,
  ],
  controllers: [SettingsController],
  providers: [SettingsService],
})
export class SettingsModule {}
