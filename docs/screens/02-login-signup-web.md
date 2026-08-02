# 로그인 및 회원가입 — Next.js 웹 개발가이드

## 1. 개요

- **목적**: 웹 사용자가 기존 아이디/비밀번호(Credentials/NextAuth)로 로그인하고, 이메일·비밀번호 기반 계정을 생성해 웹 작성·검토 기능에 접근하게 한다.
- **대상**: 2030 자녀와 웹에서 직접 작성·수정하는 사용자.
- **관련 문서**: [화면 색인](./00-index.md), [현재 기능 정의 AUTH-01·AUTH-01b](../01-현재-기능정의.md), [웹·앱 분리 로드맵](../02-웹앱-분리-로드맵.md).
- **인증 경계**: 웹 화면에는 앱의 OCTOMO 전화번호 인증을 넣지 않는다. OCTOMO SMS 인증은 Flutter 앱 전용 흐름이며, 웹은 기존 Credentials 로그인을 유지한다.

`AUTH-01`은 NextAuth Credentials(JWT 세션) 기반 로그인·회원가입으로 구현되어 있다. `AUTH-01b`의 Kakao/Google/Naver SNS OAuth는 `SignupForm`에 TODO만 있고 **미구현**이다.

## 2. 유저 플로우

### 로그인

1. 사용자가 `/login`에 진입한다. 보호된 대시보드에서 온 경우 `callbackUrl`을 유지한다.
2. 아이디(현행 구현은 `user.email`로 조회)와 비밀번호를 입력한다.
3. `signIn("credentials")`가 NextAuth Credentials provider를 호출한다.
4. 서버는 bcrypt 해시를 비교하고 JWT 세션에 사용자 ID·role을 넣는다.
5. 성공하면 `callbackUrl` 또는 기본 `/mypage`로 이동한다. 대시보드 레이아웃은 유효 사용자 ID가 없으면 `/login`으로 되돌린다.

### 회원가입

1. 사용자가 `/signup`에서 아이디(현행 DB 컬럼은 `email`)와 비밀번호·확인을 입력한다.
2. 필수 서비스 이용약관·개인정보 처리방침에 동의한다.
3. `/api/auth/signup`이 중복을 확인하고 bcrypt 해시 비밀번호로 `user` 레코드를 생성한다.
4. 현재 구현은 자동 로그인하지 않고 성공 안내 뒤 `/login`으로 이동한다.

### 앱 인증과의 관계

- 앱의 전화번호/OCTOMO/약관 가입은 웹 로그인 화면에 노출하지 않는다.
- 앱 전용 계정과 웹 Credentials 계정을 같은 사용자로 통합할지, `account` 또는 별도 인증수단 링크 모델로 연결할지는 미확정이다. 통합 전에는 앱·웹의 인증 DB와 토큰을 상호 호환된다고 가정하지 않는다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| Credentials 로그인 | 아이디·비밀번호, bcrypt 비교, NextAuth JWT 세션 | 기존 (`AUTH-01`) |
| 회원가입 | 아이디(현행 `email`)·6자 이상 비밀번호·필수 약관 확인 | 기존 (`AUTH-01`) |
| 로그인 실패 | “아이디 또는 비밀번호를 확인해 주세요.” 표시 | 기존 |
| 대시보드 보호 | 세션 사용자 ID 유효성 확인, 실패 시 `/login` 리다이렉트 | 기존 (`AUTH-02`) |
| OAuth | Kakao/Google/Naver | 미구현 (`AUTH-01b`) |
| OCTOMO 전화번호 로그인 | 앱 전용; 웹 UI/API에 추가하지 않음 | 비범위 |
| 앱·웹 계정 연결 | 동일 사용자 모델 또는 링크 모델 결정 | 신규·미정 |

## 4. 화면 구성

| 화면 | 주요 섹션 | 기존 Next.js 대응 |
|---|---|---|
| `/login` | 브랜드, 아이디, 비밀번호, 로그인, 회원가입 링크 | 기존 |
| `/signup` | 아이디, 비밀번호/확인, 이용약관·개인정보 처리방침 필수 동의, 로그인 링크 | 기존 |
| 인증 오류 | 필드 검증, 중복 아이디, 로그인 실패 토스트/문구 | 기존 |
| 보호 영역 | `(dashboard)` 레이아웃의 세션 검증 | 기존 |

웹 가입 화면은 앱의 이름+전화번호, OCTOMO 전송 안내, “이용약관을 확인해 주세요” 4항목 동의 UI를 복제하지 않는다. 다만 앱·웹 계정 통합 정책이 확정되면 약관 버전 및 동의 이력의 단일 소스를 재검토한다.

## 5. API 엔드포인트

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| POST | `/api/auth/callback/credentials` | NextAuth Credentials provider의 로그인 콜백 | 기존 |
| GET / POST | `/api/auth/[...nextauth]` | NextAuth 핸들러 및 세션 관련 라우트 | 기존 |
| POST | `/api/auth/signup` | 아이디·비밀번호·필수 약관 확인 후 계정 생성 | 기존 |
| — | OCTOMO 관련 웹 API | 웹 로그인 범위에 없음 | 비범위 |

현행 회원가입 API는 `identifier`, `password`, `agreeTerms`, `agreePrivacy`를 확인한다. `identifier`는 이름 또는 이메일이라는 화면 문구와 달리 데이터베이스의 `user.email`에 저장·조회되므로, 실제 허용 형식과 명칭을 통일할 필요가 있다.

## 6. 데이터 모델

| 테이블 | 주요 필드/역할 | 상태 |
|---|---|---|
| `user` | `id`, `name`, `email`(not null·unique), `password`(bcrypt hash), `role`, 프로필·주소 설정 | 기존 |
| `account` | NextAuth provider 계정 연결용 `provider`·`providerAccountId` 복합 PK | 기존 |
| `session` | Drizzle Adapter 세션 테이블 | 기존 |
| `verification_token` | NextAuth 검증 토큰 테이블 | 기존 |
| 앱 인증수단 링크 | 앱 전화번호/OCTOMO 사용자와 웹 `user` 연결을 위한 식별자·검증 이력 | 신규 후보 |
| 공통 동의 이력 | 앱·웹 공통 정책 채택 시 약관 항목·버전·동의/철회시각 | 신규 후보 |

현행 `user`는 `email` 유니크뿐 아니라 `name`에도 유니크 인덱스가 있다. 반면 Flutter/NestJS의 신규 제안은 `(name, normalized_phone)`을 최종 식별 기준으로 하므로, 두 모델은 현재 동일 사용자 계정 모델이 아니다.

## 7. 기존 코드 참고

- `app/app/(auth)/login/page.tsx` — 로그인 페이지와 `callbackUrl` 전달
- `app/app/(auth)/signup/page.tsx` — 회원가입 페이지
- `app/components/auth/LoginForm.tsx` — Credentials `signIn`, 로그인 오류·리다이렉트
- `app/components/auth/SignupForm.tsx` — 가입 폼, 필수 약관 체크, SNS OAuth TODO
- `app/lib/auth.ts` — DrizzleAdapter, Credentials provider, bcrypt 검증, JWT/session callback
- `app/app/api/auth/[...nextauth]/route.ts` — NextAuth GET/POST 핸들러
- `app/app/api/auth/signup/route.ts` — 중복 검사·bcrypt 해시·계정 생성
- `app/lib/db/schema.ts` — `user`, `account`, `session`, `verification_token` 정의
- `app/app/(dashboard)/layout.tsx` — `getValidUserId()` 기반 대시보드 인증 가드
- `app/middleware.ts` — 관리자 및 관리자 API 전용 JWT/게이트 가드

## 8. 신규 개발 범위 요약

1. 웹은 현행 Credentials 로그인·이메일/아이디와 비밀번호 가입을 유지한다. OCTOMO UI·클라이언트 호출을 추가하지 않는다.
2. 화면 문구의 “이름 또는 이메일”과 실제 `email` 유니크·조회 정책을 정합화한다.
3. 앱 전화번호 계정과 웹 계정의 통합 여부가 결정되면, 사용자 식별자 매핑·계정 링크·세션 교환 금지·약관 이력 귀속을 설계한다.
4. SNS OAuth(`AUTH-01b`)는 이번 로그인/회원가입 범위에서 구현하지 않는다.

## 9. 열린 이슈 / 가정

1. **계정 통합**: 앱의 `(name, normalized_phone)` 사용자와 웹의 `email` 유니크 Credentials 사용자를 하나의 계정으로 합칠지, 별도 인증수단 링크 모델로 연결할지 미정이다.
2. **사용자 데이터 공유**: 앱·웹을 단일 사용자로 통합할 때 기존 Next.js Drizzle DB와 NestJS PostgreSQL의 소유권·ID 매핑·마이그레이션 주체를 결정해야 한다.
3. **약관 일관성**: 앱은 4개 동의 항목과 버전·철회 이력을 요구하고, 웹은 현재 약관/개인정보 2개 boolean만 검증한다. 공통 법적 동의 모델을 채택할지 결정해야 한다.
4. **웹 아이디 의미**: UI는 “이름 또는 이메일”이라고 하지만 서버는 `email`로만 조회·저장한다. 이메일 형식 강제 여부와 표시 문구를 확정해야 한다.
5. **웹 SNS OAuth**: Kakao/Google/Naver는 `AUTH-01b`로 미구현이며, 추가 시 앱 OCTOMO 계정과의 연결 규칙도 함께 정해야 한다.
6. **앱 ID/PW 링크**: 앱의 “ID, PW로 로그인하기”를 웹 로그인으로 연결할 경우, 인앱 브라우저/딥링크 후 세션 전달을 어떻게 안전하게 처리할지 미정이다.
