import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from './app-user.entity';

/** "오늘의 질문 알림" 발송 대상 — FCM 토큰 (iOS는 APNs via FCM) */
@Entity('device_push_token')
export class DevicePushTokenModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  /** ios | android */
  @Column({ type: 'varchar', length: 10 })
  platform: string;

  @Column({ type: 'varchar', length: 255, unique: true })
  token: string;

  /** 마지막 등록·갱신·발송 시도. 무효 토큰 정리 기준 */
  @Column({ name: 'last_used_at', type: 'timestamptz', nullable: true })
  lastUsedAt: Date | null;

  /** provider가 무효를 알려준 시각. 로그아웃 시에도 찍는다 */
  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt: Date | null;
}
