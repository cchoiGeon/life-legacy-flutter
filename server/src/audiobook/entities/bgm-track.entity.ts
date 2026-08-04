import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

/**
 * [신규] 오디오북 배경음 카탈로그.
 * (`erd/new-erd.dbml` bgm_track)
 */
@Entity('bgm_track')
export class BgmTrackModel {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 100 })
  title: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  mood: string | null;

  @Column({ name: 'object_key', type: 'varchar', length: 500 })
  objectKey: string;

  @Column({ name: 'license_source', type: 'varchar', length: 200 })
  licenseSource: string;

  @Column({ name: 'allowed_regions', type: 'jsonb', nullable: true })
  allowedRegions: unknown | null;

  @Column({ name: 'valid_until', type: 'date', nullable: true })
  validUntil: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
