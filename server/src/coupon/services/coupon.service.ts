import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, ILike, Repository } from 'typeorm';

import { ApiException } from 'src/common/exception/api.exception';
import { ERROR_CODE } from 'src/common/exception/error-code.const';
import { EntitlementService } from 'src/entitlement/services/entitlement.service';
import { CreateCouponDto } from '../dto/request/create-coupon.dto';
import { UpdateCouponDto } from '../dto/request/update-coupon.dto';
import { CouponResponseDto } from '../dto/response/coupon-response.dto';
import { RedeemCouponResponseDto } from '../dto/response/redeem-coupon-response.dto';
import { CouponRedemptionModel } from '../entities/coupon-redemption.entity';
import { CouponModel } from '../entities/coupon.entity';

@Injectable()
export class CouponService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(CouponModel)
    private readonly coupons: Repository<CouponModel>,
    @InjectRepository(CouponRedemptionModel)
    private readonly redemptions: Repository<CouponRedemptionModel>,
    private readonly entitlementService: EntitlementService,
  ) {}

  async create(dto: CreateCouponDto): Promise<CouponResponseDto> {
    const code = normalizeCode(dto.code);
    const existing = await this.coupons.findOne({
      where: { code: ILike(code) },
    });
    if (existing) {
      throw new ApiException(ERROR_CODE.COUPON.CODE_TAKEN);
    }

    const row = await this.coupons.save(
      this.coupons.create({
        code,
        planCode: dto.plan_code,
        maxRedemptions: dto.max_redemptions ?? null,
        redemptionCount: 0,
        expiresAt: dto.expires_at ? new Date(dto.expires_at) : null,
        note: dto.note ?? null,
        isActive: dto.is_active ?? true,
      }),
    );
    return CouponResponseDto.from(row);
  }

  async list(): Promise<CouponResponseDto[]> {
    const rows = await this.coupons.find({
      order: { createdAt: 'DESC' },
    });
    return rows.map(CouponResponseDto.from);
  }

  async get(id: string): Promise<CouponResponseDto> {
    return CouponResponseDto.from(await this.requireById(id));
  }

  async update(id: string, dto: UpdateCouponDto): Promise<CouponResponseDto> {
    const row = await this.requireById(id);
    if (dto.plan_code !== undefined) row.planCode = dto.plan_code;
    if (dto.max_redemptions !== undefined) {
      row.maxRedemptions = dto.max_redemptions;
    }
    if (dto.expires_at !== undefined) {
      row.expiresAt = dto.expires_at ? new Date(dto.expires_at) : null;
    }
    if (dto.note !== undefined) row.note = dto.note;
    if (dto.is_active !== undefined) row.isActive = dto.is_active;
    return CouponResponseDto.from(await this.coupons.save(row));
  }

  /** 비활성 처리(소프트). 이미 교환된 이력이 있어도 코드는 남긴다. */
  async deactivate(id: string): Promise<CouponResponseDto> {
    const row = await this.requireById(id);
    row.isActive = false;
    return CouponResponseDto.from(await this.coupons.save(row));
  }

  async redeem(
    userId: string,
    rawCode: string,
  ): Promise<RedeemCouponResponseDto> {
    const code = normalizeCode(rawCode);

    return this.dataSource.transaction(async (manager) => {
      const couponRepo = manager.getRepository(CouponModel);
      const redemptionRepo = manager.getRepository(CouponRedemptionModel);

      const coupon = await couponRepo
        .createQueryBuilder('c')
        .setLock('pessimistic_write')
        .where('upper(c.code) = :code', { code })
        .getOne();

      if (!coupon) {
        throw new ApiException(ERROR_CODE.COUPON.NOT_FOUND);
      }
      if (!coupon.isActive) {
        throw new ApiException(ERROR_CODE.COUPON.INACTIVE);
      }
      if (coupon.expiresAt && coupon.expiresAt.getTime() <= Date.now()) {
        throw new ApiException(ERROR_CODE.COUPON.EXPIRED);
      }
      if (
        coupon.maxRedemptions != null &&
        coupon.redemptionCount >= coupon.maxRedemptions
      ) {
        throw new ApiException(ERROR_CODE.COUPON.EXHAUSTED);
      }

      const already = await redemptionRepo.findOne({
        where: { couponId: coupon.id, userId },
      });
      if (already) {
        throw new ApiException(ERROR_CODE.COUPON.ALREADY_REDEEMED);
      }

      await redemptionRepo.save(
        redemptionRepo.create({
          couponId: coupon.id,
          userId,
          planCode: coupon.planCode,
          redeemedAt: new Date(),
        }),
      );

      coupon.redemptionCount += 1;
      await couponRepo.save(coupon);

      const planCode = await this.entitlementService.grantPlan(
        userId,
        coupon.planCode,
        'coupon',
        manager,
      );

      return {
        plan_code: planCode,
        message: `${planCode} 플랜이 적용됐어요`,
      };
    });
  }

  private async requireById(id: string): Promise<CouponModel> {
    const row = await this.coupons.findOne({ where: { id } });
    if (!row) {
      throw new ApiException(ERROR_CODE.COUPON.NOT_FOUND);
    }
    return row;
  }
}

function normalizeCode(code: string): string {
  return code.trim().toUpperCase();
}
