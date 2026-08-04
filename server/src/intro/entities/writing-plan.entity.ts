import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  OneToOne,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';

@Entity('writing_plan')
export class WritingPlanModel {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => AppUserModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  /** 10 | 30 | 60 | 90 | 120 */
  @Column({ name: 'daily_minutes', type: 'smallint' })
  dailyMinutes: number;

  /** 0=일 ~ 6=토 */
  @Column({ name: 'available_weekdays', type: 'jsonb' })
  availableWeekdays: number[];

  /** am | pm */
  @Column({ name: 'available_periods', type: 'jsonb' })
  availablePeriods: string[];

  /** 1 | 2 | 4 | 6 */
  @Column({ name: 'duration_weeks', type: 'smallint' })
  durationWeeks: number;

  /** recommended | manual */
  @Column({ name: 'duration_source', type: 'varchar', length: 12 })
  durationSource: string;

  @Column({ name: 'alarm_enabled', type: 'boolean', default: true })
  alarmEnabled: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
