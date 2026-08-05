import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, IsNull, Repository } from 'typeorm';

import { EntitlementLedgerModel } from '../entities/entitlement-ledger.entity';
import { UserEntitlementModel } from '../entities/user-entitlement.entity';
import { EntitlementsResponseDto } from '../dto/response/entitlements-response.dto';

type FeatureKey =
  | 'ebook'
  | 'audiobook'
  | 'manual_photo'
  | 'ai_photo'
  | 'ai_rewrite';

type FeatureFlag = {
  allowed: boolean;
  reason: string | null;
  remaining_generations: number | null;
};

/** 상시 무료 기본값 — DB에 행이 없어도 적용 (§11 예시 + 랜딩 무료 플랜) */
const FREE_DEFAULTS: Record<FeatureKey, FeatureFlag> = {
  ebook: { allowed: true, reason: null, remaining_generations: null },
  audiobook: {
    allowed: false,
    reason: 'PLAN_REQUIRED',
    remaining_generations: 0,
  },
  manual_photo: {
    allowed: false,
    reason: 'PLAN_REQUIRED',
    remaining_generations: 0,
  },
  ai_photo: { allowed: true, reason: null, remaining_generations: 1 },
  ai_rewrite: {
    allowed: false,
    reason: 'PLAN_REQUIRED',
    remaining_generations: 0,
  },
};

/** T1 이상 — 유료 feature 전부 허용. 챕터별 한도는 overview 응답에서 따로 준다 */
const PAID_DEFAULTS: Record<FeatureKey, FeatureFlag> = {
  ebook: { allowed: true, reason: null, remaining_generations: null },
  audiobook: { allowed: true, reason: null, remaining_generations: null },
  manual_photo: { allowed: true, reason: null, remaining_generations: null },
  ai_photo: { allowed: true, reason: null, remaining_generations: null },
  ai_rewrite: { allowed: true, reason: null, remaining_generations: null },
};

const PLAN_RANK: Record<string, number> = {
  free: 0,
  T1: 1,
  T2: 2,
  T3: 3,
  T4: 4,
};

@Injectable()
export class EntitlementService {
  constructor(
    @InjectRepository(UserEntitlementModel)
    private readonly entitlements: Repository<UserEntitlementModel>,
    @InjectRepository(EntitlementLedgerModel)
    private readonly ledger: Repository<EntitlementLedgerModel>,
    private readonly config: ConfigService,
  ) {}

  /** api-spec §11 UI 안내용 (접근 통제 아님) */
  async getBookEntitlements(
    userId: string,
    bookId: string,
  ): Promise<EntitlementsResponseDto> {
    const active = await this.findActive(userId);
    let planCode = this.derivePlanCode(active);
    const autoGrant =
      this.config.get<string>('AUDIOBOOK_AUTO_GRANT') === 'true';
    if (autoGrant && planCode === 'free') planCode = 'T1';

    const base =
      planCode === 'free'
        ? { ...cloneFlags(FREE_DEFAULTS) }
        : { ...cloneFlags(PAID_DEFAULTS) };

    // DB에 feature 행이 있으면 그 허용을 우선(프로모션 등)
    for (const row of active) {
      const key = row.feature as FeatureKey;
      if (!(key in base)) continue;
      base[key] = {
        allowed: true,
        reason: null,
        remaining_generations: base[key].remaining_generations,
      };
    }

    if (autoGrant) {
      base.audiobook = {
        allowed: true,
        reason: null,
        remaining_generations: null,
      };
    }

    if (base.ai_photo.allowed && base.ai_photo.remaining_generations != null) {
      const used = await this.sumUsage(userId, bookId, 'ai_photo');
      base.ai_photo.remaining_generations = Math.max(
        0,
        base.ai_photo.remaining_generations - used,
      );
      if (base.ai_photo.remaining_generations === 0) {
        base.ai_photo.reason = 'LIMIT_REACHED';
      }
    }

    return { plan_code: planCode, features: base };
  }

  /** §6.2 dashboard 요약 — storybook은 앱 비범위 */
  async getDashboardEntitlements(userId: string, bookId: string) {
    const full = await this.getBookEntitlements(userId, bookId);
    return {
      ebook: {
        allowed: full.features.ebook.allowed,
        reason: full.features.ebook.reason,
      },
      audiobook: {
        allowed: full.features.audiobook.allowed,
        reason: full.features.audiobook.reason,
      },
      storybook: { allowed: false as const, reason: 'WEB_ONLY' },
    };
  }

  async hasFeature(userId: string, feature: string): Promise<boolean> {
    if (
      feature === 'audiobook' &&
      this.config.get<string>('AUDIOBOOK_AUTO_GRANT') === 'true'
    ) {
      return true;
    }
    const active = await this.findActive(userId);
    if (active.some((r) => r.feature === feature)) return true;
    const plan = this.derivePlanCode(active);
    if (plan !== 'free') {
      return feature in PAID_DEFAULTS
        ? PAID_DEFAULTS[feature as FeatureKey].allowed
        : false;
    }
    return feature in FREE_DEFAULTS
      ? FREE_DEFAULTS[feature as FeatureKey].allowed
      : false;
  }

  /** 로컬/프로모션 — audiobook T1 권한 부여(멱등) */
  async grantAudiobookT1(
    userId: string,
    source = 'default',
    /** signup 트랜잭션 안에서는 같은 manager를 써야 FK가 보인다 */
    manager?: EntityManager,
  ): Promise<void> {
    const repo = manager
      ? manager.getRepository(UserEntitlementModel)
      : this.entitlements;
    const existing = await this.findActiveFeature(userId, 'audiobook', repo);
    if (existing) return;
    await repo.save(
      repo.create({
        userId,
        feature: 'audiobook',
        planCode: 'T1',
        source,
      }),
    );
  }

  async findActiveFeature(
    userId: string,
    feature: string,
    repo: Repository<UserEntitlementModel> = this.entitlements,
  ): Promise<UserEntitlementModel | null> {
    const active = await this.findActive(userId, repo);
    return active.find((r) => r.feature === feature) ?? null;
  }

  private async findActive(
    userId: string,
    repo: Repository<UserEntitlementModel> = this.entitlements,
  ): Promise<UserEntitlementModel[]> {
    const rows = await repo.find({
      where: { userId, revokedAt: IsNull() },
      order: { grantedAt: 'DESC' },
    });
    const now = Date.now();
    return rows.filter(
      (r) => r.expiresAt == null || r.expiresAt.getTime() > now,
    );
  }

  private derivePlanCode(active: UserEntitlementModel[]): string {
    if (active.length === 0) return 'free';
    let best = 'free';
    let bestRank = 0;
    for (const row of active) {
      const rank = PLAN_RANK[row.planCode] ?? 0;
      if (rank > bestRank) {
        bestRank = rank;
        best = row.planCode;
      }
    }
    return best;
  }

  /** ledger delta 합(음수 소모). 절대값으로 사용한 횟수 */
  private async sumUsage(
    userId: string,
    bookId: string,
    feature: string,
  ): Promise<number> {
    const rows = await this.ledger.find({
      where: { userId, bookId, feature },
    });
    const sum = rows.reduce((acc, r) => acc + r.delta, 0);
    return Math.max(0, -sum);
  }
}

function cloneFlags(
  src: Record<FeatureKey, FeatureFlag>,
): Record<FeatureKey, FeatureFlag> {
  return {
    ebook: { ...src.ebook },
    audiobook: { ...src.audiobook },
    manual_photo: { ...src.manual_photo },
    ai_photo: { ...src.ai_photo },
    ai_rewrite: { ...src.ai_rewrite },
  };
}
