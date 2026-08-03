# LifeLegacy 앱 개발가이드 — QnA · FAQ · 설정 (07~09)

- **작성 기준일**: 2026-08-02
- **대상**: Flutter 앱 + NestJS 서버 (`/Users/ck1044/Projects/life-legacy-flutter`)
- **목적**: 앱 지원 경험(QnA·FAQ)과 현재 설정 기능의 As-Is를 확인하고, Flutter/NestJS 구현 착수 범위를 정리한다.
- **비범위**: Next.js 웹 화면의 재설계·개발 가이드, 6-1-4 `book/[id]/bookcard` 개발. 웹 코드는 아래 As-Is의 참고 근거로만 사용한다.
- **상태 표기**: **기존**(Flutter+NestJS에서 동작) · **부분**(일부 코드·모델만 존재) · **신규**(설계·구현 필요)

## 1. 개요 및 범위

| 화면 | 앱 경로 | Flutter/NestJS 상태 | 이번 가이드 범위 |
|---|---|---|---|
| 7. QnA | 없음 | **신규** | 인증 사용자 문의 작성·내 문의 조회, 관리자 답변·게시 관리 |
| 8. FAQ | 없음 | **신규** | 공개 FAQ 조회와 QnA 공개 게시물을 구분한 지원 화면 |
| 9. 설정 | `/settings`, `/settings/profile`, `/settings/address` | **부분** | 구현된 프로필 조회·배송지·오늘의 질문 알림·로그아웃을 정확히 유지하고 누락 정책을 식별 |

Flutter 라우트(`lib/core/route/app_routes.dart`, `app_pages.dart`)에는 설정·알림만 등록되어 있으며 QnA/FAQ 라우트·뷰·컨트롤러는 없다. NestJS `server/src` 전체에도 QnA/FAQ 모듈·엔티티·컨트롤러가 없다. 따라서 QnA/FAQ는 웹 기능을 그대로 이식했다고 보지 않고 신규 도메인으로 설계한다.

## 2. 공통 사용자 플로우 및 네비게이션

```text
하단 탭 설정(/settings)
 ├─ 내 정보(/settings/profile) → 조회만
 ├─ 인쇄본 배송지(/settings/address) → 조회·저장
 ├─ 오늘의 질문 알림 → 설정 토글 저장
 ├─ FAQ (신규 진입) → 공개 FAQ / 게시 QnA 조회
 ├─ QnA (신규 진입) → 문의 작성 / 내 문의 조회
 ├─ 이용약관·개인정보 처리방침 → 현재 준비 중 토스트
 └─ 로그아웃 → 확인 → 세션 삭제 → 스플래시
```

- 현재 `TabScaffold`의 4개 탭은 홈·작성·자서전·설정이며, 설정은 독립 라우트다. QnA/FAQ의 최종 진입 위치(설정 내 목록, 홈 등)는 미정이므로 신규 기획 결정이 필요하다.
- 알림 센터(`/notifications`)는 홈의 “전체 보기”에서 진입하는 별도 화면이다. 설정의 `daily_question_alarm`은 알림 목록 조회·읽음 처리와 다른 사용자 선호값이다.
- 앱은 `ApiEnv.useMock` 기본값에서 `MockApiClient`, `--dart-define=USE_MOCK=false`에서 `RealApiClient`와 NestJS를 사용한다. 신규 지원 API는 `ApiClient` 인터페이스·실제/목업 구현을 함께 맞춰야 한다.

## 3. QnA

### 3.1 유저 플로우

1. 사용자는 로그인 후 QnA에 진입한다.
2. 카테고리(선택)와 문의 본문을 입력해 등록한다.
3. 본인 문의 목록에서 접수·답변·종료·게시 상태와 관리자 답변을 확인한다.
4. 관리자는 별도 관리자 권한으로 문의를 조회하고 답변·상태·공개 게시 여부를 관리한다.
5. 공개 처리된 항목만 비로그인 사용자도 FAQ 화면의 “게시 QnA”에서 조회한다.

### 3.2 핵심 기능 및 화면 구성

| 기능 | 상태 | Flutter 화면 구성 / 처리 |
|---|---|---|
| 문의 작성 | **신규** | 카테고리 선택, 다중 행 본문, 입력 검증, 등록·오류 상태 |
| 내 문의 조회 | **신규** | 상태 배지, 작성일, 질문, 답변을 본인 데이터만 표시 |
| 관리자 답변·상태 변경 | **신규** | 앱 사용자 화면이 아닌 관리자 API/운영 UI 범위 |
| 공개 게시 QnA 조회 | **신규** | FAQ와 구분된 접기/펼치기 목록, 공개 데이터만 노출 |
| 음성 문의 입력 | **신규/미결정** | 웹에는 STT 입력이 있으나 앱 QnA에 적용할 확정 요구는 없다. 기본 범위에 포함하지 않는다. |

### 3.3 NestJS API 및 데이터 모델

| Method | Path (제안) | 설명 | 상태 |
|---|---|---|---|
| `POST` | `/qna` | 로그인 사용자의 문의 등록 | **신규** |
| `GET` | `/qna/me` | 로그인 사용자의 문의 목록 | **신규** |
| `GET` | `/qna/published` | 공개 게시 QnA 목록, 인증 불필요 | **신규** |
| `GET` | `/admin/qna` | 관리자 문의 목록·상태·검색 | **신규** |
| `PATCH` | `/admin/qna/:id` | 관리자 답변, 상태, 공개 여부 변경 | **신규** |

신규 `qna_question` 모델은 최소한 다음 책임을 분리한다.

| 필드군 | 내용 |
|---|---|
| 소유·본문 | `id`, `user_id`, `question`, 선택 `category`, 생성·수정 시각 |
| 처리 상태 | `pending`, `answered`, `published`, `closed` |
| 답변 | `answer`, `answered_by`, `answered_at`, 내부용 `admin_note` |
| 공개 | `published_at`; `published` 상태이고 답변이 있는 행만 공개 API에서 반환 |

문의 본문·관리자 메모·사용자 연락처를 공개 응답에 포함하지 않는다. 관리자 목록도 운영에 필요한 최소 식별 정보만 반환한다.

### 3.4 기존 코드 참고

- Flutter 부재 확인: `lib/core/route/app_routes.dart`, `lib/core/route/app_pages.dart`, `lib/feature/**`에 QnA/FAQ 라우트·UI 없음.
- NestJS 부재 확인: `server/src`에 `qna`·`faq` 도메인 모듈·엔티티·컨트롤러 없음.
- 웹 As-Is 참고:
  - `app/app/faq/page.tsx`, `app/components/faq/FaqQnaClient.tsx`: 정적 FAQ, 문의 등록, 내 문의, 게시 QnA를 한 화면의 탭으로 제공.
  - `app/app/api/qna/route.ts`, `app/app/api/qna/published/route.ts`: 로그인 사용자 문의와 공개 게시 목록을 분리.
  - `app/app/api/admin/qna/**`, `app/lib/qna.ts`, `app/lib/db/schema.ts`: 관리자의 답변·게시 상태와 `qna_question` 데이터 구조.
- 제품 기능 근거: `docs/01-현재-기능정의.md`의 MKT-03(FAQ·QnA), ADM-08(QnA 관리).

### 3.5 신규 범위와 열린 이슈

- NestJS 관리자 권한 모델·운영 UI 위치가 현재 서버에 없으므로, 관리자 인증/권한 정책을 먼저 확정해야 한다.
- 문의 수정·삭제·첨부·이메일/푸시 답변 알림·SLA는 기존 구현에 근거가 없어 이번 범위에 포함하지 않는다.
- 공개 FAQ와 사용자 문의에서 공개된 QnA는 별도 데이터 원천·API·UI 섹션으로 유지한다.

## 4. FAQ

### 4.1 유저 플로우

1. 사용자는 로그인 여부와 무관하게 FAQ에 진입한다.
2. 카테고리별 정적 FAQ를 탐색한다.
3. 도움되는 공개 QnA를 별도 목록에서 확인한다.
4. 답을 찾지 못한 로그인 사용자는 QnA 문의 작성으로 이동한다.

### 4.2 핵심 기능 및 화면 구성

| 기능 | 상태 | Flutter 화면 구성 / 처리 |
|---|---|---|
| 카테고리 FAQ | **신규** | 카테고리 필터와 질문·답변 펼침 목록 |
| 게시 QnA 조회 | **신규** | `published` 상태·답변 존재 항목만 조회 |
| 문의 전환 CTA | **신규** | 미로그인 시 로그인 유도, 로그인 시 QnA 작성 진입 |
| 서버 기반 FAQ CMS | **신규/미결정** | 기존 웹 FAQ는 정적 콘텐츠이므로 이번 범위에서 새 CMS를 전제하지 않음 |

### 4.3 API 및 데이터 모델

| Method | Path (제안) | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/faq` 또는 앱 번들 콘텐츠 | 정적 FAQ 카테고리·문항·답변 | **신규/결정 필요** |
| `GET` | `/qna/published` | 게시 QnA 목록 | **신규** |

- 현 웹 FAQ는 `app/content/faq.ts`의 정적 콘텐츠이며, `FAQ_CATEGORIES`는 시작·가입/자기소개·목차/작성·전송·저장/음성 입력/나의 자서전/미리보기·내보내기/계정·설정/기타다.
- 따라서 Flutter 1차는 동일한 검수된 정적 콘텐츠를 앱 자산 또는 서버 읽기 전용 응답으로 제공하는 정도가 적절하다. 운영자가 FAQ를 편집해야 한다는 요구가 확정되기 전에는 FAQ 테이블·관리 CMS를 추가하지 않는다.

### 4.4 기존 코드 참고

- Flutter/NestJS: FAQ 화면·라우트·API·모델 없음.
- 웹 참고: `app/content/faq.ts`, `app/components/faq/FaqQnaClient.tsx`, `app/lib/qna-constants.ts`.
- 웹 화면은 FAQ와 QnA를 한 탭 화면으로 섞어 노출하지만, 앱 가이드에서는 정적 FAQ·공개 QnA·개인 문의를 데이터와 권한 기준으로 구분한다.

### 4.5 신규 범위와 열린 이슈

- FAQ 콘텐츠의 앱 전달 방식(번들 정적 데이터 또는 NestJS 읽기 API), 콘텐츠 소유자와 배포 절차를 결정해야 한다.
- 검색·첨부 안내·챗봇·FAQ 관리자 편집은 기존 근거가 없어 신규 요구가 생길 때 별도 범위로 다룬다.

## 5. 설정

### 5.1 유저 플로우

1. 하단 설정 탭(`/settings`)에서 로그인 사용자·설정을 로드한다.
2. 프로필 카드를 누르면 `/settings/profile`에서 이름·전화번호·배송지·자기소개를 **조회**한다.
3. “인쇄본 배송지”에서 `/settings/address`로 이동해 수령인·연락처·우편번호·기본/상세 주소를 저장한다.
4. “오늘의 질문 알림”을 토글하면 낙관적으로 반영한 뒤 `PATCH /settings`로 저장하며 실패 시 복원·오류 토스트를 보인다.
5. 로그아웃 확인 후 토큰·온보딩 플래그를 삭제하고 스플래시로 이동한다.

### 5.2 핵심 기능 및 화면 구성

| 기능 | 상태 | 실제 구현 |
|---|---|---|
| 프로필 카드·내 정보 조회 | **기존** | `settings_view.dart`, `profile_view.dart`; 이름·전화번호·배송지·자기소개는 보기 전용 |
| 배송지 조회·저장 | **기존** | `address_view.dart`, `address_controller.dart`; 수령인·전화번호·우편번호·기본/상세 주소 |
| 우편번호 검색 | **부분** | “주소 찾기” 버튼은 준비 중 토스트만 표시; 외부 주소 검색 SDK 미연결 |
| 오늘의 질문 알림 선호 | **기존** | `daily_question_alarm` 단일 boolean, 토글 낙관적 저장 |
| 이용약관·개인정보 처리방침 | **부분** | 목록은 보이나 준비 중 토스트만 표시하며 실제 문서 라우트 없음 |
| 로그아웃 | **기존** | 확인 다이얼로그 → `AuthService.logout()` → `/` |
| 이름·전화번호·자기소개 수정 | **신규** | 현 프로필은 조회 전용이며 배송지만 수정 가능 |
| 비밀번호 변경 | **비대상/신규 아님** | 앱 인증은 전화번호 SMS·카카오 기반이며 비밀번호 필드가 없음 |
| 회원 탈퇴 | **신규** | `deleted_at` 컬럼만 있고 API·앱 UI·보존/파기 실행 흐름 없음 |

공통 디자인 시스템은 `lib/common/widgets/ds/app_setting_row.dart`(설정 섹션·그룹·행·스위치·프로필 카드), `app_field.dart`(입력·오류), `app_notice_box.dart`(지속 오류 안내)를 사용한다.

### 5.3 NestJS API 및 데이터 모델

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/settings` | `daily_question_alarm` 조회. 행이 없으면 `true` | **기존** |
| `PATCH` | `/settings` | `daily_question_alarm` 저장/upsert | **기존** |
| `GET` | `/shipping-address` | 미등록 시 빈 문자열 필드 객체 반환 | **기존** |
| `PUT` | `/shipping-address` | 배송지 저장/upsert | **기존** |
| `GET` | `/users/me` | 로그인 사용자 기본 정보 조회 | **기존** |
| `POST` | `/auth/logout` | 서버 세션/리프레시 토큰 무효화 | **기존** |
| `DELETE` 또는 `POST` | `/users/me/withdrawal` | 탈퇴 요청·인증·보존/파기 처리 | **신규** |

| 모델 | 실제 필드·책임 | 상태 |
|---|---|---|
| `app_user` | 전화번호(선택), 이름, `child_linked`, `intro_completed_at`, `last_login_at`, `deleted_at` | **기존** |
| `user_setting` | 사용자별 `daily_question_alarm` (기본 `true`) | **기존** |
| `shipping_address` | `user_id`, `recipient`, 숫자만 저장하는 `phone`, `postal_code`, `line1`, `line2` | **기존** |
| `device_push_token` | 사용자·플랫폼·고유 토큰 모델만 존재 | **부분** |
| `notification` | 인앱 알림 유형·제목·연결 질문·읽음 시각 | **기존** |

### 5.4 기존 코드 참고

- Flutter 화면·상태·바인딩: `lib/feature/settings/{settings,profile,address}_{view,controller}.dart`, `binding.dart`
- Flutter 네트워크·보안 저장소: `lib/core/network/{api_client,real_api_client,mock_api_client}.dart`, `lib/data/storage.dart`, `lib/main.dart`
  - 실제 API는 `USE_MOCK=false`일 때만 사용한다.
  - `Storage`는 access/refresh token을 현재 평문 `GetStorage`에 저장하므로 보안 저장소 전환이 필요한 기존 위험이다.
- Flutter 알림과의 구분: `lib/feature/notifications/**`, `lib/data/models/notification.dart`
- NestJS: `server/src/settings/**`, `server/src/users/entities/{app-user,user-setting,shipping-address,device-push-token}.entity.ts`, `server/src/users/**`, `server/src/notifications/**`
- 웹 참고만: `app/app/(dashboard)/settings/page.tsx`, `app/app/api/account/**`, `docs/01-현재-기능정의.md` AUTH-03. 웹은 이메일·비밀번호·글꼴·AI 쓰기 설정 등 다른 인증/설정 모델이므로 앱의 구현 범위로 전파하지 않는다.

### 5.5 알림과 개인정보 주의사항

- `daily_question_alarm`은 선호값 저장일 뿐이다. 현재 서버에는 `device_push_token` 엔티티만 있으며 토큰 등록 API, Firebase/APNs 등 provider 연동, scheduler/cron 발송 로직은 확인되지 않았다. 토글 ON을 실제 푸시 수신 보장으로 표현하면 안 된다.
- 인앱 알림은 `GET /notifications`, `POST /notifications/read-all`로 목록·일괄 읽음을 제공한다. 현재 알림 탭 시 딥링크는 “준비 중” 토스트이며, 30일 보관 문구와 실제 삭제 작업의 연결은 확인되지 않았다.
- 배송지와 전화번호는 자서전 서비스의 민감 개인정보다. 로그·분석·공개 QnA 응답에 원문을 포함하지 않고, 사용자 소유권을 서버 `userId`로 강제한다. 화면에서는 필요한 마지막 값만 표시하며 수정·조회 API 응답도 최소화한다.
- 탈퇴는 `app_user.deleted_at` 모델 의도만 있고 실제 API·재인증·연관 데이터 보존 기간·파기 배치가 없다. 개인정보 처리방침 화면도 아직 연결되지 않았다.

## 6. 공통 NestJS/Flutter 아키텍처·권한

- 인증 필요 API는 `@UseGuards(AccessTokenGuard)`와 `@UserId()`를 사용한다. guard는 `Authorization: Bearer` JWT의 `sub`를 요청 사용자 ID로 설정한다.
- 사용자 소유 리소스는 URL이나 본문 사용자 ID를 신뢰하지 않고 인증된 `userId` 조건으로 조회·갱신한다. QnA의 내 문의, 설정, 배송지, 알림 모두 같은 원칙을 적용한다.
- NestJS 오류는 전역 `HttpExceptionFilter`가 최상위 `{ code, message }`로 정규화한다. Flutter `RealApiClient`는 이를 `ApiException`으로 변환하고 컨트롤러는 사용자용 토스트로 표시한다.
- Flutter 컨트롤러는 `ApiClient` 추상화에 의존한다. QnA/FAQ 추가 시 실제 구현과 목업 구현을 동시에 제공해 화면 테스트와 API 계약 검증이 분리되도록 한다.

## 7. 통합 신규 개발 범위와 열린 이슈 요약

| 영역 | 확정된 신규 개발 | 먼저 결정할 열린 이슈 |
|---|---|---|
| QnA | Flutter 라우트·UI·컨트롤러, NestJS QnA 모델/API, 관리자 답변·공개 상태 | 관리자 인증/운영 UI, 진입 위치, 문의 수정·삭제·첨부·답변 알림 |
| FAQ | Flutter FAQ·게시 QnA 조회, 로그인 기반 문의 전환 | 정적 번들/서버 API 전달 방식, 콘텐츠 담당·갱신 절차 |
| 설정 | 탈퇴·약관/개인정보 처리방침 실제 연결은 신규 후보 | 탈퇴 재인증, 보존·파기 정책, 주소 검색 SDK, 토큰 보안 저장소 |
| 알림 연결 | 없음(현재 토글·인앱 알림 유지) | push token 등록, provider, scheduler, 수신 권한·실제 발송 정책 |

이번 문서는 현재 코드에 확인된 기능만 As-Is로 기록했다. QnA/FAQ 또는 설정의 정책·상세 UI가 새로 확정되면 그 결정에 맞춰 별도 구현 범위를 갱신한다.
