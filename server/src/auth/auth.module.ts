import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HttpModule } from '@nestjs/axios';

import { UsersModule } from 'src/users/users.module';
import { EntitlementModule } from 'src/entitlement/entitlement.module';
import { SocialAccountModel } from 'src/users/entities/social-account.entity';
import { AuthGuardModule } from './auth-guard.module';
import { AuthController, ConsentsController } from './auth.controller';
import { PhoneVerificationModel } from './entities/phone-verification.entity';
import { RefreshTokenModel } from './entities/refresh-token.entity';
import { AuthVerificationSessionModel } from './entities/auth-verification-session.entity';
import { ConsentDocumentModel } from './entities/consent-document.entity';
import { UserConsentModel } from './entities/user-consent.entity';
import { PhoneVerificationRepository } from './repositories/phone-verification.repository';
import { RefreshTokenRepository } from './repositories/refresh-token.repository';
import { AuthService } from './services/auth.service';
import { SmsService } from './services/sms.service';
import { OctomoService } from './services/octomo.service';
import { SignupService } from './services/signup.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PhoneVerificationModel,
      RefreshTokenModel,
      AuthVerificationSessionModel,
      ConsentDocumentModel,
      UserConsentModel,
      SocialAccountModel,
    ]),
    HttpModule,
    JwtModule.register({}),
    AuthGuardModule,
    UsersModule,
    EntitlementModule,
  ],
  controllers: [AuthController, ConsentsController],
  providers: [
    AuthService,
    SmsService,
    PhoneVerificationRepository,
    RefreshTokenRepository,
    OctomoService,
    SignupService,
  ],
  exports: [AuthService, OctomoService, SignupService],
})
export class AuthModule {}
