import { Column, Entity, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from './app-user.entity';

/** "오늘의 질문 알림" 발송 대상 */
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
}
