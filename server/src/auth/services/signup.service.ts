import { randomUUID } from 'node:crypto';

import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, IsNull, Repository } from 'typeorm';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { AppUserRepository } from 'src/users/repositories/app-user.repository';
import { UserResponseDto } from 'src/users/dto/response/user-response.dto';
import { AuthVerificationSessionModel } from '../entities/auth-verification-session.entity';
import { ConsentDocumentModel } from '../entities/consent-document.entity';
import { UserConsentModel } from '../entities/user-consent.entity';
import { hashSecret } from '../const/auth.util';
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';
import { RefreshTokenModel } from '../entities/refresh-token.entity';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  REFRESH_TOKEN_TTL_SECONDS,
} from '../const/token.const';
import { OctomoService } from './octomo.service';
import { EntitlementService } from 'src/entitlement/services/entitlement.service';

@Injectable()
export class SignupService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly appUserRepository: AppUserRepository,
    private readonly refreshTokenRepository: RefreshTokenRepository,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly octomoService: OctomoService,
    private readonly entitlementService: EntitlementService,
    @InjectRepository(AuthVerificationSessionModel)
    private readonly sessionRepository: Repository<AuthVerificationSessionModel>,
    @InjectRepository(ConsentDocumentModel)
    private readonly consentDocumentRepository: Repository<ConsentDocumentModel>,
  ) {}

  /** api-spec §1.9 — 신규 계정 verify 응답용 약관 목록 */
  async listRequiredConsents(): Promise<
    {
      key: string;
      version: string;
      title: string;
      url: string | null;
      required: boolean;
    }[]
  > {
    const now = new Date();
    const docs = await this.consentDocumentRepository.find({
      order: { createdAt: 'ASC' },
    });
    return docs
      .filter((d) => d.effectiveAt <= now)
      .map((d) => ({
        key: d.consentKey,
        version: d.version,
        title: d.title,
        url: d.url || null,
        required: d.isRequired,
      }));
  }

  /** api-spec §1.10 — 한 트랜잭션에서 실행 */
  async signup(
    signupToken: string,
    name: string,
    consents: { key: string; version: string; agreed: boolean }[],
  ): Promise<{
    access_token: string;
    refresh_token: string;
    expires_in: number;
    needs_intro: boolean;
    user: UserResponseDto;
  }> {
    const sessionId = this.octomoService.resolveSignupToken(signupToken);
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
    });

    if (!session) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    const now = new Date();
    if (session.expiresAt <= now) {
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_EXPIRED);
    }

    if (!session.verifiedAt) {
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_NOT_COMPLETED);
    }

    if (session.consumedAt) {
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_EXPIRED);
    }

    const requiredDocs = await this.consentDocumentRepository.find({
      where: { isRequired: true },
    });
    const requiredKeys = new Set(requiredDocs.map((d) => d.consentKey));

    const consentedKeys = new Set(
      consents.filter((c) => c.agreed).map((c) => c.key),
    );

    for (const key of requiredKeys) {
      if (!consentedKeys.has(key)) {
        throw new ApiException(ERROR_CODE.AUTH.CONSENT_REQUIRED);
      }
    }

    const consentedEntries = consents.filter((c) => c.agreed);
    const consentKeys = consentedEntries.map((c) => c.key);
    const allDocs =
      consentKeys.length > 0
        ? await this.consentDocumentRepository
            .createQueryBuilder('cd')
            .where('cd.consent_key IN (:...keys)', { keys: consentKeys })
            .getMany()
        : [];

    const docByKey = new Map(allDocs.map((d) => [d.consentKey, d]));

    const existingUser = await this.appUserRepository.findByPhone(
      session.normalizedPhone,
    );
    if (existingUser) {
      // 이미 가입된 번호 — signup 경로가 아니라 login 경로를 써야 함
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_EXPIRED);
    }

    return await this.dataSource.transaction(async (entityManager) => {
      const user = entityManager.create(AppUserModel, {
        phone: session.normalizedPhone,
        name,
      });
      const savedUser = await entityManager.save(AppUserModel, user);

      for (const entry of consentedEntries) {
        const doc = docByKey.get(entry.key);
        if (!doc) continue;

        const userConsent = entityManager.create(UserConsentModel, {
          user: savedUser,
          consentDocument: doc,
          agreedAt: now,
          channel: 'app',
        });
        await entityManager.save(UserConsentModel, userConsent);
      }

      const updateResult = await entityManager.update(
        AuthVerificationSessionModel,
        { id: sessionId, consumedAt: IsNull() },
        { consumedAt: now },
      );
      if (updateResult.affected === 0) {
        throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_EXPIRED);
      }

      const accessToken = await this.jwtService.signAsync(
        { sub: savedUser.id },
        {
          secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
          expiresIn: ACCESS_TOKEN_TTL_SECONDS,
        },
      );

      const refreshToken = await this.jwtService.signAsync(
        { sub: savedUser.id, typ: 'refresh', jti: randomUUID() },
        {
          secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
          expiresIn: REFRESH_TOKEN_TTL_SECONDS,
        },
      );

      const refreshTokenEntity = entityManager.create(RefreshTokenModel, {
        user: savedUser,
        tokenHash: hashSecret(refreshToken),
        expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_SECONDS * 1000),
      });
      await entityManager.save(RefreshTokenModel, refreshTokenEntity);

      if (this.configService.get<string>('AUDIOBOOK_AUTO_GRANT') === 'true') {
        await this.entitlementService.grantAudiobookT1(
          savedUser.id,
          'signup_auto',
          entityManager,
        );
      }

      return {
        access_token: accessToken,
        refresh_token: refreshToken,
        expires_in: ACCESS_TOKEN_TTL_SECONDS,
        needs_intro: true,
        user: UserResponseDto.from(savedUser),
      };
    });
  }
}