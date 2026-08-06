import { DataSource, Repository } from 'typeorm';

import { randomUUID } from 'node:crypto';

import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { firstValueFrom } from 'rxjs';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { AppUserRepository } from 'src/users/repositories/app-user.repository';
import { SocialAccountModel } from 'src/users/entities/social-account.entity';
import { UserResponseDto } from 'src/users/dto/response/user-response.dto';
import {
  generateVerificationCode,
  hashPassword,
  hashSecret,
  matchesPassword,
  matchesSecret,
} from '../const/auth.util';
import {
  ACCESS_TOKEN_TTL_SECONDS,
  REFRESH_TOKEN_TTL_SECONDS,
  VERIFICATION_MAX_ATTEMPTS,
  VERIFICATION_RESEND_AFTER_SECONDS,
  VERIFICATION_TTL_SECONDS,
} from '../const/token.const';
import { AuthSessionResponseDto } from '../dto/response/auth-session-response.dto';
import { AuthTokensResponseDto } from '../dto/response/auth-tokens-response.dto';
import { VerificationChallengeResponseDto } from '../dto/response/verification-challenge-response.dto';
import { PhoneVerificationRepository } from '../repositories/phone-verification.repository';
import { RefreshTokenRepository } from '../repositories/refresh-token.repository';
import { SmsService } from './sms.service';
import { OctomoService } from './octomo.service';
import { AuthVerificationSessionModel } from '../entities/auth-verification-session.entity';

const ISSUE_LIMIT_PER_HOUR = 5;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly appUserRepository: AppUserRepository,
    private readonly phoneVerificationRepository: PhoneVerificationRepository,
    private readonly refreshTokenRepository: RefreshTokenRepository,
    private readonly smsService: SmsService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly octomoService: OctomoService,
    private readonly httpService: HttpService,
    @InjectRepository(SocialAccountModel)
    private readonly socialAccountRepository: Repository<SocialAccountModel>,
  ) {}

  /** api-spec §1.1 */
  async requestVerificationCode(
    phone: string,
  ): Promise<VerificationChallengeResponseDto> {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const issuedLastHour =
      await this.phoneVerificationRepository.countIssuedSince(
        phone,
        oneHourAgo,
      );
    if (issuedLastHour >= ISSUE_LIMIT_PER_HOUR) {
      throw new ApiException(ERROR_CODE.COMMON.TOO_MANY_REQUESTS);
    }

    // 아직 재발송 대기 중이면 새로 만들지 않고 남은 시간만 알려 준다.
    // 여기서 새 번호를 발급하면 사용자가 방금 받은 문자가 무효가 된다.
    const pending =
      await this.phoneVerificationRepository.findLatestPending(phone);
    const now = new Date();
    if (pending && pending.resendAvailableAt > now && pending.expiresAt > now) {
      return {
        expires_in: secondsUntil(pending.expiresAt, now),
        resend_after: secondsUntil(pending.resendAvailableAt, now),
      };
    }

    const code = this.smsService.isStub
      ? this.smsService.stubCode
      : generateVerificationCode();

    await this.phoneVerificationRepository.create({
      phone,
      codeHash: hashSecret(code),
      expiresAt: new Date(now.getTime() + VERIFICATION_TTL_SECONDS * 1000),
      resendAvailableAt: new Date(
        now.getTime() + VERIFICATION_RESEND_AFTER_SECONDS * 1000,
      ),
    });
    await this.smsService.sendVerificationCode(phone, code);

    return {
      expires_in: VERIFICATION_TTL_SECONDS,
      resend_after: VERIFICATION_RESEND_AFTER_SECONDS,
    };
  }

  /**
   * api-spec §1.2 — 가입과 로그인을 구분하지 않는다.
   * 없는 번호면 그 자리에서 계정을 만들고 needs_intro: true로 돌려준다.
   */
  async verifyCode(
    phone: string,
    code: string,
  ): Promise<AuthSessionResponseDto> {
    const verification =
      await this.phoneVerificationRepository.findLatestPending(phone);
    if (!verification) {
      throw new ApiException(ERROR_CODE.AUTH.INVALID_CODE);
    }

    const now = new Date();
    if (verification.expiresAt <= now) {
      throw new ApiException(ERROR_CODE.AUTH.CODE_EXPIRED);
    }

    if (!matchesSecret(code, verification.codeHash)) {
      verification.attemptCount += 1;
      // 무차별 대입을 막는다. 한도를 넘기면 이 번호는 죽고 다시 받아야 한다.
      if (verification.attemptCount >= VERIFICATION_MAX_ATTEMPTS) {
        verification.consumedAt = now;
      }
      await this.phoneVerificationRepository.save(verification);

      throw new ApiException(ERROR_CODE.AUTH.INVALID_CODE);
    }

    verification.consumedAt = now;
    await this.phoneVerificationRepository.save(verification);

    const existing = await this.appUserRepository.findByPhone(phone);
    const user = existing ?? (await this.appUserRepository.create(phone));

    return await this.issueSession(user);
  }

  /**
   * api-spec §1.3.
   *
   * `KAKAO_PROVIDER=stub`(기본, 로컬 개발용)이면 토큰을 검증하지 않고
   * 그 자리에서 새 계정을 만든다.
   *
   * 그 외 값이면 카카오 액세스 토큰으로 `kapi.kakao.com/v2/user/me`를 불러
   * 카카오 사용자 ID를 얻는다 — 토큰 자체가 카카오 서버에서 검증되므로
   * 서버는 별도 앱 키 없이 `Authorization: Bearer {token}`만 실어 보낸다.
   * `social_account(provider='kakao')`로 기존 계정을 찾거나, 없으면
   * 전화번호 없는 계정을 새로 만들고 연결한다.
   */
  async loginWithKakao(
    kakaoAccessToken: string,
  ): Promise<AuthSessionResponseDto> {
    const provider = this.configService.get<string>('KAKAO_PROVIDER', 'stub');
    if (provider === 'stub') {
      const user = await this.appUserRepository.create(null);
      return await this.issueSession(user);
    }

    const kakaoUserId = await this.fetchKakaoUserId(kakaoAccessToken);

    const existingLink = await this.socialAccountRepository.findOne({
      where: { provider: 'kakao', providerUserId: kakaoUserId },
      relations: { user: true },
    });
    if (existingLink) {
      return await this.issueSession(existingLink.user);
    }

    const user = await this.appUserRepository.create(null);
    await this.socialAccountRepository.save(
      this.socialAccountRepository.create({
        user,
        provider: 'kakao',
        providerUserId: kakaoUserId,
      }),
    );

    return await this.issueSession(user);
  }

  /** 카카오 액세스 토큰 → 카카오 사용자 ID(문자열). 토큰 검증은 카카오 서버가 한다 */
  private async fetchKakaoUserId(accessToken: string): Promise<string> {
    try {
      const { data } = await firstValueFrom(
        this.httpService.get<{ id?: number }>(
          'https://kapi.kakao.com/v2/user/me',
          {
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
            },
            timeout: 10_000,
          },
        ),
      );

      if (data.id === undefined || data.id === null) {
        throw new Error('카카오 응답에 사용자 ID가 없습니다');
      }
      return String(data.id);
    } catch (err) {
      this.logger.warn(`카카오 사용자 조회 실패: ${(err as Error).message}`);
      throw new ApiException(ERROR_CODE.AUTH.KAKAO_LOGIN_FAILED);
    }
  }

  /** api-spec §1.4 — 리프레시 토큰도 함께 회전시킨다 */
  async refresh(refreshToken: string): Promise<AuthTokensResponseDto> {
    const stored = await this.refreshTokenRepository.findLiveByHash(
      hashSecret(refreshToken),
    );
    if (!stored || stored.expiresAt <= new Date()) {
      throw new ApiException(ERROR_CODE.AUTH.UNAUTHORIZED);
    }

    // 한 번 쓴 리프레시 토큰이 계속 유효하면, 새어 나갔을 때 만료를
    // 기다리는 수밖에 없다.
    await this.refreshTokenRepository.revoke(stored);

    const tokens = await this.issueTokens(stored.user);
    return tokens;
  }

  async logout(userId: string): Promise<void> {
    await this.refreshTokenRepository.revokeAllByUser(userId);
  }

  /**
   * api-spec §1.9 — OCTOMO 인증 완료 후 기존 사용자면 세션을 발급한다.
   * 신규 사용자면 null을 반환한다.
   */
  /** 아이디·비밀번호 로그인 (웹에서 가입했거나 설정에서 만든 계정) */
  async loginWithCredentials(
    loginId: string,
    password: string,
  ): Promise<AuthSessionResponseDto> {
    const user = await this.appUserRepository.findByLoginId(loginId.trim());
    if (!user?.passwordHash) {
      throw new ApiException(ERROR_CODE.AUTH.INVALID_CREDENTIALS);
    }

    const ok = await matchesPassword(password, user.passwordHash);
    if (!ok) {
      throw new ApiException(ERROR_CODE.AUTH.INVALID_CREDENTIALS);
    }

    return await this.issueSession(user);
  }

  /**
   * 카카오/전화 사용자가 설정에서 아이디·비밀번호를 처음 만든다.
   * 이미 있으면 거부한다.
   */
  async setCredentials(
    userId: string,
    loginId: string,
    password: string,
  ): Promise<UserResponseDto> {
    const user = await this.appUserRepository.findById(userId);
    if (!user) {
      throw new ApiException(ERROR_CODE.AUTH.UNAUTHORIZED);
    }
    if (user.passwordHash || user.loginId) {
      throw new ApiException(ERROR_CODE.AUTH.CREDENTIALS_ALREADY_SET);
    }

    const normalized = loginId.trim();
    const taken = await this.appUserRepository.findByLoginId(normalized);
    if (taken) {
      throw new ApiException(ERROR_CODE.AUTH.LOGIN_ID_TAKEN);
    }

    user.loginId = normalized;
    user.passwordHash = await hashPassword(password);
    await this.appUserRepository.save(user);

    return UserResponseDto.from(user);
  }

  async loginViaOctomo(
    sessionId: string,
  ): Promise<{
    access_token: string;
    refresh_token: string;
    expires_in: number;
    needs_intro: boolean;
    user: UserResponseDto;
  } | null> {
    const session = await this.dataSource
      .getRepository(AuthVerificationSessionModel)
      .findOne({ where: { id: sessionId } });

    if (!session) return null;

    const existing = await this.appUserRepository.findByPhone(session.normalizedPhone);
    if (!existing) return null;

    await this.octomoService.consumeSession(sessionId);

    return await this.issueSession(existing);
  }

  private async issueSession(
    user: AppUserModel,
  ): Promise<AuthSessionResponseDto> {
    user.lastLoginAt = new Date();
    await this.appUserRepository.save(user);

    const tokens = await this.issueTokens(user);

    return {
      ...tokens,
      // 목차 확정까지 끝내야 false가 된다. 앱 분기의 유일한 근거다.
      needs_intro: user.introCompletedAt === null,
      user: UserResponseDto.from(user),
    };
  }

  private async issueTokens(
    user: AppUserModel,
  ): Promise<AuthTokensResponseDto> {
    const accessToken = await this.jwtService.signAsync(
      { sub: user.id },
      {
        secret: this.configService.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      },
    );

    // ⚠️ jti가 없으면 같은 초에 두 번 발급했을 때 payload(sub·iat·exp)가
    //    완전히 같아 **토큰 문자열까지 동일**해진다. token_hash 유니크에
    //    걸려 갱신이 500으로 죽는다.
    const refreshToken = await this.jwtService.signAsync(
      { sub: user.id, typ: 'refresh', jti: randomUUID() },
      {
        secret: this.configService.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: REFRESH_TOKEN_TTL_SECONDS,
      },
    );

    await this.refreshTokenRepository.issue(
      user,
      hashSecret(refreshToken),
      new Date(Date.now() + REFRESH_TOKEN_TTL_SECONDS * 1000),
    );

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      expires_in: ACCESS_TOKEN_TTL_SECONDS,
    };
  }
}

function secondsUntil(target: Date, now: Date): number {
  return Math.max(0, Math.ceil((target.getTime() - now.getTime()) / 1000));
}
