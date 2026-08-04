import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';
import { AppUserModel } from 'src/users/entities/app-user.entity';
import { ConsentDocumentModel } from './consent-document.entity';

/**
 * [신규] 필수 4종(이용약관·개인정보·만14세) + 선택(마케팅)의 동의 이력.
 * 가입은 사용자 생성과 이 행들을 한 트랜잭션으로 만든다 —
 * 약관에 동의하지 않은 계정이 생겨서는 안 된다.
 */
@Entity('user_consent')
@Index('ux_user_consent', ['user', 'consentDocument'], { unique: true })
@Index('ix_user_consent_user', ['user'])
export class UserConsentModel extends BaseModel {
  @ManyToOne(() => AppUserModel, { onDelete: 'CASCADE', nullable: false })
  @JoinColumn({ name: 'user_id' })
  user: AppUserModel;

  @ManyToOne(() => ConsentDocumentModel, { onDelete: 'RESTRICT', nullable: false })
  @JoinColumn({ name: 'consent_document_id' })
  consentDocument: ConsentDocumentModel;

  @Column({ name: 'agreed_at', type: 'timestamptz' })
  agreedAt: Date;

  /** 마케팅 동의 철회 등 */
  @Column({ name: 'revoked_at', type: 'timestamptz', nullable: true })
  revokedAt: Date | null;

  /** app | web */
  @Column({ type: 'varchar', length: 10, default: 'app' })
  channel: string;
}
