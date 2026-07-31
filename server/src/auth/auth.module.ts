import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';

import { UsersModule } from 'src/users/users.module';
import { AuthGuardModule } from './auth-guard.module';
import { AuthController } from './auth.controller';
import { PhoneVerificationModel } from './entities/phone-verification.entity';
import { RefreshTokenModel } from './entities/refresh-token.entity';
import { PhoneVerificationRepository } from './repositories/phone-verification.repository';
import { RefreshTokenRepository } from './repositories/refresh-token.repository';
import { AuthService } from './services/auth.service';
import { SmsService } from './services/sms.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([PhoneVerificationModel, RefreshTokenModel]),
    JwtModule.register({}),
    AuthGuardModule,
    UsersModule,
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    SmsService,
    PhoneVerificationRepository,
    RefreshTokenRepository,
  ],
  exports: [AuthService],
})
export class AuthModule {}
