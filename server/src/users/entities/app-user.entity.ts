import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * 전화번호 SMS 인증 또는 카카오로 로그인한다. **비밀번호가 없다.**
 *
 * `name`은 표시 전용 비정규화 값이다 — 원본은 user_intro_answer에 있다.
 */
@Entity('app_user')
export class AppUserModel extends BaseModel {
  /** 숫자만 11자리. 카카오 전용 가입이면 null */
  @Index('ux_app_user_phone', { unique: true })
  @Column({ type: 'varchar', length: 11, nullable: true })
  phone: string | null;

  /** 자기소개 i1에서 채워진다. 가입 직후엔 빈 문자열 */
  @Column({ type: 'varchar', length: 50, default: '' })
  name: string;

  /** 자녀 계정 연결. 흐름은 2차 */
  @Column({ name: 'child_linked', type: 'boolean', default: false })
  childLinked: boolean;

  /** null이면 API의 needs_intro=true */
  @Column({ name: 'intro_completed_at', type: 'timestamptz', nullable: true })
  introCompletedAt: Date | null;

  @Column({ name: 'last_login_at', type: 'timestamptz', nullable: true })
  lastLoginAt: Date | null;

  /** 탈퇴. 본문은 보존 기간이 지난 뒤 파기한다 */
  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;
}
