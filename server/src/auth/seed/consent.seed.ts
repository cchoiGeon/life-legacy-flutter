import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * 리포 루트 md를 시드 본문으로 쓴다.
 * `npm run seed`는 보통 `server/` cwd에서 돌아가므로 `..` 후보도 본다.
 */
export function loadRepoMarkdown(fileName: string): string {
  const candidates = [
    join(process.cwd(), fileName),
    join(process.cwd(), '..', fileName),
  ];
  for (const path of candidates) {
    if (existsSync(path)) {
      return readFileSync(path, 'utf8');
    }
  }
  throw new Error(
    `약관 마크다운을 찾을 수 없습니다: ${fileName} (cwd=${process.cwd()})`,
  );
}

export type ConsentSeedRow = {
  consentKey: string;
  version: string;
  title: string;
  url: string;
  isRequired: boolean;
  /** 가입 동의 체크리스트 노출. 환불정책은 false. */
  isConsentItem: boolean;
  /** null이면 본문 없음(체크만). 함수면 시드 시점에 파일에서 읽음. */
  content: string | null | (() => string);
};

/** api-spec §1.9·§1.10·§1.11 — 로컬/초기 약관 레지스트리 */
export const CONSENT_SEED: readonly ConsentSeedRow[] = [
  {
    consentKey: 'terms_of_service',
    version: '1.0',
    title: '서비스 이용약관',
    url: '',
    isRequired: true,
    isConsentItem: true,
    content: () => loadRepoMarkdown('서비스이용약관.md'),
  },
  {
    consentKey: 'privacy_policy',
    version: '1.0',
    title: '개인정보 처리방침',
    url: '',
    isRequired: true,
    isConsentItem: true,
    content: () => loadRepoMarkdown('개인정보.md'),
  },
  {
    consentKey: 'refund_policy',
    version: '1.0',
    title: '환불 정책',
    url: '',
    isRequired: false,
    isConsentItem: false,
    content: () => loadRepoMarkdown('환불정책.md'),
  },
  {
    consentKey: 'age_14',
    version: '1.0',
    title: '만 14세 이상입니다',
    url: '',
    isRequired: true,
    isConsentItem: true,
    content: null,
  },
  {
    consentKey: 'marketing',
    version: '1.0',
    title: '마케팅 정보 수신',
    url: '',
    isRequired: false,
    isConsentItem: true,
    content:
      '마케팅 정보 수신에 동의하면 기로기의 새로운 기능, 할인·쿠폰, 이벤트 등 광고성 정보를 문자·앱 알림·이메일 등으로 받아보실 수 있습니다. 동의하지 않아도 서비스 이용에는 제한이 없으며, 설정에서 언제든 철회할 수 있습니다.',
  },
] as const;

export function resolveConsentContent(
  content: ConsentSeedRow['content'],
): string | null {
  if (content == null) return null;
  if (typeof content === 'function') return content();
  return content;
}
