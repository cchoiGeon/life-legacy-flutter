import { createHash, randomInt, timingSafeEqual } from 'node:crypto';

import * as bcrypt from 'bcryptjs';

/**
 * 인증번호·리프레시 토큰은 **원문을 저장하지 않는다.**
 *
 * 6자리 숫자에 bcrypt를 쓰면 검증마다 수십 ms가 붙는데, 짧게 살고 시도
 * 횟수가 5회로 막혀 있어 그만한 값이 없다. 단방향 해시로 충분하다.
 */
export function hashSecret(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

/** 길이가 같은 해시끼리 상수 시간 비교 — 타이밍으로 새어 나가지 않게 */
export function matchesSecret(value: string, hash: string): boolean {
  const left = Buffer.from(hashSecret(value));
  const right = Buffer.from(hash);
  if (left.length !== right.length) {
    return false;
  }

  return timingSafeEqual(left, right);
}

/** 000000~999999 */
export function generateVerificationCode(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

/** 로그인 비밀번호 — 웹(lifelegacy)과 동일하게 bcrypt cost 10 */
const PASSWORD_BCRYPT_ROUNDS = 10;

export async function hashPassword(plain: string): Promise<string> {
  return await bcrypt.hash(plain, PASSWORD_BCRYPT_ROUNDS);
}

export async function matchesPassword(
  plain: string,
  hash: string,
): Promise<boolean> {
  return await bcrypt.compare(plain, hash);
}
