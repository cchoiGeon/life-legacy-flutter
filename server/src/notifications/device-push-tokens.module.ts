import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AuthGuardModule } from 'src/auth/auth-guard.module';
import { DevicePushTokenModel } from 'src/users/entities/device-push-token.entity';
import { DevicePushTokensController } from './device-push-tokens.controller';
import { DevicePushTokensService } from './services/device-push-tokens.service';

/** 토큰 등록/폐기만 — Auth 로그아웃과 발송 모듈이 공유 */
@Module({
  imports: [
    TypeOrmModule.forFeature([DevicePushTokenModel]),
    AuthGuardModule,
  ],
  controllers: [DevicePushTokensController],
  providers: [DevicePushTokensService],
  exports: [DevicePushTokensService],
})
export class DevicePushTokensModule {}
