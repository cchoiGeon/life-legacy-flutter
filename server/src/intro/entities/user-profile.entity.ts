import { Column, Entity, JoinColumn, ManyToOne, OneToOne, PrimaryColumn } from 'typeorm';

import { AppUserModel } from 'src/users/entities/app-user.entity';
import { CaseDefinitionModel } from './case-definition.entity';

/**
 * 자기소개에서 파생된 판정 결과. 원본은 user_intro_answer에 그대로 있다.
 *
 * has_* 셋을 여기 복사해 두는 이유는 케이스 정의가 나중에 바뀌어도 이미
 * 목차를 확정한 사용자가 흔들리지 않게 하기 위해서다.
 */
@Entity('user_profile')
export class UserProfileModel {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @OneToOne(() => AppUserModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @ManyToOne(() => CaseDefinitionModel, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'case_id' })
  case: CaseDefinitionModel;

  /** 책 표지에 들어갈 이름 */
  @Column({ name: 'display_name', type: 'varchar', length: 50 })
  displayName: string;

  /** 문체 호칭용. 케이스와 무관 */
  @Column({ type: 'varchar', length: 10, nullable: true })
  gender: string | null;

  /** i5 원본 값. "고등학교" 등 */
  @Column({ name: 'education_level', type: 'varchar', length: 30 })
  educationLevel: string;

  @Column({ name: 'has_college', type: 'boolean' })
  hasCollege: boolean;

  @Column({ name: 'has_marriage', type: 'boolean' })
  hasMarriage: boolean;

  @Column({ name: 'has_children', type: 'boolean' })
  hasChildren: boolean;

  /** null이면 목차 확정 전 */
  @Column({ name: 'toc_confirmed_at', type: 'timestamptz', nullable: true })
  tocConfirmedAt: Date | null;
}
