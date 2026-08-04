import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';

/**
 * [신규] 기능별 권한. 서버 판정용.
 * (`erd/new-erd.dbml` user_entitlement)
 */
@Entity('user_entitlement')
@Index('ix_entitlement_user_feature', ['userId', 'feature'])
export class UserEntitlementModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  /** ebook | audiobook | storybook | chapter_write | ai_rewrite | manual_photo */
  @Column({ type: 'varchar', length: 30 })
  feature: string;

  /** free | T1 ~ T4 */
  @Column({ name: 'plan_code', type: 'varchar', length: 20 })
  planCode: string;

  /** purchase | promotion | default */
  @Column({ type: 'varchar', length: 20 })
  source: string;

  @CreateDateColumn({ name: 'granted_at', type: 'timestamptz' })
  grantedAt: Date;

  @Column({ name: 'expires_at', type: 'timestamptz', nullable: true })
  expiresAt: Date | null;

  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt: Date | null;
}
