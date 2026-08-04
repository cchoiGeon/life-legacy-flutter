# 로그인 및 회원가입 — Flutter 앱 + NestJS 개발가이드

## 1. 개요

- **목적**: 랜딩의 “시작하기” 이후, 휴대전화번호와 사용자가 직접 보낸 SMS를 통한 OCTOMO 확인으로 앱 사용자를 로그인 또는 회원가입시킨다.
- **대상**: Flutter 앱의 첫 시작·비로그인 사용자. 완료 후 온보딩(`/intro`)으로 진입한다.
- **관련 문서**: [화면 색인](./00-index.md), Flutter `docs/api-spec.md`, NestJS `docs/server-feature-definition.md`, `docs/server-architecture.md`.
- **중요한 인증 경계**: OCTOMO는 인증문자를 발송하는 API가 아니다. 사용자가 지정된 수신번호로 보낸 특정 문자 원문(예: `3538`)의 수신 여부를 조회하는 API다. OCTOMO API Key는 **Flutter에 절대 포함하지 않고 NestJS 서버만** 보관·호출한다.

현재 앱은 전화번호 OTP 스텁(`482915`) 및 카카오 진입 화면을 제공한다. 이 문서의 OCTOMO 기반 로그인·회원가입·약관 흐름은 신규 요구사항이며, 기존 OTP 계약을 그대로 대체하는 것으로 확정하지 않는다.

## 2. 유저 플로우

### 로그인 및 기존 사용자

1. 앱 랜딩의 **“시작하기”** → `/login`.
2. 전화번호 입력 화면에서 번호를 숫자만으로 입력한다. 선택적으로 연락처 접근 권한을 요청하여 연락처에서 번호를 선택·가져올 수 있다.
3. 앱은 정규화한 번호로 서버에 기존 사용자 후보를 조회한다. 이 단계의 응답은 가입 여부를 과도하게 노출하지 않도록 화면상 “인증을 진행해 주세요”로 동일하게 안내한다.
4. 서버가 안내 문구, OCTOMO 수신번호, 인증용 `text`(고정값 또는 서버 발급값), 만료·재확인 정보를 내려준다.
5. 사용자는 자신의 메시지 앱에서 지정된 수신번호로 `text`를 **직접 전송**한다.
6. 앱은 서버에 확인을 폴링한다. 서버만 OCTOMO `POST /octomo/v1/public/message/exists`를 호출해 `{ exists: boolean }`을 확인한다.
7. 인증 성공 시 기존 사용자는 세션(JWT access/refresh)을 받고, `needs_intro`에 따라 `/intro` 또는 `/home`으로 간다.

### 신규 회원가입

1. 첫 시작 또는 비로그인 상태에서 전화번호 조회 결과 기존 사용자가 없으면 회원가입으로 이동한다.
2. 이름과 전화번호를 입력한다.
3. 위 OCTOMO SMS 전송·서버 폴링 확인을 완료한다.
4. 약관 동의 화면을 표시한다.
   - 제목: **“이용약관을 확인해 주세요”**
   - 보조: **“라이프로그는 선생님의 소중한 기억을 안전하게 보호합니다.”**
   - **“모두 동의합니다”**
   - 서비스 이용약관 (필수)
   - 개인정보 처리방침 (필수)
   - 만 14세 이상입니다 (필수)
   - 마케팅 정보 수신 (선택)
   - 버튼: **“동의하고 시작하기”**
5. 필수 약관이 모두 동의되면 서버가 사용자·동의 이력을 원자적으로 생성하고 세션을 발급한다.
6. 성공 화면 **“회원가입 성공!”** → **“자서전 작성하러 가기”** 버튼 → `/intro`.

### 보조 경로

- 로그인 하단에 **“ID, PW로 로그인하기”**를 둔다. 현재 앱 범위에서는 준비 중 안내만 제공한다. 웹 로그인으로 연결할지는 열린 이슈다.
- 기존 카카오 진입은 현재 서버·앱 모두 스텁이므로 OCTOMO 흐름과 별도로 유지 여부를 결정해야 한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 랜딩→로그인 | 신규 랜딩의 시작하기가 `/login`으로 진입 | 신규 |
| 전화번호 입력 | 앱 자체 숫자 키패드, 숫자만 11자리·표시용 하이픈 형식 | 기존 |
| 연락처 번호 가져오기 | 연락처 권한 후 연락처에서 번호를 선택해 입력값에 반영 | 신규 |
| OCTOMO SMS 확인 | 안내된 문자값을 사용자가 전송하고 서버가 수신 여부를 조회 | 신규 |
| 서버 측 비밀 관리 | `Authorization: Octomo {API_KEY}`는 NestJS 환경변수/시크릿에만 보관 | 신규 |
| 기존 사용자 로그인 | 인증 완료 후 세션 발급, `needs_intro`로 다음 화면 분기 | 부분 |
| 신규 회원가입 | 이름+번호, SMS 확인, 약관 동의 후 최종 사용자 생성 | 신규 |
| 약관 동의 이력 | 필수/선택별 버전·동의시각·철회 이력을 보존 | 신규 |
| ID/PW 진입 | 앱은 준비 중 안내; 실제 인증·웹 연결은 미결정 | 신규 |
| 기존 SMS OTP | `phone/code`·`phone/verify`, 고정 코드 스텁 | 기존(교체/병행 설계 필요) |

## 4. 화면 구성

| 화면 | 주요 섹션 | 기존 Flutter 대응 |
|---|---|---|
| 앱 랜딩 | “시작하기” CTA → `/login` | 랜딩 문서 범위의 신규 화면 |
| 로그인 | 전화번호 입력, 연락처에서 가져오기, SMS 전송 안내, 하단 “ID, PW로 로그인하기” | `/login`, `/login/phone`, `/login/code`는 부분 대응 |
| SMS 안내/확인 | 수신번호, 전송할 `text`, 복사·메시지 앱 열기 안내, “확인 중/다시 확인”·만료 상태 | 신규 |
| 회원가입 정보 | 이름, 전화번호, 인증 상태 | 신규 |
| 약관 동의 | 필수·선택 체크, 전체 동의, 약관 원문 링크, CTA | 신규 |
| 가입 성공 | “회원가입 성공!”, “자서전 작성하러 가기” → `/intro` | 신규 |

접근성·오류 처리: 권한 거부는 번호 직접 입력을 유지하고, SMS 미전송·미수신·만료·네트워크 오류는 재안내/재확인 UI를 제공한다. 전화번호나 인증 결과를 로그·토스트에 과도하게 노출하지 않는다.

## 5. API 엔드포인트 (NestJS)

앱 공개 API 기본 경로는 `/v1`이다. 아래 `신규` 계약은 DTO 상세가 아니라 필요한 경계·목적을 정리한 것이다.

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| POST | `/v1/auth/phone/lookup` | 정규화 번호로 기존 사용자 후보/가입 필요 상태를 판단하는 사전 단계 | 신규 |
| POST | `/v1/auth/octomo/challenge` | SMS 수신번호·`text`·만료·폴링 정보를 발급/반환. `text`는 서버 발급 또는 정책상 고정 | 신규 |
| POST | `/v1/auth/octomo/verify` | 인증 세션을 기준으로 서버가 OCTOMO 조회 후 인증 상태 반환; 성공 시 기존 사용자 세션 발급 또는 가입 진행 상태 반환 | 신규 |
| POST | `/v1/auth/signup` | 이름·인증 완료 세션·필수/선택 동의 버전을 검증하고 사용자/동의 이력을 트랜잭션 생성 | 신규 |
| POST | `/v1/auth/refresh` | refresh token 회전 | 기존 |
| POST | `/v1/auth/logout` | 해당 사용자의 refresh token 폐기 | 기존 |
| GET | `/v1/users/me` | 로그인 사용자 조회 | 기존 |
| POST | `/v1/auth/phone/code` | 기존 서버 OTP 발송 요청 | 기존 스텁 |
| POST | `/v1/auth/phone/verify` | 기존 OTP 확인 및 번호 단독 사용자 생성 | 기존 스텁·새 정책과 충돌 |

### OCTOMO 서버 연동 흐름

1. NestJS가 내부 인증 세션의 `mobileNum`, `text`, 만료를 검증한다.
2. NestJS에서만 다음 요청을 보낸다.

   `POST https://api.octoverse.kr/octomo/v1/public/message/exists`

   - Headers: `Authorization: Octomo {API_KEY}`, `Content-Type: application/json`, `Accept: application/json`
   - Body: `mobileNum`(필수), `text`(필수; 사용자가 전송한 인증문자 원문값, 예: `3538`), `withinMinutes`(선택, 기본 5)
   - 성공 응답: `201 { "exists": boolean }`

3. `exists: true`일 때만 인증 세션을 `verified`로 전이한다. 클라이언트가 OCTOMO 결과나 API Key를 위조할 수 없게 한다.
4. 문자 전송 자체는 사용자의 메시지 앱에서 일어난다. 기존 OTP처럼 서버가 인증번호를 발송하고 사용자가 숫자를 앱에 다시 입력하는 방식이 아니다.

## 6. 데이터 모델

| 테이블/모델 | 주요 역할 | 상태 |
|---|---|---|
| `app_user` | 앱 사용자. 현행은 `phone` 단독 유니크·`name` 빈값 허용 | 기존, 정책 변경 필요 |
| `phone_verification` | 현행 OTP 코드 해시·만료·시도횟수 | 기존, OCTOMO와 별도 |
| `refresh_token` | refresh token 해시와 회전 | 기존 |
| `auth_verification_session` | 정규화 번호, 목적(login/signup), 서버 발급 `text`, 만료, OCTOMO 확인 시각/횟수, 소비 시각 | 신규 |
| `user_consent` | `user_id`, 동의 항목, 문서 버전, 동의시각, 철회시각, 수집 경로(app), 선택값 | 신규 |
| `consent_document` 또는 배포된 약관 버전 레지스트리 | 이용약관·개인정보 처리방침 등 버전과 공개 URL/시행일 | 신규 권장 |

계정 식별은 **`normalized_phone` 단독 유니크**를 유지한다. `(name, phone)` 복합 유니크는 이름만 바꾸면 같은 번호로 계정을 무한히 만들 수 있으므로 채택하지 않았다. 한 번호에 여러 사람이 붙는 상황은 가족 공유(`book_participant`)로 푸는 것이 맞다.

동시 가입은 이름+번호 기준 조건부 insert 또는 유니크 제약 처리로 한 트랜잭션에서 해결한다. 동일한 인증 세션을 재사용하거나 두 요청이 동시에 도착해도 사용자·동의 이력이 중복 생성되지 않게 인증 세션 소비 상태를 원자적으로 갱신한다.

## 7. 기존 코드 참고

### Flutter

- `lib/feature/splash/splash_controller.dart` — 세션·`Storage.introDone`으로 로그인/intro/home 분기
- `lib/feature/login/login_view.dart`, `phone_view.dart`, `code_view.dart`, `login_controller.dart` — 기존 로그인, 전화번호·코드 입력 및 타이머
- `lib/core/route/app_routes.dart`, `app_pages.dart` — `/login`, `/login/phone`, `/login/code`, `/intro` 라우트
- `lib/core/network/api_client.dart` — 인증 API 추상 경계
- `lib/core/network/mock_api_client.dart` — `482915` OTP 목업
- `lib/core/network/real_api_client.dart`, `auth_interceptor.dart` — 실제 `/auth/*` 요청, Bearer·갱신 재시도
- `lib/data/models/user.dart`, `lib/data/storage.dart`, `lib/service/auth_service.dart` — 세션 모델, 토큰 저장, 복구/분기

### NestJS

- `server/src/auth/auth.controller.ts` — 현행 `/auth/phone/code`, `/auth/phone/verify`, refresh/logout
- `server/src/auth/services/auth.service.ts` — 번호 단독 조회/생성 및 JWT 발급
- `server/src/auth/services/sms.service.ts` — 현재 SMS 발송 스텁
- `server/src/auth/entities/phone-verification.entity.ts` — OTP 해시/만료 모델
- `server/src/auth/dto/request/request-code.dto.ts`, `verify-code.dto.ts` — 현행 번호·6자리 OTP 입력 계약
- `server/src/auth/const/token.const.ts`, `server/src/common/exception/error-code.const.ts` — 만료·재시도 및 오류 코드 기준
- `server/src/users/entities/app-user.entity.ts`, `repositories/app-user.repository.ts` — 현행 번호 단독 유니크와 조회
- `server/src/users/users.controller.ts`, `services/users.service.ts` — `/users/me`
- `server/src/main.ts`, `server/src/app.module.ts` — `/v1` prefix, 검증 파이프, 모듈 등록

## 8. 신규 개발 범위 요약

1. Flutter 랜딩→로그인 연결, 연락처에서 번호 선택, OCTOMO SMS 안내·폴링·오류 UI, 이름 입력·약관·성공 화면을 추가한다.
2. NestJS에 OCTOMO 전용 서버 어댑터와 비밀 환경변수, 인증 세션·조회/확인/가입 API, 레이트 리밋·감사 로그를 추가한다.
3. 현행 번호 단독 OTP 생성 흐름을 `normalized_phone` 단독 유니크 정책에 맞게 재설계하고, 사용자·약관 동의 이력을 원자적으로 저장한다.
4. 앱 토큰은 현행 `GetStorage` 평문이므로 `flutter_secure_storage` 전환을 함께 우선 검토한다.

## 9. 열린 이슈 / 가정

1. **기기 전화번호 자동 감지**: 연락처 권한은 연락처에서 번호를 선택/가져오는 데 적합할 뿐, 현재 단말의 회선 전화번호를 안정적으로 읽게 하지 않는다. Android/iOS 모두 플랫폼·통신사·권한 제약 때문에 직접 조회를 보장할 수 없다. 연락처 선택을 기본 대안으로 하고, Android SIM/전화번호 힌트 등은 기기·통신사별 지원을 별도 검증한 뒤 채택한다.
2. **OCTOMO 프로토콜**: 수신번호, `text`의 고정/서버발급 여부, 재사용 방지, 안내 딥링크/복사 UX, 폴링 주기·최대 시도·만료 및 비용/레이트리밋을 OCTOMO 계약과 함께 확정해야 한다.
3. **OCTOMO 보안**: API Key는 Flutter·로그·분석 도구에 노출하지 않고 NestJS 시크릿에만 둔다. 서버가 전화번호·인증 세션 소유·만료를 검증한 뒤에만 외부 조회해야 한다.
4. **[결정 완료] 동일 번호 중복 정책**: `normalized_phone` 단독 유니크를 유지한다. `(name, phone)` 복합 유니크는 채택하지 않았다. 가족 공유는 `book_participant`로 해결한다.
5. **[결정 완료] 기존 사용자 이관 불필요**: 번호 단독 unique를 유지하므로, 기존 사용자에 대한 이관 작업이 필요하지 않다. 빈 이름 사용자는 회원가입 단계의 이름 입력으로 보완한다.
6. **기존 OTP·카카오**: 현행 `phone/code`, `phone/verify`, 카카오 스텁을 폐기·병행·대체할 범위와 출시 전환 시점을 정해야 한다.
7. **ID/PW 경로**: 앱의 “ID, PW로 로그인하기”를 준비 중 안내로 둘지, Next.js 웹 로그인으로 안전하게 연결할지 및 계정 연결 정책은 미정이다.
8. **약관 운영**: 각 필수 문서의 실제 URL, 버전 발행·재동의 규칙, 마케팅 동의 철회 UI/보존 기간을 확정해야 한다.
9. **세션 저장소**: refresh token을 현재 평문 `GetStorage`에서 보안 저장소로 옮기는 일정이 필요하다.
