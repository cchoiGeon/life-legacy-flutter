import { Column, Entity, JoinColumn, ManyToOne, Unique } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from './app-user.entity';

@Entity('social_account')
@Unique('ux_social_provider_uid', ['provider', 'providerUserId'])
export class SocialAccountModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @Column({ type: 'varchar', length: 20 })
  provider: string;

  @Column({ name: 'provider_user_id', type: 'varchar', length: 100 })
  providerUserId: string;
}
