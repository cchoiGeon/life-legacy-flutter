/** api-spec §1.9·§1.10·§1.11 — 로컬/초기 약관 레지스트리 */
export const CONSENT_SEED = [
  {
    consentKey: 'terms_of_service',
    version: '1.0',
    title: '서비스 이용약관',
    url: 'https://lifelog.example/terms',
    isRequired: true,
  },
  {
    consentKey: 'privacy_policy',
    version: '1.0',
    title: '개인정보 처리방침',
    url: 'https://lifelog.example/privacy',
    isRequired: true,
  },
  {
    consentKey: 'age_14',
    version: '1.0',
    title: '만 14세 이상입니다',
    url: '',
    isRequired: true,
  },
  {
    consentKey: 'marketing',
    version: '1.0',
    title: '마케팅 정보 수신',
    url: 'https://lifelog.example/marketing',
    isRequired: false,
  },
] as const;
