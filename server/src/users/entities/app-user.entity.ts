import { Column, Entity, Index } from 'typeorm';

import { BaseModel } from 'src/common/entities/base.entity';

/**
 * 전화(OTP/OCTOMO)·카카오·아이디/비밀번호로 로그인한다.
 * 비밀번호는 bcrypt 해시로만 저장하며, 카카오/전화만 쓴 사용자는 null일 수 있다.
 *
 * `name`은 표시 전용 비정규화 값이다 — 원본은 user_intro_answer에 있다.
 */
@Entity('app_user')
export class AppUserModel extends BaseModel {
  /** 숫자만 11자리. 카카오 전용 가입이면 null */
  @Index('ux_app_user_phone', { unique: true })
  @Column({ type: 'varchar', length: 11, nullable: true })
  phone: string | null;

  /** 자기소개 i1에서 채워진다. 카카오 가입 시 닉네임으로 미리 채울 수 있다 */
  @Column({ type: 'varchar', length: 50, default: '' })
  name: string;

  /** 카카오 등 소셜에서 받은 이메일. 없으면 null */
  @Index('ux_app_user_email', { unique: true })
  @Column({ type: 'varchar', length: 255, nullable: true })
  email: string | null;

  /**
   * 아이디/비밀번호 로그인용 식별자.
   * 웹에서 가입했거나 설정에서 만든 경우만 채워진다.
   */
  @Index('ux_app_user_login_id', { unique: true })
  @Column({ name: 'login_id', type: 'varchar', length: 50, nullable: true })
  loginId: string | null;

  /** bcrypt 해시. login_id가 있어도 아직 비밀번호를 안 만든 경우는 없다(둘 다 함께 설정). */
  @Column({ name: 'password_hash', type: 'text', nullable: true })
  passwordHash: string | null;

  /** `storage/avatars/...` 상대 경로. null이면 이니셜 아바타. */
  @Column({ name: 'avatar_object_key', type: 'varchar', length: 255, nullable: true })
  avatarObjectKey: string | null;

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
