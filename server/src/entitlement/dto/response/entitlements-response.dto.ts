import { ApiProperty } from '@nestjs/swagger';

/** api-spec §11 기능별 잠금 안내 */
export class FeatureEntitlementDto {
  @ApiProperty() allowed: boolean;
  @ApiProperty({ nullable: true, type: String }) reason: string | null;
  @ApiProperty({
    nullable: true,
    type: Number,
    description: 'null = 한도 없음. 생성에만 적용',
  })
  remaining_generations: number | null;
}

export class EntitlementsResponseDto {
  @ApiProperty({ example: 'free' }) plan_code: string;

  @ApiProperty({ type: 'object', additionalProperties: { type: 'object' } })
  features: Record<string, FeatureEntitlementDto>;
}
