import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * [신규] 약관 문서 버전 레지스트리.
 * 동의 이력이 "어느 버전에 동의했는지"를 가리켜야 재동의 대상을 가려낼 수 있다.
 * 실제 URL·버전 발행 규칙은 §확정 대기 · 약관 운영
 */
@Entity('consent_document')
@Index('ux_consent_document_version', ['consentKey', 'version'], { unique: true })
export class ConsentDocumentModel extends BaseModel {
  /** terms_of_service | privacy_policy | age_14 | marketing */
  @Column({ name: 'consent_key', type: 'varchar', length: 40 })
  consentKey: string;

  @Column({ type: 'varchar', length: 20 })
  version: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  @Column({ type: 'varchar', length: 500 })
  url: string;

  @Column({ name: 'is_required', type: 'boolean' })
  isRequired: boolean;

  @Column({ name: 'effective_at', type: 'timestamptz' })
  effectiveAt: Date;
}
