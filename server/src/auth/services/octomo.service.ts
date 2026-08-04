import { randomInt } from 'node:crypto';

import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { firstValueFrom } from 'rxjs';
import { IsNull, MoreThanOrEqual, Repository } from 'typeorm';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { AuthVerificationSessionModel } from '../entities/auth-verification-session.entity';

export const OCTOMO_TTL_SECONDS = 300;
const POLL_INTERVAL_SECONDS = 3;

@Injectable()
export class OctomoService {
  /** 폴링 중인 세션(아직 확인 안 됨, 만료 안 됨)은 체크 카운트를 올릴 때 이 값을 넘기면 중단 */
  readonly maxCheckCount = 30;

  constructor(
    @InjectRepository(AuthVerificationSessionModel)
    private readonly sessionRepository: Repository<AuthVerificationSessionModel>,
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {}

  /** api-spec §1.8 */
  async createChallenge(
    normalizedPhone: string,
    purpose: 'login' | 'signup',
  ): Promise<{
    session: AuthVerificationSessionModel;
    receiverNumber: string;
    verifyText: string;
    expiresIn: number;
    pollInterval: number;
  }> {
    const hourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentCount = await this.sessionRepository.count({
      where: {
        normalizedPhone,
        createdAt: MoreThanOrEqual(hourAgo),
      },
    });
    // phone lookup은 따로 rate limit하지 않고 여기서 한 번에 센다
    if (recentCount >= 5) {
      throw new ApiException(ERROR_CODE.COMMON.TOO_MANY_REQUESTS);
    }

    // 수신번호와 인증문자는 서버가 만든다 (OCTOMO 계약에 따라 고정/발급 혼용 가능)
    const receiverNumber =
      this.configService.get<string>('OCTOMO_RECEIVER_NUMBER') ?? '0503xxxxxxx';
    const verifyText = randomInt(1000, 9999).toString();

    const session = await this.sessionRepository.save(
      this.sessionRepository.create({
        normalizedPhone,
        purpose,
        verifyText,
        receiverNumber,
        expiresAt: new Date(Date.now() + OCTOMO_TTL_SECONDS * 1000),
        checkCount: 0,
      }),
    );

    return {
      session,
      receiverNumber,
      verifyText,
      expiresIn: OCTOMO_TTL_SECONDS,
      pollInterval: POLL_INTERVAL_SECONDS,
    };
  }

  /** api-spec §1.9 — 서버가 OCTOMO API를 호출해 수신 여부를 확인한다 */
  async checkVerification(
    sessionId: string,
  ): Promise<{
    status: 'pending' | 'verified';
    checkCount: number;
    expiresIn: number;
  }> {
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

    // 이미 검증됐으면 바로 verified 리턴
    if (session.verifiedAt) {
      const expiresIn = Math.max(
        0,
        Math.ceil(
          (session.expiresAt.getTime() - now.getTime()) / 1000,
        ),
      );
      return { status: 'verified', checkCount: session.checkCount, expiresIn };
    }

    // 소비된 세션은 검증 불가
    if (session.consumedAt) {
      throw new ApiException(ERROR_CODE.COMMON.NOT_FOUND);
    }

    // 최대 시도 횟수 초과
    if (session.checkCount >= this.maxCheckCount) {
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_EXPIRED);
    }

    // OCTOMO API 호출
    const apiKey = this.configService.getOrThrow<string>('OCTOMO_API_KEY');
    const exists = await this.callOctomoExists(
      apiKey,
      session.normalizedPhone,
      session.verifyText,
    );

    session.checkCount += 1;
    session.lastCheckedAt = now;

    if (exists) {
      session.verifiedAt = now;
    }

    await this.sessionRepository.save(session);

    if (exists) {
      const remaining = Math.max(
        0,
        Math.ceil(
          (session.expiresAt.getTime() - now.getTime()) / 1000,
        ),
      );
      return { status: 'verified', checkCount: session.checkCount, expiresIn: remaining };
    }

    return {
      status: 'pending',
      checkCount: session.checkCount,
      expiresIn: Math.max(
        0,
        Math.ceil(
          (session.expiresAt.getTime() - now.getTime()) / 1000,
        ),
      ),
    };
  }

  /** api-spec §1.9 — signup_token ↔ session_id */
  toSignupToken(sessionId: string): string {
    return `st_${sessionId}`;
  }

  resolveSignupToken(signupToken: string): string {
    if (signupToken.startsWith('st_')) {
      return signupToken.slice(3);
    }
    return signupToken;
  }

  /** 세션을 소비(consumed_at 기록)한다. atomic update로 중복 실행을 막는다 */
  async consumeSession(sessionId: string): Promise<void> {
    const now = new Date();
    const result = await this.sessionRepository.update(
      { id: sessionId, consumedAt: IsNull() },
      { consumedAt: now },
    );
    if (result.affected === 0) {
      // 이미 소비됐거나 존재하지 않음
      throw new ApiException(ERROR_CODE.AUTH.VERIFICATION_NOT_COMPLETED);
    }
  }

  /** OCTOMO API 호출 */
  private async callOctomoExists(
    apiKey: string,
    mobileNum: string,
    text: string,
  ): Promise<boolean> {
    const url = 'https://api.octoverse.kr/octomo/v1/public/message/exists';

    const response = await firstValueFrom(
      this.httpService.post<{ exists: boolean }>(
        url,
        {
          mobileNum,
          text,
          withinMinutes: 5,
        },
        {
          headers: {
            Authorization: `Octomo ${apiKey}`,
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
        },
      ),
    );

    return response.data.exists;
  }
}