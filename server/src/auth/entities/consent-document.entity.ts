import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * 약관 문서 버전 레지스트리.
 * 동의 이력이 "어느 버전에 동의했는지"를 가리켜야 재동의 대상을 가려낼 수 있다.
 * 본문(content)은 마크다운으로 보관하며, 앱·웹이 API로 읽어 표시한다.
 */
@Entity('consent_document')
@Index('ux_consent_document_version', ['consentKey', 'version'], { unique: true })
export class ConsentDocumentModel extends BaseModel {
  /** terms_of_service | privacy_policy | refund_policy | age_14 | marketing */
  @Column({ name: 'consent_key', type: 'varchar', length: 40 })
  consentKey: string;

  @Column({ type: 'varchar', length: 20 })
  version: string;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  /** 외부 호스팅 URL(선택). 본문이 있으면 앱은 content를 우선한다. */
  @Column({ type: 'varchar', length: 500, default: '' })
  url: string;

  /** 마크다운 본문. age_14 등 체크만 하는 항목은 null/빈 문자열. */
  @Column({ type: 'text', nullable: true })
  content: string | null;

  @Column({ name: 'is_required', type: 'boolean' })
  isRequired: boolean;

  /**
   * 가입 동의 체크리스트에 노출할지.
   * 환불정책처럼 열람 전용인 문서는 false.
   */
  @Column({ name: 'is_consent_item', type: 'boolean', default: true })
  isConsentItem: boolean;

  @Column({ name: 'effective_at', type: 'timestamptz' })
  effectiveAt: Date;
}
