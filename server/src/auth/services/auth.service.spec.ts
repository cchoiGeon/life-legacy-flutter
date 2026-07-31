import { AuthService } from './auth.service';
import { hashSecret } from '../const/auth.util';
import { VERIFICATION_MAX_ATTEMPTS } from '../const/token.const';

/**
 * 인증·토큰의 **규칙**만 잰다. Nest 테스트 모듈 대신 생성자에 목을 직접
 * 넣는다 — 빠르고 의존성 그래프에 끌려다니지 않는다.
 */
function buildService() {
  const appUserRepository = {
    findById: jest.fn(),
    findByPhone: jest.fn(),
    create: jest.fn(),
    save: jest.fn().mockImplementation(async (u: unknown) => u),
  };
  const phoneVerificationRepository = {
    findLatestPending: jest.fn(),
    countIssuedSince: jest.fn().mockResolvedValue(0),
    create: jest.fn(),
    save: jest.fn().mockImplementation(async (v: unknown) => v),
  };
  const refreshTokenRepository = {
    findLiveByHash: jest.fn(),
    issue: jest.fn(),
    revoke: jest.fn(),
    revokeAllByUser: jest.fn(),
  };
  const smsService = {
    isStub: true,
    stubCode: '482915',
    sendVerificationCode: jest.fn(),
  };
  // 서명된 토큰이 매번 달라야 한다는 규칙을 확인하려고 payload를 그대로 찍는다.
  const jwtService = {
    signAsync: jest
      .fn()
      .mockImplementation(async (payload: object) => JSON.stringify(payload)),
  };
  const configService = { getOrThrow: jest.fn().mockReturnValue('secret'), get: jest.fn() };

  const service = new AuthService(
    appUserRepository as never,
    phoneVerificationRepository as never,
    refreshTokenRepository as never,
    smsService as never,
    jwtService as never,
    configService as never,
  );

  return {
    service,
    appUserRepository,
    phoneVerificationRepository,
    refreshTokenRepository,
    jwtService,
  };
}

function pendingVerification(overrides: Record<string, unknown> = {}) {
  return {
    phone: '01012345678',
    codeHash: hashSecret('482915'),
    expiresAt: new Date(Date.now() + 60_000),
    resendAvailableAt: new Date(Date.now() + 30_000),
    attemptCount: 0,
    consumedAt: null,
    ...overrides,
  };
}

describe('AuthService', () => {
  it('인증번호가 틀리면 INVALID_CODE로 거절한다', async () => {
    const { service, phoneVerificationRepository } = buildService();
    phoneVerificationRepository.findLatestPending.mockResolvedValue(
      pendingVerification(),
    );

    await expect(
      service.verifyCode('01012345678', '000000'),
    ).rejects.toMatchObject({ code: 'INVALID_CODE' });
  });

  it('한도를 넘겨 틀리면 그 인증번호를 죽인다', async () => {
    const { service, phoneVerificationRepository } = buildService();
    const verification = pendingVerification({
      attemptCount: VERIFICATION_MAX_ATTEMPTS - 1,
    });
    phoneVerificationRepository.findLatestPending.mockResolvedValue(verification);

    await expect(
      service.verifyCode('01012345678', '000000'),
    ).rejects.toMatchObject({ code: 'INVALID_CODE' });

    // 무차별 대입을 막는다. 다음부터는 번호를 다시 받아야 한다.
    expect(verification.consumedAt).not.toBeNull();
  });

  it('유효시간이 지났으면 CODE_EXPIRED로 거절한다', async () => {
    const { service, phoneVerificationRepository } = buildService();
    phoneVerificationRepository.findLatestPending.mockResolvedValue(
      pendingVerification({ expiresAt: new Date(Date.now() - 1_000) }),
    );

    await expect(
      service.verifyCode('01012345678', '482915'),
    ).rejects.toMatchObject({ code: 'CODE_EXPIRED' });
  });

  it('재발송 대기 중이면 새 번호를 만들지 않고 남은 시간만 알려 준다', async () => {
    const { service, phoneVerificationRepository } = buildService();
    phoneVerificationRepository.findLatestPending.mockResolvedValue(
      pendingVerification(),
    );

    const challenge = await service.requestVerificationCode('01012345678');

    // 여기서 새 번호를 발급하면 방금 받은 문자가 무효가 된다.
    expect(phoneVerificationRepository.create).not.toHaveBeenCalled();
    expect(challenge.resend_after).toBeGreaterThan(0);
  });

  it('발급 한도를 넘기면 TOO_MANY_REQUESTS로 막는다', async () => {
    const { service, phoneVerificationRepository } = buildService();
    phoneVerificationRepository.countIssuedSince.mockResolvedValue(5);

    await expect(
      service.requestVerificationCode('01012345678'),
    ).rejects.toMatchObject({ code: 'TOO_MANY_REQUESTS' });
  });

  it('리프레시 토큰은 쓰는 즉시 폐기하고 새것을 준다', async () => {
    const { service, refreshTokenRepository } = buildService();
    const stored = {
      user: { id: 'u1' },
      expiresAt: new Date(Date.now() + 60_000),
    };
    refreshTokenRepository.findLiveByHash.mockResolvedValue(stored);

    await service.refresh('old-token');

    // 한 번 쓴 토큰이 계속 유효하면, 새어 나갔을 때 만료를 기다릴 수밖에 없다.
    expect(refreshTokenRepository.revoke).toHaveBeenCalledWith(stored);
    expect(refreshTokenRepository.issue).toHaveBeenCalledTimes(1);
  });

  it('같은 초에 두 번 발급해도 리프레시 토큰이 겹치지 않는다', async () => {
    const { service, refreshTokenRepository } = buildService();
    refreshTokenRepository.findLiveByHash.mockResolvedValue({
      user: { id: 'u1' },
      expiresAt: new Date(Date.now() + 60_000),
    });

    const first = await service.refresh('a');
    const second = await service.refresh('b');

    // jti가 없으면 payload(sub·iat·exp)가 같아 토큰 문자열까지 같아지고,
    // token_hash 유니크에 걸려 갱신이 500으로 죽는다.
    expect(first.refresh_token).not.toEqual(second.refresh_token);
  });

  it('만료된 리프레시 토큰은 거절한다', async () => {
    const { service, refreshTokenRepository } = buildService();
    refreshTokenRepository.findLiveByHash.mockResolvedValue({
      user: { id: 'u1' },
      expiresAt: new Date(Date.now() - 1_000),
    });

    await expect(service.refresh('expired')).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
  });
});
