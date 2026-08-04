import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * [신규] OCTOMO 인증 세션.
 *
 * 방향이 v1 OTP와 반대다 —
 *   v1   서버가 인증번호를 발송하고 사용자가 앱에 입력한다
 *   To-Be 사용자가 지정 수신번호로 문자를 보내고, 서버가 수신 여부를 조회한다
 *
 * 서버만 POST /octomo/v1/public/message/exists 를 호출한다.
 * OCTOMO API Key는 Flutter·로그·분석 도구 어디에도 두지 않는다.
 * exists=true일 때만 verified_at을 찍는다 — 클라이언트가 결과를 위조할 수 없어야 한다.
 *
 * consumed_at을 원자적으로 갱신해 같은 세션으로 두 번 가입되지 않게 한다.
 */
@Entity('auth_verification_session')
@Index('ix_auth_session_lookup', ['normalizedPhone', 'createdAt'])
export class AuthVerificationSessionModel extends BaseModel {
  /** 숫자만 11자리 */
  @Column({ name: 'normalized_phone', type: 'varchar', length: 11 })
  normalizedPhone: string;

  /** login | signup */
  @Column({ type: 'varchar', length: 10 })
  purpose: string;

  /** 사용자가 수신번호로 보내야 하는 문자 원문. 예: 3538 */
  @Column({ name: 'verify_text', type: 'varchar', length: 20 })
  verifyText: string;

  /** OCTOMO 수신번호. 앱에 안내로 뜬다 */
  @Column({ name: 'receiver_number', type: 'varchar', length: 20 })
  receiverNumber: string;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt: Date;

  /** 서버가 OCTOMO를 조회한 횟수 */
  @Column({ name: 'check_count', type: 'smallint', default: 0 })
  checkCount: number;

  @Column({ name: 'last_checked_at', type: 'timestamptz', nullable: true })
  lastCheckedAt: Date | null;

  /** OCTOMO exists=true를 받은 시각 */
  @Column({ name: 'verified_at', type: 'timestamptz', nullable: true })
  verifiedAt: Date | null;

  /** 세션을 써서 로그인·가입을 마친 시각. 재사용 차단 */
  @Column({ name: 'consumed_at', type: 'timestamptz', nullable: true })
  consumedAt: Date | null;
}
