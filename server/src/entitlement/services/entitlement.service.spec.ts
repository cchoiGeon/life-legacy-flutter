import { EntitlementService } from './entitlement.service';

function buildService(
  options: {
    entitlements?: Array<{
      feature: string;
      planCode: string;
      expiresAt?: Date | null;
      revokedAt?: Date | null;
      grantedAt?: Date;
    }>;
    ledger?: Array<{ feature: string; bookId: string; delta: number }>;
    autoGrant?: boolean;
  } = {},
) {
  const entitlements = {
    find: jest.fn().mockResolvedValue(
      (options.entitlements ?? []).map((e) => ({
        feature: e.feature,
        planCode: e.planCode,
        expiresAt: e.expiresAt ?? null,
        revokedAt: e.revokedAt ?? null,
        grantedAt: e.grantedAt ?? new Date(),
      })),
    ),
    findOne: jest.fn(),
    save: jest.fn().mockImplementation((row) => Promise.resolve(row)),
    create: jest.fn().mockImplementation((row) => row),
  };
  const ledger = {
    find: jest.fn().mockImplementation(
      ({
        where,
      }: {
        where: { userId: string; bookId: string; feature: string };
      }) =>
        Promise.resolve(
          (options.ledger ?? []).filter(
            (r) =>
              r.bookId === where.bookId && r.feature === where.feature,
          ),
        ),
    ),
  };
  const config = {
    get: jest.fn((key: string) =>
      key === 'AUDIOBOOK_AUTO_GRANT' && options.autoGrant ? 'true' : undefined,
    ),
  };

  return {
    service: new EntitlementService(
      entitlements as never,
      ledger as never,
      config as never,
    ),
    entitlements,
    ledger,
  };
}

describe('EntitlementService', () => {
  it('행이 없으면 free 기본값을 준다', async () => {
    const { service } = buildService();
    const result = await service.getBookEntitlements('u1', 'b1');

    expect(result.plan_code).toBe('free');
    expect(result.features.ebook.allowed).toBe(true);
    expect(result.features.audiobook).toMatchObject({
      allowed: false,
      reason: 'PLAN_REQUIRED',
      remaining_generations: 0,
    });
    expect(result.features.ai_photo.remaining_generations).toBe(1);
  });

  it('T1 audiobook 행이 있으면 유료 플랜으로 올린다', async () => {
    const { service } = buildService({
      entitlements: [{ feature: 'audiobook', planCode: 'T1' }],
    });
    const result = await service.getBookEntitlements('u1', 'b1');

    expect(result.plan_code).toBe('T1');
    expect(result.features.audiobook.allowed).toBe(true);
    expect(result.features.ai_rewrite.allowed).toBe(true);
  });

  it('ai_photo 한도는 ledger 소모를 반영한다', async () => {
    const { service } = buildService({
      ledger: [{ feature: 'ai_photo', bookId: 'b1', delta: -1 }],
    });
    const result = await service.getBookEntitlements('u1', 'b1');

    expect(result.features.ai_photo.remaining_generations).toBe(0);
    expect(result.features.ai_photo.reason).toBe('LIMIT_REACHED');
  });

  it('dashboard 요약은 storybook을 WEB_ONLY로 고정한다', async () => {
    const { service } = buildService({
      entitlements: [{ feature: 'audiobook', planCode: 'T2' }],
    });
    const dash = await service.getDashboardEntitlements('u1', 'b1');

    expect(dash.audiobook.allowed).toBe(true);
    expect(dash.storybook).toEqual({ allowed: false, reason: 'WEB_ONLY' });
  });
});
