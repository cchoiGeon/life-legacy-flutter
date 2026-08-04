# LifeLegacy API 명세

앱(Flutter) 기준 서버 계약.

- 대상 클라이언트: Flutter 앱 1종 (웹 `lifelegacy-web`은 별도 서비스, 이 명세의 대상 아님)
- 데이터 모델: [`../erd/new-erd.dbml`](../erd/new-erd.dbml)
- 화면별 요구사항: [`screens/`](screens/) — 앱 문서가 기준, 웹 문서는 참고
- 케이스 판정: [`목차-케이스.md`](목차-케이스.md)

## 상태 표기

모든 엔드포인트 제목 옆에 붙는다.

| 표기 | 뜻 |
|------|-----|
| `[기존]` | v1 서버에 구현되어 있고 계약이 그대로다 (`server/src`) |
| `[변경]` | v1에 있으나 요청·응답이 바뀐다 |
| `[신규]` | v1에 없다 |

**수록 기준** — `screens/`가 "신규·변경"으로 확정한 것만 계약으로 적었다.
"열린 이슈 / 미정 / 후보 / TODO"로 표시된 것은 각 절 끝의 **확정 대기** 블록에
모아 두었고 엔드포인트를 만들지 않았다. 미정을 계약으로 굳히면 앱이 그 위에
코드를 쓰고, 되돌리는 비용이 계약을 늦게 내는 비용보다 커진다.

**v1 범위 제외** — 관리자, 승인·결제·인쇄 발주, 인생 방향 케이스(`direction_*`),
가족 공유 참여자, 팩트 체크.

---

## 0. 공통 규약

### 0.1 기본

| 항목 | 값 |
|------|-----|
| Base URL | `https://api.lifelegacy.app/v1` |
| 형식 | JSON (UTF-8) |
| 필드 표기 | `snake_case` |
| 시각 | ISO 8601 UTC (`2026-07-31T09:00:00Z`) |
| 식별자 | 문자열 (UUID 권장). 앱의 모든 `id`는 `String`이다 |

### 0.2 인증 헤더

```http
Authorization: Bearer {access_token}
```

- 액세스 토큰: 1시간
- 리프레시 토큰: 60일, 응답 바디로 전달 (앱은 쿠키를 쓰지 않으므로 secure storage에 보관)

### 0.3 응답 형태

**성공 (단일)** — 리소스를 그대로 반환한다. 래퍼 없음.

```json
{ "id": "q_012", "order": 3, "text": "…" }
```

**성공 (목록)** — `items`로 감싼다. 지금은 전량 반환이지만 나중에 `next_cursor`를 붙일 자리를 남겨 둔다.

```json
{ "items": [ … ] }
```

**본문 없음** — `204 No Content`

**실패** — 상태 코드 + 아래 바디. 앱의 `ApiException(message, code)`에 그대로 대응한다.

```json
{ "code": "INVALID_CODE", "message": "인증번호가 일치하지 않아요" }
```

> `message`는 **사용자에게 그대로 보여줄 한국어 문장**이다. 앱은 이 문자열을 토스트에 바로 띄운다.
> 개발자용 상세는 `message`에 넣지 말고 로그로 남긴다.

### 0.4 에러 코드

| HTTP | code | 상황 |
|------|------|------|
| 400 | `INVALID_REQUEST` | 필수 파라미터 누락·형식 오류 |
| 401 | `UNAUTHORIZED` | 토큰 없음·유효하지 않음 |
| 401 | `TOKEN_EXPIRED` | 액세스 토큰 만료 → 앱이 리프레시 시도 |
| 401 | `INVALID_CODE` | 인증번호 불일치 (앱이 `code`로 분기해 입력칸을 빨갛게 표시) |
| 410 | `CODE_EXPIRED` | 인증번호 유효시간 초과 |
| 429 | `TOO_MANY_REQUESTS` | 인증번호 재발송·API 호출 제한 |
| 403 | `INTRO_REQUIRED` | 자기소개·목차 확정 전에 본문 API를 호출 |
| 404 | `NOT_FOUND` | 리소스 없음 |
| 409 | `CHAPTER_LOCKED` | 잠긴 장의 질문에 접근 |
| 409 | `ALREADY_ANSWERED` | 이미 확정 저장된 질문에 다시 답변 |
| 409 | `TOC_ALREADY_CONFIRMED` | 목차를 다시 확정 |
| 422 | `FOLLOWUP_FAILED` | AI 꼬리질문 생성 실패 → **처음부터 다시** (§5.3) |
| 422 | `POLISH_FAILED` | AI 윤문 실패 → **저장만 재시도** (§5.4) |
| 500 | `SERVER_ERROR` | 그 외 |

**신규 코드**

| HTTP | code | 상황 |
|------|------|------|
| 401 | `VERIFICATION_NOT_COMPLETED` | 인증 세션이 아직 `verified`가 아님 (§1.9·§1.10) |
| 410 | `VERIFICATION_EXPIRED` | 인증 세션 만료 → 새로 발급받아야 한다 |
| 409 | `CONSENT_REQUIRED` | 필수 약관 미동의 상태로 가입 시도 |
| 403 | `FORBIDDEN_BOOK` | 내 책이 아님 — **응답은 404로 내린다** (아래 주의) |
| 409 | `CHAPTER_NOT_REVIEWED` | 리뷰 저장 전 챕터로 산출물 생성·조회 시도 |
| 403 | `PLAN_REQUIRED` | 해당 기능의 entitlement 없음 |
| 429 | `QUOTA_EXCEEDED` | 기능별 제공 한도 소진 |
| 409 | `JOB_IN_PROGRESS` | 같은 챕터에 진행 중인 생성 작업이 있음 |
| 422 | `SYNTHESIZE_FAILED` | 챕터 종합 원고 생성 실패 |

> ⚠️ **남의 리소스는 403이 아니라 404다.** `FORBIDDEN_BOOK`은 서버 내부 로그용
> 구분이고, 클라이언트에는 `404 NOT_FOUND`로 나간다. 403을 주면 "그 id는 존재한다"를
> 알려주는 셈이다. v1 `ChaptersService.getOwnedQuestion`이 이미 이 방식이다.

### 0.5 호출 제한

| 대상 | 제한 |
|------|------|
| `POST /auth/phone/code` | 전화번호당 5회 / 1시간 |
| `POST /auth/octomo/challenge` | 전화번호당 5회 / 1시간 |
| `POST /auth/octomo/verify` (폴링) | 세션당 최대 시도 횟수 — 주기·상한은 §1 확정 대기 |
| `POST /questions/{id}/answer` (AI 호출) | 사용자당 60회 / 시간 |
| 생성 작업(`.../jobs`, `.../generate`) | entitlement 한도로 통제 (§12) |
| 그 외 | 사용자당 100회 / 10초 |

### 0.6 책 범위 경로

책에 딸린 리소스는 **`/books/{book_id}/…`만** 쓴다. (`erd/new-erd.dbml` 다권 계약)

```
/v1/books/{book_id}/chapters
/v1/books/{book_id}/questions/current
/v1/books/{book_id}/pages
/v1/books/{book_id}/chapters/{chapter_id}/review
```

**`book_id`를 신뢰하지 않는다.** `AccessTokenGuard`가 심은 사용자 ID로 소유 관계를
서버에서 매번 확인한다. URL의 값, 클라이언트가 들고 있는 플랜, 비활성화된 버튼은
권한 근거가 될 수 없다. 소유자가 아니면 `404 NOT_FOUND`(존재 여부 노출 방지).

> [2026-08-04] v1 단일 경로(`/book`, `/chapters`, `/questions/current`, `/book/pages`)는
> **제거한다.** "첫 책으로 해석"하는 전환 호환을 두지 않는다. 첫 책은
> `POST /intro/answers`가 만들고 반환한 `book_id`로만 접근한다.

---

## 1. 인증

### 1.1 인증번호 발송 `[기존]`

> v1 SMS OTP다. OCTOMO(§1.7~1.10)로 전환할지·병행할지는 §1 확정 대기 · 인증 전환.

```
POST /auth/phone/code
```

```json
{ "phone": "01012345678" }
```

**200**

```json
{
  "expires_in": 180,
  "resend_after": 30
}
```

| 필드 | 설명 |
|------|------|
| `expires_in` | 인증번호 유효 초. 앱 A6의 "2분 47초 남음" 타이머 |
| `resend_after` | "다시 받기"가 눌리기까지 대기 초 |

> ⚠️ 현재 앱은 `ApiClient.verificationCodeTtl`이라는 **클라이언트 상수**로 타이머를 돌린다.
> 이 응답이 들어오면 그 상수는 지운다 — 기기 시계가 틀어져도 서버 기준으로 맞는다.

**에러**: `400 INVALID_REQUEST` (11자리 숫자 아님), `429 TOO_MANY_REQUESTS`

### 1.2 인증번호 확인 (로그인/가입) `[기존]`

```
POST /auth/phone/verify
```

```json
{ "phone": "01012345678", "code": "123456" }
```

**200** — `AuthSession`

```json
{
  "access_token": "eyJ…",
  "refresh_token": "rt_…",
  "expires_in": 3600,
  "needs_intro": true,
  "user": {
    "id": "u_001",
    "name": "김영희",
    "phone": "01012345678",
    "child_linked": false
  }
}
```

| 필드 | 설명 |
|------|------|
| `needs_intro` | 자기소개·목차 확정을 아직 안 한 사용자면 `true`. **스플래시·로그인 후 분기의 유일한 근거** |
| `user.name` | 가입 직후에는 빈 문자열. 자기소개 i1에서 채워진다 |

가입과 로그인을 구분하지 않는다 — 없는 번호면 그 자리에서 계정을 만들고 `needs_intro: true`로 돌려준다.

**에러**: `401 INVALID_CODE`, `410 CODE_EXPIRED`

### 1.3 카카오 로그인 `[기존]`

```
POST /auth/kakao
```

```json
{ "kakao_access_token": "…" }
```

**200** — `AuthSession` (§1.2와 동일)

카카오 계정에 전화번호가 없으면 `needs_phone: true`를 함께 내려보내고, 앱은 전화번호 화면으로 보낸다.

> 📌 현재 앱은 카카오 SDK를 붙이지 않았다. `MockApiClient.loginWithKakao()`가 바로 세션을 돌려준다.

### 1.4 토큰 갱신 `[기존]`

```
POST /auth/refresh
```

```json
{ "refresh_token": "rt_…" }
```

**200**

```json
{ "access_token": "eyJ…", "refresh_token": "rt_…", "expires_in": 3600 }
```

리프레시 토큰은 매번 새로 발급한다(rotation). 이전 토큰은 즉시 폐기.

### 1.5 내 정보 `[기존]`

```
GET /users/me
```

**200** — `User` (§1.2의 `user`와 동일 형태)

### 1.6 로그아웃 `[기존]`

```
POST /auth/logout
```

**204**. 리프레시 토큰을 폐기한다.

---

### OCTOMO 인증 — 방향이 반대다

§1.1~1.2는 **서버가 문자를 보내고 사용자가 번호를 입력**한다.
§1.7~1.10은 **사용자가 문자를 보내고 서버가 수신 여부를 조회**한다.

```
POST /auth/phone/lookup      번호로 기존 사용자 후보를 판단
        │
        ▼
POST /auth/octomo/challenge  수신번호 + 보낼 문자(text) + 만료를 받는다
        │
        ▼  사용자가 자기 메시지 앱에서 수신번호로 text를 직접 보낸다
        │
POST /auth/octomo/verify     서버가 OCTOMO에 수신 여부를 묻는다 (앱은 폴링)
        │
        ├─ 기존 사용자 ─────▶ 세션 발급. 끝
        │
        ▼  신규 사용자
POST /auth/signup            이름 + 필수 약관 동의 → 계정 생성 + 세션 발급
```

**OCTOMO API Key는 서버만 갖는다.** Flutter 번들·로그·분석 도구 어디에도 넣지 않는다.
앱은 `exists` 결과를 직접 받지 못하고, 서버가 판정한 세션 상태만 본다 —
그래야 클라이언트가 인증 결과를 위조할 수 없다.

### 1.7 전화번호 조회 `[신규]`

```
POST /auth/phone/lookup
```

```json
{ "phone": "01012345678" }
```

**200**

```json
{ "next_step": "verify" }
```

| 필드 | 설명 |
|------|------|
| `next_step` | 항상 `verify`. 가입 여부와 무관하게 같은 값을 준다 |

> ⚠️ **가입 여부를 노출하지 않는다.** 응답을 `login`/`signup`으로 나누면 임의의 번호를
> 넣어 가입 여부를 캐낼 수 있다. 화면 문구도 양쪽 모두 "인증을 진행해 주세요"다.
> 실제 분기는 §1.9에서 인증이 끝난 뒤에 알려준다.

### 1.8 인증 문자 발급 `[신규]`

```
POST /auth/octomo/challenge
```

```json
{ "phone": "01012345678" }
```

**200**

```json
{
  "session_id": "avs_8f21",
  "receiver_number": "0503xxxxxxx",
  "verify_text": "3538",
  "expires_in": 300,
  "poll_interval": 3
}
```

| 필드 | 설명 |
|------|------|
| `receiver_number` | 사용자가 문자를 **보낼** 번호. 앱이 복사·메시지 앱 열기를 제공한다 |
| `verify_text` | 보낼 문자 원문 |
| `expires_in` | 세션 유효 초 |
| `poll_interval` | §1.9를 다시 부르기까지 권장 대기 초 |

**에러**: `400 INVALID_REQUEST`, `429 TOO_MANY_REQUESTS`

### 1.9 인증 확인 (폴링) `[신규]`

```
POST /auth/octomo/verify
```

```json
{ "session_id": "avs_8f21" }
```

**200 — 아직 안 옴**

```json
{ "status": "pending", "expires_in": 214 }
```

**200 — 기존 사용자**

```json
{
  "status": "verified",
  "account": "existing",
  "session": {
    "access_token": "eyJ…",
    "refresh_token": "rt_…",
    "expires_in": 3600,
    "needs_intro": false,
    "user": { "id": "u_001", "name": "김영희", "phone": "01012345678", "child_linked": false }
  }
}
```

**200 — 신규 사용자**

```json
{
  "status": "verified",
  "account": "new",
  "signup_token": "st_…",
  "required_consents": [
    { "key": "terms_of_service", "version": "1.0", "title": "서비스 이용약관", "url": "https://…", "required": true },
    { "key": "privacy_policy",   "version": "1.0", "title": "개인정보 처리방침", "url": "https://…", "required": true },
    { "key": "age_14",           "version": "1.0", "title": "만 14세 이상입니다", "url": null,      "required": true },
    { "key": "marketing",        "version": "1.0", "title": "마케팅 정보 수신",   "url": "https://…", "required": false }
  ]
}
```

`signup_token`은 §1.10에서만 쓰는 단기 토큰이다. 액세스 토큰이 아니다 —
아직 계정이 없다.

**에러**: `410 VERIFICATION_EXPIRED`, `404 NOT_FOUND`

### 1.10 회원가입 `[신규]`

```
POST /auth/signup
```

```json
{
  "signup_token": "st_…",
  "name": "김영희",
  "consents": [
    { "key": "terms_of_service", "version": "1.0", "agreed": true },
    { "key": "privacy_policy",   "version": "1.0", "agreed": true },
    { "key": "age_14",           "version": "1.0", "agreed": true },
    { "key": "marketing",        "version": "1.0", "agreed": false }
  ]
}
```

**200** — `AuthSession` (§1.2와 동일 형태, `needs_intro: true`)

서버가 한 트랜잭션에서 하는 일:

1. `signup_token`의 인증 세션이 `verified`이고 아직 소비되지 않았는지 확인
2. 필수 3종이 모두 `agreed: true`인지 확인
3. `app_user` 생성 — 식별은 **`normalized_phone` 단독 유니크**
4. `user_consent` 행들을 함께 기록
5. 인증 세션을 `consumed`로 원자 갱신
6. 세션 발급

**약관에 동의하지 않은 계정이 생겨서는 안 된다.** 사용자 생성과 동의 이력이
같은 트랜잭션인 이유다. 같은 세션으로 두 요청이 동시에 와도 5번의 원자 갱신이
중복 생성을 막는다.

> **v1에서 바뀌는 건 식별자가 아니라 생성 시점이다.** 번호 단독 유니크는 그대로 두고,
> "번호 인증되면 그 자리에서 생성"을 "이름 + 필수 약관 동의까지 받고 생성"으로 옮긴다.
> 화면 문서 02가 제안한 `(name, phone)` 복합 유니크는 채택하지 않았다 — 이름만 바꾸면
> 같은 번호로 계정을 무한히 만들 수 있다. 한 번호에 여러 사람이 붙는 요구는
> 가족 공유로 푼다 (§6 확정 대기 · 가족 공유).

**에러**: `401 VERIFICATION_NOT_COMPLETED`, `409 CONSENT_REQUIRED`, `410 VERIFICATION_EXPIRED`

### 1.11 약관 문서 `[신규]`

```
GET /consents/documents
```

인증 불필요. 현재 시행 중인 버전만 내려준다.

**200**

```json
{
  "items": [
    { "key": "terms_of_service", "version": "1.0", "title": "서비스 이용약관",
      "url": "https://…", "required": true, "effective_at": "2026-08-01T00:00:00Z" }
  ]
}
```

설정 화면의 "이용약관·개인정보 처리방침"이 지금 준비 중 토스트만 띄우는데,
이 응답의 `url`로 연결한다.

### 1.12 회원 탈퇴 `[신규]`

```
DELETE /users/me
```

```json
{ "reason": "…" }
```

**204**. `app_user.deleted_at`을 찍고 리프레시 토큰을 전부 폐기한다.

- 재인증을 요구할지, 연관 데이터 보존 기간과 파기 배치를 어떻게 둘지는 §1 확정 대기 · 탈퇴 처리
- 컬럼(`deleted_at`)은 v1부터 있었으나 이를 쓰는 API가 없었다

### 확정 대기 — 인증

1. **인증 전환.** `/auth/phone/code`·`/auth/phone/verify`를 폐기할지
   병행할지, 카카오 스텁을 존치할지, 전환 시점은 언제인지.
2. **OCTOMO 프로토콜 세부.** `verify_text`를 고정값으로 둘지 세션마다 발급할지,
   재사용 방지, 폴링 주기·최대 시도·비용·레이트리밋. 위 `poll_interval: 3`은
   자리를 잡아 둔 값이지 확정 수치가 아니다.
3. **탈퇴 처리.** 재인증 여부, 보존 기간, 파기 배치, 자서전 본문의 처리.
4. **약관 운영.** 실제 URL, 버전 발행·재동의 규칙, 마케팅 동의 철회 UI와 보존 기간.
5. **앱의 "ID, PW로 로그인하기".** 준비 중 안내로 둘지 웹 로그인으로 연결할지.
   연결한다면 인앱 브라우저·딥링크 후 세션 전달 방식.

---

## 2. 자기소개 → 목차

### 2.1 자기소개 문항 `[변경]`

```
GET /intro/questions
```

인증 필요. 순서대로 내려준다. **문항 수는 고정이 아니다** — v1은 5문항이었으나
생년월일·작성 계획이 들어오면서 늘어난다.

**200**

```json
{
  "items": [
    {
      "id": "i2", "order": 1,
      "text": "성별을\n알려주세요",
      "subtitle": null,
      "hint": null,
      "answer_type": "choice",
      "skippable": false,
      "choices": [
        { "id": "ch_m", "label": "남" },
        { "id": "ch_f", "label": "여" }
      ]
    },
    {
      "id": "i6", "order": 2,
      "text": "생년월일을\n알려주세요",
      "answer_type": "date",
      "skippable": false,
      "choices": []
    },
    {
      "id": "i3", "order": 3,
      "text": "결혼은\n하셨나요?",
      "answer_type": "choice",
      "skippable": true,
      "choices": [
        { "id": "ch_y", "label": "예" },
        { "id": "ch_n", "label": "아니오" }
      ]
    },
    {
      "id": "i5", "order": 5,
      "text": "학교는 어디까지\n다니셨나요?",
      "subtitle": "학창 시절 질문을 고를 때 써요",
      "answer_type": "choice",
      "skippable": false,
      "choices": [
        { "id": "ch_e", "label": "초등학교", "details": [
          { "id": "ch_e1", "label": "초등학교" },
          { "id": "ch_e2", "label": "국민학교" }
        ]},
        { "id": "ch_u", "label": "대학교 이상", "details": [
          { "id": "ch_u1", "label": "학사" },
          { "id": "ch_u2", "label": "석사" },
          { "id": "ch_u3", "label": "박사" }
        ]}
      ]
    }
  ]
}
```

| 필드 | 설명 |
|------|------|
| `text` | 화면 제목. **`\n`이 줄바꿈 위치다** |
| `subtitle` | 왜 묻는지 알려주는 한 줄 |
| `hint` | 입력칸 placeholder. `answer_type: "text"`일 때만 |
| `answer_type` | `text` \| `choice` \| `date` \| `multi_choice` |
| `skippable` | `true`면 화면에 "건너뛰기"가 뜬다. 결혼·자녀만 해당 |
| `choices[].details` | **선택 직후 같은 화면에 나타나는 상세 선택지.** 없으면 키를 생략한다 |

**상세가 붙는 선택지는 둘뿐이다.**

| 단계 | 상세 | 성격 |
|------|------|------|
| 초등학교 | 초등학교 / 국민학교 | 세대별 표기 차이 |
| 중학교 · 고등학교 | 없음 | |
| 대학교 이상 | 학사 / 석사 / 박사 | 학위 |

화면 문서 03은 중·고등학교에도 학위를 보이는 안이었으나 채택하지 않았다 —
"중학교 + 박사" 조합이 `education_detail`에 원본으로 남으면 나중에 학력별로
질문을 나눌 때 쓸 수 없는 값이 된다.

빈 배열이 아니라 **키 자체를 생략한다.** 앱은 키 유무로 상세 화면을 띄울지 판단한다.

> **v1에서 바뀐 점** — 예전에는 `choices`가 비었는지로 입력 방식을 갈랐고
> 선택지가 문자열 배열이었다. 생년월일(`date`)과 복수 선택(`multi_choice`)이
> 생기면서 `answer_type`이 필요해졌고, 조건부 상세 때문에 선택지가 객체가 됐다.
> 앱의 `IntroAnswerType`은 `choices` 유무가 아니라 이 필드를 읽는다.

### 2.2 자기소개 제출 → 목차 생성 `[변경]`

```
POST /intro/answers
```

```json
{
  "answers": [
    { "question_id": "i2", "choice_id": "ch_f", "value": "여" },
    { "question_id": "i6", "value": "1962-04-17" },
    { "question_id": "i3", "skipped": true },
    { "question_id": "i4", "choice_id": "ch_y", "value": "있어요" },
    { "question_id": "i5", "choice_id": "ch_u", "detail_choice_id": "ch_u1",
      "value": "대학교 이상", "detail_value": "학사" }
  ]
}
```

| 필드 | 필수 | 설명 |
|------|:---:|------|
| `question_id` | O | |
| `value` | 조건부 | 고르거나 적은 **원본 문자열**. `skipped: true`면 생략 |
| `choice_id` | 조건부 | 선택형일 때 |
| `detail_choice_id` / `detail_value` | — | 조건부 상세를 골랐을 때 |
| `values` | 조건부 | `multi_choice`일 때 문자열 배열 |
| `skipped` | — | `true`면 건너뜀. `skippable: true` 문항에만 허용 |

**원본을 접어서 저장하지 않는다.** 규칙이 두 가지다.

1. **`skipped: true`를 `아니오`로 바꾸지 않는다.** 바꾸면 "안 했어요"와
   "말하지 않았다"가 같은 값이 되어 되돌릴 수 없다.
2. **학업 상세를 `대학 O/X` 하나로 덮어쓰지 않는다.** 덮어쓰면 나중에
   "고등학교 졸업"과 "중학교 졸업"을 나눠 질문을 주고 싶어질 때 데이터가 없다.

케이스 판정값은 원본에서 **파생**시킨다. 저장은 원본, 판정은 파생이다.

**건너뛴 결혼·자녀는 축을 `false`로 파생한다** = 해당 장을 목차에 넣지 않는다.
빈 장을 넣으면 그 장에서 답할 것이 없어 진행이 막히고, 장 순차 잠금 때문에
뒤 장까지 열리지 않는다. 되돌릴 길은 두 가지로 열어 둔다 — 원본이 남아 있어
규칙이 바뀌면 재계산할 수 있고, 사용자가 §2.4에서 그 장을 직접 추가할 수 있다.

**200**

```json
{
  "case_key": "legacy_college_married_children",
  "book_id": "b_001",
  "chapters": [
    {
      "id": "c_01", "order": 1, "title": "탄생과 유아기 시절",
      "source_type": "template",
      "status": "writing", "answered_count": 0, "question_count": 5,
      "next_question_text": null
    },
    {
      "id": "c_02", "order": 2, "title": "가족환경과 성장환경",
      "source_type": "template",
      "status": "locked", "answered_count": 0, "question_count": 5,
      "next_question_text": null
    }
  ]
}
```

- **`book_id`가 이 시점에 만들어진다.** 이후 목차 편집·확정·작성이 전부 이 책 범위다
- 케이스 판정 규칙과 8종 정의는 [`목차-케이스.md`](목차-케이스.md) 참조
- 이 시점에 사용자별 목차·질문 **스냅샷을 복제해 둔다** (§13.2)
- 오래 걸리는 작업이다. 앱은 전용 로딩 화면(B6)을 띄우고 기다린다. **타임아웃 60초**

**에러**: `400 INVALID_REQUEST` (필수 문항 누락, 건너뛸 수 없는 문항에 `skipped`)

### 2.3 카탈로그 대목차 `[신규]`

```
GET /catalog/chapters?book_id=b_001
```

목차 편집에서 "추가하기"를 눌렀을 때 고를 수 있는 후보.

**200**

```json
{
  "items": [
    { "id": "ct_08", "title": "현재의 삶", "question_count": 5, "already_added": false },
    { "id": "ct_04", "title": "20대 시절 - 대학생활", "question_count": 5, "already_added": true }
  ]
}
```

`already_added: true`인 항목은 앱이 비활성으로 그린다. 목록에서 빼지 않고 내려주는 건
"이미 들어 있다"를 보여 주기 위해서다.

### 2.4 목차 초안 저장 `[신규]`

```
PATCH /intro/toc/draft
```

제목 수정·삭제·추가·순서 변경을 한 번에 반영한다. 확정 전까지 여러 번 부를 수 있다.

```json
{
  "book_id": "b_001",
  "chapters": [
    { "id": "c_02", "title": "가족환경과 성장환경" },
    { "id": "c_01", "title": "내가 태어난 날" },
    { "template_id": "ct_08" },
    { "title": "군대 이야기" }
  ]
}
```

**배열 순서가 곧 목차 순서다.** 각 항목은 셋 중 하나다.

| 형태 | 뜻 |
|------|-----|
| `{ id, title? }` | 기존 장. `title`을 주면 제목을 고친다 |
| `{ template_id }` | 카탈로그에서 새로 추가. **템플릿의 활성 질문도 함께 복제한다** |
| `{ title }` | 사용자 정의 장. `source_type: "custom"` |

**사용자 정의 장의 질문은 AI가 제목으로 만든다.** "군대 이야기"라고 적으면 거기 맞는
질문 5개를 생성한다. 범용 질문을 심으면 모든 커스텀 장이 같은 질문을 받아 장을 나눈
의미가 없고, 사용자가 직접 적게 하면 시니어에게 부담이 크다.
생성이 실패하면 **범용 질문 3개로 폴백한다** — 질문이 0개인 장은 들어가도 답할 것이
없고 곧바로 `done`이 되어 진행이 이상해진다. 이 요청은 실패로 만들지 않는다.

**배열에 없는 기존 장은 삭제된다.** 삽입 위치를 따로 보내지 않는 이유 — 앱이
"어디에 넣을지" 고른 결과가 이미 이 배열의 순서다. 위치를 별도 필드로 받으면
서버와 앱이 각자 순서를 계산해 어긋날 여지가 생긴다.

**200** — §2.2와 같은 `chapters` 배열

**에러**: `409 TOC_ALREADY_CONFIRMED`, `404 NOT_FOUND`

> 삭제는 **인트로 시점에 답변이 없다는 전제**다. 작성 시작 후의 목차 편집은
> 답변·진행률·원고 보존 정책이 정해져야 열 수 있다 (§2 확정 대기 · 작성 후 목차 편집).

### 2.5 목차 확정 `[변경]`

```
POST /intro/toc/confirm
```

```json
{ "book_id": "b_001", "chapter_ids": ["c_02", "c_01", "c_03"] }
```

**200** — v1은 `204`였다. 작성 화면으로 가려면 `book_id`가 필요해 본문을 준다.

```json
{
  "book_id": "b_001",
  "first_question_id": "q_001",
  "chapters": [ … ]
}
```

서버는 배열 순서대로 `order`를 1부터 다시 매기고, 1번 장을 `writing`,
나머지를 `locked`로 초기화한다. `toc_confirmed_at`·`intro_completed_at`을 기록하고
이후 `needs_intro`는 `false`가 된다.

> 📌 **`(book_id, sort_order)` 유니크 때문에 두 번에 나눠 쓴다.** 재배열한 순서를
> 곧바로 1..N으로 쓰면 중간에 충돌한다. 먼저 전부 음수(-1, -2, …)로 밀고 그다음 1..N.

**에러**: `409 TOC_ALREADY_CONFIRMED`, `400 INVALID_REQUEST` (보유한 장 집합과 불일치)

### 2.6 작성 계획 `[신규]`

```
GET  /intro/writing-plan
PUT  /intro/writing-plan
```

```json
{
  "daily_minutes": 30,
  "available_weekdays": [1, 3, 5],
  "available_periods": ["am"],
  "duration_weeks": 2,
  "duration_source": "recommended",
  "alarm_enabled": true
}
```

| 필드 | 설명 |
|------|------|
| `daily_minutes` | `10` \| `30` \| `60` \| `90` \| `120`(2시간 이상) |
| `available_weekdays` | `0`=일 ~ `6`=토 |
| `available_periods` | `am` \| `pm`. 복수 선택 |
| `duration_weeks` | `1` \| `2` \| `4` \| `6` |
| `duration_source` | `recommended`(서버 추천을 그대로 씀) \| `manual`(직접 고름) |
| `alarm_enabled` | 계획 수립 시점의 알림 동의 |

추천 기간은 `GET`이 함께 내려준다.

```json
{ "recommended_weeks": 2, "plan": { … } }
```

> ⚠️ **`available_periods`는 작성 가능 시간대이지 알림 발송 시각이 아니다.**
> 그리고 `alarm_enabled: true`가 실제 푸시 수신을 보장하지 않는다 —
> 발송 경로 자체가 아직 없다 (§7 확정 대기 · 발송 경로).

### 2.7 자기소개 프로필 조회 `[변경]`

```
GET /intro/profile
```

**200**

```json
{
  "entries": [
    { "label": "성별", "value": "여" },
    { "label": "생년월일", "value": "1962년 4월 17일" },
    { "label": "결혼", "value": null, "skipped": true },
    { "label": "자녀", "value": "있어요" },
    { "label": "학력", "value": "대학교 이상 · 학사" }
  ]
}
```

라벨과 값을 **서버가 짝지어** 내려준다. 화면이 `i2`·`i5` 같은 질문 id를 알 필요가 없다.

- `skipped: true`인 항목은 값을 지어내지 않는다. 앱은 "답하지 않음"으로 그린다
- 학력은 상세가 있으면 `단계 · 상세`로 합쳐 준다
- 성함은 이 목록에 넣지 않는다 — 화면 상단에 이미 이름이 있다

### 확정 대기 — 자기소개·목차

1. **기간 추천 공식.** 복수 시간대가 실제 작성 횟수를 뜻하는지, 사용자가 추천을
   거부할 수 있는지, 계획 변경 시 알림 재계산 규칙.
2. **작성 후 목차 편집.** §2.4의 삭제는 답변이 없다는 전제다. 이후 편집을
   허용하려면 답변·원고·진행률의 보존/숨김/이관 정책이 먼저 필요하다.
3. **성함(i1) 문항의 거취.** 가입에서 이름을 받게 되면서 인트로에 남길 이유가
   줄었다. 기존 `i2`~`i5` 선택값을 새 코드·라벨로 어떻게 매핑할지도 함께.

---

## 3. 홈

### 3.1 홈 요약 `[변경]`

```
GET /books/{book_id}/home
```

**200**

```json
{
  "book_id": "b_001",
  "today_question": "첫 월급을 받던 날, 기분이 어떠셨나요?",
  "today_question_id": "q_012",
  "progress": 0.42,
  "chapter_done": 2,
  "chapter_total": 5,
  "remaining_questions": 12
}
```

| 필드 | 설명 |
|------|------|
| `book_id` | 이 요약이 속한 책 |
| `today_question` | 지금 답해야 할 질문. `null`이면 앱이 빈 상태 화면을 그린다 |
| `progress` | 0.0~1.0. 해당 책의 전체 질문 중 답변 완료 비율 |

화면 하나가 필요한 값을 한 번에 준다. 서버가 여러 도메인에서 모아야 하더라도 이 모양으로 합쳐서 준다.

> [2026-08-04] v1 `GET /home`은 제거한다. 홈도 책 범위다.

---

## 4. 목차 · 질문 조회

### 4.1 장 목록 `[변경]`

```
GET /books/{book_id}/chapters
```

**200**

```json
{
  "items": [
    {
      "id": "c_01", "order": 1, "title": "탄생과 유아기 시절",
      "status": "done", "answered_count": 5, "question_count": 5,
      "next_question_text": null
    },
    {
      "id": "c_02", "order": 2, "title": "가족환경과 성장환경",
      "status": "writing", "answered_count": 3, "question_count": 5,
      "next_question_text": "가족과 함께 했던 여행 중 가장 기억에 남는 장소는 어디인가요?"
    },
    {
      "id": "c_03", "order": 3, "title": "청소년기와 학창시절",
      "status": "locked", "answered_count": 0, "question_count": 6,
      "next_question_text": null
    }
  ]
}
```

**`status`** — `locked` | `writing` | `done`

**장 순차 잠금 규칙**

- 목차 확정 시 1번 장만 `writing`, 나머지는 `locked`
- 어떤 장의 모든 질문이 확정 저장(또는 건너뛰기)되면 그 장은 `done`이 되고 **다음 장 하나만** `writing`으로 열린다
- `locked` 장의 질문은 조회·답변 모두 `409 CHAPTER_LOCKED`
- `done` 장은 다시 열리지 않는다 (v1 기준. 재작성 기능은 2차)

`next_question_text`는 `writing` 장에만 채운다 — 목록에 "다음 질문 · 첫 소풍의 기억"으로 뜬다.

### 4.2 지금 답할 질문 `[변경]`

```
GET /books/{book_id}/questions/current
```

**200**

```json
{
  "id": "q_012",
  "chapter_id": "c_02",
  "order": 3,
  "text": "가족과 함께 했던 여행 중 가장 기억에 남는 장소는 어디인가요?",
  "answer": null
}
```

`writing` 장에서 아직 답하지 않은 **가장 앞 순번**의 질문. 모든 장을 끝냈으면 **204 No Content**
(앱은 이걸 "다 끝났다"로 읽고 자서전 화면으로 보낸다).

| 필드 | 설명 |
|------|------|
| `order` | 장 안에서의 순번(1부터). "질문 3 / 6"의 앞 숫자 |
| `answer` | 확정 저장된 **사용자 원문**. 아직이면 `null`. AI 윤문 결과가 아니다 |

### 4.3 질문 단건 `[기존]`

```
GET /questions/{question_id}
```

**200** — §4.2와 동일. **에러**: `404 NOT_FOUND`, `409 CHAPTER_LOCKED`

질문 id는 전역 고유하므로 책 범위를 경로에 넣지 않는다. 대신 서버가 그 질문이
호출자의 책에 속하는지 확인하고, 아니면 **404**를 준다(§0.4).

### 4.4 질문 문구 수정 `[기존]`

```
PATCH /questions/{question_id}
```

```json
{ "text": "가족 여행 중 가장 기억에 남는 곳이 어디인가요?" }
```

**200** — 수정된 `Question`

- 수정할 수 있는 건 **문구뿐**이다. 질문 추가·삭제·순서 변경은 v1 범위 밖
- 사용자별 스냅샷(`user_question`)만 바뀐다. 카탈로그 원본은 그대로
- **답변 전 질문만 수정 가능.** 이미 답한 질문의 문구를 바꾸면 저장된 원고와 어긋난다 → `409 ALREADY_ANSWERED`

---

## 5. 작성 (핵심 흐름)

### 5.0 전체 그림

```
GET /questions/current                    질문을 받는다
        │
        ▼  사용자가 음성 또는 키보드로 답한다 (앱이 확인 화면에서 원문을 보여준다)
POST /questions/{id}/answer               1차 답변 전송
        │
        ├─ 422 FOLLOWUP_FAILED ──────────▶ 초안 폐기. 질문부터 다시 (§5.3)
        │
        ▼  200 { followup: { id, text } }  AI 꼬리질문 1개
        │
        ▼  사용자가 꼬리질문에 답한다
POST /questions/{id}/followup/{fid}/answer
        │
        ├─ 422 POLISH_FAILED ────────────▶ 글은 살려둔 채 저장만 재시도 (§5.4)
        │
        ▼  200 { followup | next_question, chapter_completed }
        followup이 오면 한 번 더, next_question이 오면 확정된 것이다
```

**질문 1개 = 묶음 1개.** 한 묶음은 (원질문, 1차 답변, 꼬리질문·꼬리답변 N쌍, 윤문 결과)다.

> **v1에서 바뀐 점** — 꼬리질문이 정확히 1회였다. 이제 **전체 3라운드**다 —
> 최초 답변 + 꼬리답변 2회. 한 질문에 사용자가 총 세 번 말한다.
> `answer_followup.seq`가 회차를 담고 질문당 최대 2행이 쌓인다.
>
> **앱은 횟수를 세지 않는다.** 응답에 `followup`이 왔는지 `next_question`이 왔는지로만
> 분기한다. 상한은 서버 설정값이라 실사용을 보고 조정할 수 있고, 그때 앱을
> 같이 고쳐야 하는 상황을 만들지 않기 위해서다.

**사용자에게 보여주는 것은 자기가 답한 원문뿐이다.** AI가 작가처럼 다듬은 글은 저장만 하고
작성 화면에서는 보여주지 않는다. 처음 눈에 띄는 곳은 자서전 미리보기(§6.4)다.

### 5.1 1차 답변 전송 `[기존]`

```
POST /questions/{question_id}/answer
```

```json
{
  "text": "제주도에 갔던 게 제일 기억에 남습니다. 그때가 아마 여든 두 살 때인데…",
  "input_mode": "voice",
  "spoken_seconds": 42
}
```

| 필드 | 필수 | 설명 |
|------|:---:|------|
| `text` | O | 사용자 원문. 음성이면 앱이 받아쓴 결과, 키보드면 적은 그대로 |
| `input_mode` | O | `voice` \| `keyboard` |
| `spoken_seconds` | — | `voice`일 때 말한 시간(초). 통계용 |

**200**

```json
{
  "followup": {
    "id": "f_9931",
    "text": "제주도 이야기를 꺼내시니 그때 공기까지 느껴지는 것 같습니다. 가족과 함께한 시간이 특별하셨던 것 같아요. 그날 제주도에서 가장 오래 머문 곳은 어디였나요?"
  }
}
```

- 서버는 1차 답변을 **초안으로 임시 저장**하고 AI에 꼬리질문을 요청한다. 이 시점에는 아직 확정이 아니다
- 꼬리질문은 요약 + 공감 + 질문이 한 덩어리로 온다 (웹 `/api/second-question`과 같은 형태)
- **타임아웃 30초.** AI 호출이 있어 일반 API보다 길다

### `다시 답하기` · `기존 답에 추가하기`

**이 엔드포인트를 다시 부르는 것이 전부다.** 전용 계약을 만들지 않았다.

| 앱 동작 | 보내는 것 | 서버 |
|---------|----------|------|
| 다시 답하기 | 입력칸을 **비운 채** 새로 받은 텍스트 | 초안을 덮어쓰고 꼬리질문을 새로 만든다 |
| 기존 답에 추가하기 | 저장된 원문을 **채워** 이어 쓴 텍스트 | 위와 동일 |

서버가 보기에 둘은 같은 요청이다. 다른 건 앱이 입력칸을 어떻게 준비하느냐뿐이다.

초안이 이미 있으면 **덮어쓴다.** 답변이 바뀌었으니 그에 딸린 꼬리질문도 다시 만드는
것이 맞다 — 옛 답변에 대한 질문을 그대로 두면 대화가 어긋난다.
`409 ALREADY_ANSWERED`는 **확정 저장된** 질문에만 나온다. 초안 단계에서는 나오지 않는다.

**에러**

| HTTP | code | 처리 |
|------|------|------|
| 409 | `ALREADY_ANSWERED` | 이미 확정된 질문 |
| 409 | `CHAPTER_LOCKED` | 잠긴 장 |
| 422 | `FOLLOWUP_FAILED` | §5.3 |

### 5.2 꼬리질문 답변 → 확정 저장 `[변경]`

```
POST /questions/{question_id}/followup/{followup_id}/answer
```

```json
{
  "text": "성산일출봉에 오래 있었습니다. 아이들이 계단을 뛰어 올라가는 걸 보면서…",
  "input_mode": "keyboard",
  "spoken_seconds": null
}
```

**200 — 아직 더 물을 게 있을 때**

```json
{
  "followup": { "id": "f_9932", "seq": 2, "text": "성산일출봉 계단을 오르던 아이들 얘기가…" }
}
```

**200 — 확정 저장됨**

```json
{
  "next_question": {
    "id": "q_013", "chapter_id": "c_02", "order": 4,
    "text": "가족 중에서 가장 존경했던 인물은 누구인가요?", "answer": null
  },
  "chapter_completed": false
}
```

| 필드 | 설명 |
|------|------|
| `followup` | 다음 꼬리질문. 있으면 **아직 확정되지 않았다** — 같은 엔드포인트를 다시 부른다 |
| `next_question` | 다음에 답할 질문. **`null`이면 모든 장을 끝냈다는 뜻** — 앱은 자서전 화면으로 이동 |
| `chapter_completed` | 이 답변으로 장이 끝났으면 `true`. 다음 장이 열린다 |

`followup`과 `next_question`은 **동시에 오지 않는다.** 둘 중 무엇이 왔는지가
"한 번 더"와 "끝났다"를 가르는 유일한 신호다.

서버가 이 요청 안에서 하는 일:

1. 꼬리답변을 초안에 합친다
2. (원질문, 1차 답변, 꼬리질문, 꼬리답변)을 AI에 넘겨 **작가체로 윤문**한다
3. 원문 2개 + 윤문 결과를 확정 저장하고 초안을 지운다
4. 진행 상태를 갱신한다 — 장의 `answered_count` 증가, 다 찼으면 `done` + 다음 장 열기

**타임아웃 60초** (윤문이 가장 무겁다)

> 📌 윤문을 응답 안에서 동기로 처리하는 이유: 실패를 사용자에게 즉시 알리고 재시도시켜야
> 하기 때문이다. 나중에 비동기 큐로 옮기려면 `polish_status`를 두고 `pending`으로 응답한 뒤
> 실패 건만 배치로 재처리하는 식이 된다. **v1은 동기.**

**에러**

| HTTP | code | 처리 |
|------|------|------|
| 404 | `NOT_FOUND` | `followup_id`가 이 질문의 것이 아님 |
| 422 | `POLISH_FAILED` | §5.4 |

### 5.3 꼬리질문 생성 실패 — 처음부터 다시 `[기존]`

AI가 꼬리질문을 만들지 못하면(서버 내부 재시도 후에도) `422 FOLLOWUP_FAILED`.

```json
{ "code": "FOLLOWUP_FAILED", "message": "질문을 만들지 못했어요. 잠시 후 다시 시도해 주세요" }
```

- **서버는 임시 저장한 1차 답변을 폐기한다.**
- 앱은 질문 화면으로 되돌아가 처음부터 다시 답을 받는다.
- 사용자가 답을 다시 해야 한다 — 감수하기로 한 동작이다.

> 📌 §5.6의 초안 autosave가 붙어도 **이 규칙은 그대로다.** 실패 시 초안을 지운다.
> 화면에 없는 글을 서버가 들고 있으면, 사용자가 다시 답한 내용과 어긋난다.

### 5.4 윤문 실패 — 저장만 재시도 `[기존]`

`422 POLISH_FAILED`.

```json
{ "code": "POLISH_FAILED", "message": "저장에 실패했어요. 다시 시도해 주세요" }
```

- **초안(1차 답변 + 꼬리질문 + 꼬리답변)은 지우지 않는다.**
- 앱은 이미 있는 저장 실패 화면(D5)에 머물면서 글을 화면에 남겨 두고 "다시 저장하기"를 띄운다.
- "다시 저장하기"는 §5.2를 **같은 파라미터로 재요청**한다. 서버는 멱등하게 처리한다.

꼬리질문 실패(§5.3)와 다른 이유: 그때는 아직 사용자가 한 번밖에 답하지 않았지만, 여기서는
두 번 답한 상태다. 두 번의 이야기를 날리고 처음부터 시키는 건 다른 문제다.

### 5.5 건너뛰기 `[기존]`

```
POST /questions/{question_id}/skip
```

**200** — §5.2와 같은 형태

```json
{ "next_question": { … }, "chapter_completed": false }
```

**처리가 답변 유무로 갈린다.**

| 언제 | 처리 | 질문 상태 |
|------|------|----------|
| 질문 화면에서 (1차 답변 전) | 초안 없음. 그대로 넘긴다 | `skipped` |
| 꼬리질문 화면에서 (1차 답변 후) | 그때까지의 답변을 **윤문해 확정 저장** | `answered` |

화면 문서가 "건너뛰기 → `skipped` 저장"과 "건너뛰기 → 기존 답변을 AI가 정리·저장"을
함께 말해 모순처럼 보였는데, **건너뛰기 버튼이 두 화면에 있어서**다. 각각 다른 경우를
가리킨 것으로 읽는다. 이미 말한 이야기를 버리지 않는다.

`skipped` 질문은 답변 없이 완료 처리한다. 장의 `answered_count`에는 포함된다
(그래야 장이 끝난다). 자서전 본문에는 실리지 않는다.

응답의 `next_question`·`chapter_completed`는 두 경우 모두 같은 형태다 —
앱은 어느 화면에서 눌렀는지만 알면 되고 분기를 따로 두지 않는다.

### 5.6 초안 autosave `[신규]`

```
PUT    /questions/{question_id}/draft
GET    /questions/{question_id}/draft
DELETE /questions/{question_id}/draft
```

```json
{
  "text": "제주도에 갔던 게 제일 기억에 남습니다…",
  "input_mode": "voice",
  "spoken_seconds": 42,
  "recording_meta": { "transcribed_at": "2026-08-03T04:12:00Z", "partial": false }
}
```

**200** — `PUT`·`GET` 모두 같은 형태

```json
{
  "question_id": "q_012",
  "phase": "followup",
  "text": "제주도에 갔던 게 제일 기억에 남습니다…",
  "input_mode": "voice",
  "spoken_seconds": 42,
  "followup_round": 1,
  "pending_followup": { "id": "f_9931", "text": "그날 제주도에서 가장 오래 머문 곳은…" },
  "updated_at": "2026-08-03T04:12:00Z"
}
```

| 필드 | 설명 |
|------|------|
| `phase` | `first`(1차 답변만 있음) \| `followup`(꼬리질문 대기 중) |
| `followup_round` | 지금까지 주고받은 회차. 앱은 이 값을 세지 말고 표시에만 쓴다 |
| `pending_followup` | 답을 기다리는 꼬리질문. `null`이면 1차 답변 단계다 |

앱은 작성 화면에 들어올 때 `GET`으로 복원할 초안이 있는지 본다.
`phase`와 `pending_followup`으로 **어느 단계에서 끊겼는지** 알 수 있어야
그 화면으로 되돌려 놓을 수 있다.

STT 전사가 끝나면 앱이 **확정 전에** 여기 저장한다. 사용자가 확인·수정하는 동안
앱이 죽거나 전화가 와도 글이 남는다.

> ⚠️ **초안 저장과 확정 저장은 다른 것이다.** 불안정한 부분 전사를 `answer` 확정
> 행으로 곧바로 쓰지 않는다. 전사 직후 자동 확정을 허용할지는 §5 확정 대기 · 전사 후 자동 확정.

`GET`은 초안이 없으면 **204**다. 앱은 이걸 "복원할 게 없다"로 읽는다.

### 5.7 음성 (TTS · STT) `[신규]`

```
POST /voice/tts
POST /voice/stt
```

**TTS** — 질문을 읽어 준다.

```json
{ "text": "가족과 함께 했던 여행 중…", "voice_code": "nara" }
```

**200** — `audio/mpeg` 스트림. 가능하면 `X-Voice-Duration-Ms` 헤더에 실측 길이를 싣는다.

**STT** — 녹음을 받아쓴다. `multipart/form-data`로 오디오를 올린다.

```json
{ "text": "제주도에 갔던 게 제일 기억에 남습니다", "duration_ms": 42130 }
```

- **제공자 자격 증명은 서버만 갖는다.** 앱은 액세스 토큰으로 이 엔드포인트를 부르고,
  네이버 Voice(Clova 계열) 키를 앱 번들에 넣거나 제공자 API를 직접 부르지 않는다
- 질문 TTS와 한글 타이핑 애니메이션 동기화는 **제공자가 문자 단위 타이밍을 주는지에
  달렸다.** 안 주면 실측 오디오 길이 + grapheme 단위 스케줄러로 근사한다.
  완전한 음성-문자 일치는 보장하지 않는다
- 긴 원고는 제공자 한도 이하로 쪼개 순차 호출한다 (챕터 리뷰 읽어주기, §9.4)

### 5.8 보이스·마이크 점검 `[신규]`

작성 화면 최초 로드에서 "소리가 나는가 / 마이크가 잡히는가"를 확인한다.

```
GET  /voice/sample?voice_code=nara     보이스 체크
POST /voice/stt                        마이크 체크 (§5.7 재사용)
```

**보이스 체크** — `audio/mpeg` 스트림. 짧은 안내 문장을 읽어 준다.

**미리 렌더해 둔 샘플을 준다.** 점검은 작성 화면에 들어올 때마다 도는데 매번 TTS를
부르면 비용과 지연이 붙는다. 음성을 바꾸지 않는 한 결과가 같으므로 음성별로 한 번
만들어 두고 그대로 내보낸다.

**마이크 체크** — 짧은 테스트 녹음을 `/voice/stt`로 올려 전사가 돌아오는지 본다.
전용 엔드포인트를 만들지 않았다. 실제 작성에서 쓰는 것과 같은 경로로 점검해야
"점검은 됐는데 정작 녹음이 안 된다"가 생기지 않는다.

앱은 결과를 이렇게 쓴다.

| 상황 | 화면 |
|------|------|
| 샘플 재생 실패 | 음량·출력 장치 안내. 작성은 계속할 수 있다 |
| 마이크 권한 거부 | **타이핑 입력으로 안내한다.** 막지 않는다 |
| 전사 결과가 빔 | 다시 시도 또는 타이핑 전환 |

> 화면 문서 04는 `POST /books/:bookId/voice/check`를 제안했으나 **책 범위를 두지 않았다.**
> 점검은 기기와 제공자 상태를 보는 것이지 특정 책과 무관하다. `bookId`를 받으면
> 권한 검사를 붙여야 하는데 그 검사가 점검 결과를 바꾸지 않는다.

### 5.9 챕터 완료 조회 `[신규]`

```
GET /books/{book_id}/chapters/{chapter_id}/completion
```

**200**

```json
{
  "chapter_id": "c_02",
  "chapter_order": 2,
  "chapter_title": "가족환경과 성장환경",
  "question_count": 6,
  "answered_count": 5,
  "skipped_count": 1,
  "review_status": null,
  "next_chapter": { "id": "c_03", "order": 3, "title": "청소년기와 학창시절" },
  "actions": { "review": true, "hub": true }
}
```

| 필드 | 설명 |
|------|------|
| `review_status` | `null`이면 아직 리뷰 전. 완료 화면에서 `리뷰하러 가기`를 강조한다 |
| `next_chapter` | `null`이면 마지막 장. 앱은 `홈으로 이동`만 그린다 |
| `actions.review` | 장이 `done`이어야 `true` |

**§5.2의 `chapter_completed`만으로는 부족해서 둔다.** 그건 "방금 끝났다"는 일회성
신호라, 완료 화면에 들어간 뒤 앱이 죽거나 사용자가 뒤로 갔다 오면 사라진다.
이 조회가 있어야 그 화면을 다시 그릴 수 있다.

**에러**: `404 NOT_FOUND`, `409 CHAPTER_LOCKED`

> 화면 문서 04의 `POST /books/:bookId/write/session`은 별도로 두지 않았다.
> 그 제안이 묶어 놓은 것을 이미 있는 계약으로 나눴다 —
> 책 권한·진행은 §6.2, 현재 질문은 §4.2, 음성 점검은 §5.8,
> 튜토리얼 상태는 저장 위치가 정해지지 않아 확정 대기(아래 3번)다.

### 확정 대기 — 작성

1. **재답변 시 버전 보존.** 확정된 답변을 다시 답할 수 있게 열지, 연다면 이전
   답변을 버전으로 남길지 덮어쓸지.
2. **전사 후 자동 확정.** STT 결과를 사용자 확인 없이 `answer`로 확정할지.
   현 설계는 초안까지만 자동이다.
3. **튜토리얼 완료 상태의 저장 위치.** 기기 로컬이면 간단하지만 가족이 여러 기기로
   쓰면 매번 다시 뜬다. 서버 동기화 시 단계 중단 복원까지 할지도 함께.
4. **녹음 일시정지**와 **`다른 질문`.** 기기별 테스트와 제품 결정이 선행되어야 한다.

---

## 6. 나의 자서전

### 6.1 책 목록 `[신규]`

```
GET /books
```

**200**

```json
{
  "items": [
    {
      "id": "b_001",
      "title": "나의 이야기",
      "author_name": "김영희",
      "status": "writing",
      "cover_url": null,
      "chapter_count": 9,
      "chapter_done": 2,
      "progress": 0.42,
      "updated_at": "2026-08-01T09:00:00Z"
    }
  ]
}
```

인증 사용자에게 허용된 책만 서버가 걸러서 준다. 앱은 `status`로 "제작 중"과
"제작 완료" 섹션을 나눈다.

**`status`는 저장된 컬럼이 아니라 파생값이다.**

| 값 | 조건 |
|----|------|
| `draft` | 목차 확정 전 |
| `completed` | 모든 장이 `reviewed` |
| `writing` | 그 외 |

저장하면 갱신 주체가 필요하고, 어긋나면 "완료된 책인데 전자책이 안 나온다"가 된다.
`book/pages`를 캐시하지 않기로 한 것과 같은 판단이다.

완료 기준을 `done`이 아니라 `reviewed`로 잡은 이유 — `done`은 질문을 다 처리했다는
뜻일 뿐이고 그 상태로는 전자책·오디오북이 나오지 않는다(§10). 산출물 자격과 완료
표시가 어긋나면 사용자가 "완료됐는데 왜 안 되냐"고 묻게 된다.

```
POST /books
```

새 책을 만든다. **기존 책의 목차·답변을 초기화하지 않는다.** 생성 방식(인트로를
다시 하는지, 기존 목차를 복제하는지)은 §6 확정 대기 · 새 책 생성.

### 6.2 책 상세 `[신규]`

```
GET /books/{book_id}
```

상세 허브 한 화면이 필요한 값을 한 번에 준다.

**200**

```json
{
  "id": "b_001",
  "title": "나의 이야기",
  "status": "writing",
  "progress": 0.42,
  "chapter_done": 2,
  "chapter_total": 9,
  "current_question": {
    "id": "q_012", "chapter_id": "c_02", "chapter_title": "가족환경과 성장환경",
    "order": 3, "text": "가족과 함께 했던 여행 중…"
  },
  "chapters": [
    {
      "id": "c_01", "order": 1, "title": "탄생과 유아기 시절",
      "status": "done", "answered_count": 5, "question_count": 5,
      "review_status": "reviewed", "ebook_eligible": true
    },
    {
      "id": "c_02", "order": 2, "title": "가족환경과 성장환경",
      "status": "writing", "answered_count": 3, "question_count": 5,
      "review_status": null, "ebook_eligible": false
    }
  ],
  "entitlements": {
    "ebook":     { "allowed": true,  "reason": null },
    "audiobook": { "allowed": false, "reason": "PLAN_REQUIRED" },
    "storybook": { "allowed": false, "reason": "WEB_ONLY" }
  }
}
```

| 필드 | 설명 |
|------|------|
| `current_question` | 다음에 답할 질문. `null`이면 다 끝났다 |
| `chapters[].review_status` | `null` \| `draft` \| `reviewed`. **`status: done`과 다른 개념** |
| `chapters[].ebook_eligible` | 이 장이 전자책에 실릴 자격이 되는지 |
| `entitlements` | 기능별 허용 여부와 잠긴 이유. **UI 안내용이다** |

> ⚠️ `entitlements`는 화면이 잠금을 그리라고 주는 값이지 접근 통제가 아니다.
> 실제 통제는 각 생성·조회·다운로드 요청에서 서버가 다시 한다 (§11).

> 화면 문서 06-1의 `GET /books/:bookId/progress`(길 이정표 상세 진행 뷰)는 두지 않았다.
> 이 응답의 `chapters[]`가 이정표를 그리는 데 필요한 값을 이미 담고 있고,
> 별도 뷰의 정보 구조는 Figma 시안이 확인되지 않아 무엇을 더 줘야 할지 모른다.
> 시안이 나오고 이 응답으로 부족하면 그때 추가한다.

### 6.3 책 요약 `[변경]`

```
GET /books/{book_id}
```

상세 허브가 필요 없을 때 쓰는 **짧은 요약**은 §6.2 응답의 상위 필드
(`id`, `title`, `status`, `progress`, `chapter_done`, `chapter_total`)로 충분하다.
별도 `GET /book`(v1 단일 책) 경로는 **제거**한다.

완성 화면(E3)용 `is_complete`가 필요하면 §6.2의 `status === "completed"`
(모든 장 `reviewed`)를 쓴다. v1의 `is_complete`(모든 장 `done`)와 의미가 다르다.

### 6.4 미리보기 쪽 `[변경]`

```
GET /books/{book_id}/pages
```
**200**

```json
{
  "items": [
    {
      "chapter_order": 1,
      "chapter_title": "탄생과 유아기 시절",
      "page_number": 1,
      "total_pages": 34,
      "paragraphs": [
        "나는 1962년 봄, 전라남도 해남의 작은 마을에서 태어났다.",
        "어머니는 늘 그날 유난히 볕이 좋았다고 말씀하셨다."
      ]
    }
  ]
}
```

- **AI가 윤문한 글이 처음으로 사용자에게 보이는 곳이다.**
- `done` 장만 포함한다. 작성 중인 장은 나오지 않는다
- `page_number`는 책 전체 기준 통쪽수 (장마다 1로 돌아가지 않는다)
- `total_pages`가 쪽마다 실려 오는 건 중복이지만, 앱이 쪽 하나만 들고도 "12 / 34쪽"을 그릴 수 있어야 해서 그대로 둔다
- 쪽 나누기는 **서버가 계산한다.** 앱은 받은 대로 그린다 — 기기 폭에 따라 쪽이 달라지면 "12 / 34쪽"이 사람마다 달라진다

### 확정 대기 — 책

1. **새 책 생성.** 인트로를 다시 하는지, 기존 목차를 복제하는지,
   빈 초안부터 시작하는지. 첫 책·에디션의 명명 규칙.
2. **가족 공유.** v1에는 넣지 않기로 했다. 목록·상세·작성·리뷰별
   읽기/편집 권한, 초대·철회, 감사 로그가 정해져야 열 수 있다.
   추가 비용을 낮추려고 모든 `:bookId` 조회를 "소유자 또는 참여자" 판정 함수
   하나로 좁혀 두었다 — 나중에 표 1개와 그 함수만 고치면 된다.
3. **하단 정보의 노출 항목.** 전화번호·배송지는 기본 비노출로 두었고,
   자녀 연결 상태도 공유 동의 정책 전에는 내리지 않는다.

---

## 7. 알림

### 7.1 목록 `[기존]`

```
GET /notifications
```

**200**

```json
{
  "items": [
    {
      "id": "n_01",
      "title": "오늘의 질문이 도착했어요 · 학창 시절과 꿈",
      "time_label": "오늘 오전 9:00",
      "is_read": false
    }
  ]
}
```

최신순. `time_label`은 **서버가 만든 표시용 문자열**이다 — 기기 시계가 틀어져 있으면
"2시간 전"이 엉뚱하게 나오므로 상대 시각을 앱에서 계산하지 않는다.

> 📌 확장 지점: 정렬·그룹핑이 필요해지면 원본 시각(`created_at`)을 함께 내려준다.

### 7.2 모두 읽음 `[기존]`

```
POST /notifications/read-all
```

**200** — 갱신된 목록 (§7.1과 동일). 앱이 다시 조회하지 않아도 되게 결과를 돌려준다.

### 7.3 단말 푸시 토큰 등록 `[신규]`

```
POST   /device-push-tokens
DELETE /device-push-tokens/{token}
```

```json
{ "platform": "ios", "token": "…" }
```

**204**. 같은 토큰이 이미 있으면 사용자·갱신 시각만 바꾼다(upsert).

> ⚠️ **테이블만 있고 이 API가 없어 토큰이 한 건도 쌓이지 않던 상태였다.**
> 등록이 붙어도 발송은 별개다 — provider·스케줄러·발송 워커가 모두 없다.
> `user_setting.daily_question_alarm`이 켜져 있다는 것과 푸시가 실제로 간다는 것은
> 다른 얘기이고, 화면 문구도 그렇게 써야 한다.

### 확정 대기 — 알림

1. **발송 경로.** provider(FCM/APNs) 선택, 키 관리, 스케줄러, 발송 워커,
   실패 재시도, 무효 토큰 폐기, 개인정보 고지.
2. **발송 시각·빈도·시간대.** `writing_plan.available_periods`는 작성 가능
   시간대이지 발송 시각이 아니다. 휴일·복수 슬롯 우선순위·미응답 재알림도 미정.
3. **알림 카드 X의 의미.** 카드만 닫기 / 오늘 알림 해제 / 미루기 / 개별 읽음 중
   무엇인지. 각각 저장 상태와 재노출 규칙이 다르다. 확정 전까지 X는
   **로컬 화면 닫기**로만 두고 서버 상태를 바꾸지 않는다.
4. **인앱 알림의 딥링크.** 지금은 탭하면 "준비 중" 토스트다. 다권 전환 후
   `book_id` + 질문/챕터로 보내는 계약이 필요하다.

---

## 8. 설정

### 8.1 앱 설정 `[기존]`

```
GET  /settings
PATCH /settings
```

```json
{ "daily_question_alarm": true }
```

**200** — 갱신된 `AppSettings`

v1에서 켜고 끌 수 있는 건 "오늘의 질문 알림" 하나뿐이다.

### 8.2 인쇄본 배송지 `[기존]`

```
GET /shipping-address
PUT /shipping-address
```

```json
{
  "recipient": "김영희",
  "phone": "01012345678",
  "postal_code": "03186",
  "line1": "서울 종로구 세종대로 175",
  "line2": "302동 1201호"
}
```

- **등록 전에도 `404`가 아니라 빈 문자열이 채워진 객체를 돌려준다.** 앱이 "없음"과 "못 불러옴"을 구분할 필요가 없다
- `phone`은 **숫자만** 저장한다. `010 1234 5678`처럼 띄우는 건 표시할 때만
- `line2`(상세 주소)는 비어 있어도 된다. 나머지 4개는 필수

---

## 9. 챕터 리뷰 `[신규]`

한 챕터의 모든 확정 답변을 AI가 자서전 원고로 종합한 결과를 읽는 화면이다.

**`done`과 `reviewed`는 다르다.**

| 상태 | 뜻 | 어디에 |
|------|-----|--------|
| `user_chapter.status = done` | 모든 질문에 답했다(또는 건너뛰었다) | §4.1 |
| `chapter_review.status = reviewed` | 종합 원고를 사람이 확인하고 저장했다 | 여기 |

전자책·오디오북·스토리북의 생성 자격은 전부 **후자**다. v1에는 이 개념이 없었다.

**`chapter_review`가 reviewed의 단일 정의다.** 웹 `chapter_notebook`은 이 표로
이관한다 — 산출물이 고정해야 할 원고 `version`을 원고 소유자가 들고 있어야 하고,
만드는 쪽과 소비하는 쪽이 갈리면 어느 쪽 버전인지 흐려진다.

**앱은 읽기 전용이다.** 본문 직접 편집과 수동 사진 삽입은 웹에서 한다.

### 9.1 리뷰 조회 `[신규]`

```
GET /books/{book_id}/chapters/{chapter_id}/review
```

**200**

```json
{
  "chapter_id": "c_01",
  "chapter_order": 1,
  "chapter_title": "탄생과 유아기 시절",
  "status": "draft",
  "version": 3,
  "paragraphs": [
    "나는 1962년 봄, 전라남도 해남의 작은 마을에서 태어났다.",
    "어머니는 늘 그날 유난히 볕이 좋았다고 말씀하셨다."
  ],
  "media": [
    { "id": "m_01", "url": "…", "paragraph_index": 0, "source": "ai_generated" }
  ],
  "permissions": {
    "manual_photo": false,
    "ai_photo": true,
    "ai_rewrite": false,
    "edit_body": false
  },
  "edit_hint": "웹에서 수정할 수 있어요"
}
```

| 필드 | 설명 |
|------|------|
| `version` | 원고 버전. 오디오북·스토리북이 이 값을 고정해 두고 생성한다 |
| `media[].paragraph_index` | 이 문단 **뒤에** 놓는다 |
| `permissions` | 플랜에 따른 허용 여부. 앱은 이걸로 버튼을 그린다 |

저장된 원고가 없으면 **204**다. 앱은 §9.2로 생성을 요청한다.

### 9.2 종합 원고 생성 `[신규]`

```
POST /books/{book_id}/chapters/{chapter_id}/review/synthesize
```

**200** — §9.1과 동일한 형태

- 챕터의 모든 확정 답변을 AI에 넘겨 자서전 문체로 종합한다
- 이미 원고가 있으면 재생성이다. `ai_draft`는 남기고 `body`와 `version`을 갱신한다
- **타임아웃 90초.** 챕터 전체를 다루므로 윤문(§5.2)보다 무겁다

**에러**: `409 CHAPTER_LOCKED` (아직 `done`이 아님), `422 SYNTHESIZE_FAILED`

### 9.3 리뷰 저장 `[신규]`

```
PATCH /books/{book_id}/chapters/{chapter_id}/review
```

```json
{ "status": "reviewed", "version": 3 }
```

**200** — 갱신된 리뷰

```json
{
  "status": "reviewed",
  "version": 3,
  "message": "챕터1 저장 완료",
  "next_chapter_id": "c_02"
}
```

| 필드 | 설명 |
|------|------|
| `version` | **요청에 실어 보낸다.** 서버가 들고 있는 값과 다르면 `409` — 웹에서 먼저 고친 원고를 앱이 덮어쓰지 않게 한다 |
| `message` | 첫 장은 "챕터1 저장 완료", 이후는 "현재 챕터 저장 완료" |
| `next_chapter_id` | `null`이면 다음 장이 없다 → 앱은 `홈으로 이동`을 그린다 |

**앱은 `body`를 보내지 못한다.** 본문 필드를 받지 않는다 — 편집은 웹의 몫이고,
앱이 읽기 전용이라는 규칙을 계약 자체로 강제한다.

### 9.4 원고 읽어주기 `[신규]`

```
POST /books/{book_id}/chapters/{chapter_id}/review/tts
```

```json
{ "from_paragraph": 0, "chunk_size": 2 }
```

**200** — `audio/mpeg` + 다음 청크 위치

긴 원고를 한 요청에 보내지 않는다. 제공자 한도 이하의 문장·문단 청크로 나눠
순차 요청하고, 앱은 받은 순서대로 재생한다. 중지·재시도·다시 듣기 상태를 앱이 관리한다.

### 9.5 AI 사진 생성 `[신규]`

```
POST /books/{book_id}/chapters/{chapter_id}/review/images/generate
```

**200**

```json
{
  "media": { "id": "m_02", "url": "…", "source": "ai_generated" },
  "placement": { "paragraph_index": 0, "sort_order": 0 },
  "remaining_generations": 0
}
```

앱은 이 응답만으로 화면을 갱신한다 — §9.1을 다시 부르지 않아도 사진이 어디 붙었는지
안다. `remaining_generations: 0`이면 버튼을 비활성으로 바꾼다.

무료 플랜도 쓸 수 있다. 챕터 본문을 바탕으로 1장을 만들어 **첫 이미지 슬롯에 우선**
배치한다.

> ⚠️ **외부 이미지 제공자에게 답변 본문을 보낸다.** 고지와 명시적 동의, 제공자의
> 학습 이용·보관·삭제 정책 확인이 선행되어야 한다. 동의 없이 호출하지 않는다.

**에러**: `403 PLAN_REQUIRED`, `429 QUOTA_EXCEEDED`, `409 CHAPTER_NOT_REVIEWED`

### 확정 대기 — 리뷰

1. **웹 `chapter_notebook`의 이관 절차.** 소유자는 `chapter_review`로 정해졌으나,
   기존 웹 원고를 언제 어떤 순서로 옮길지와 이관 중 웹 편집을 어떻게 막을지는 미정이다.
2. **AI 사진의 슬롯 규칙.** 기존 첫 슬롯 사진을 덮어쓸지 다음 빈 슬롯으로 보낼지.
   이미 수동 사진이 5장일 때의 처리. 생성 횟수·비용 한도.
3. **`AI와 함께 수정하기`.** 중지 문장 ±1문장(총 3문장)과 음성 지시로 부분 수정안을
   만드는 기능. 즉시 반영의 의미(자동 저장 여부), 사실 왜곡 방지, 되돌리기 이력,
   유료 권한이 정해지지 않았다. 엔드포인트를 만들지 않았다.
4. **웹 편집과의 충돌 정책.** 앱은 직접 편집하지 않으므로 웹 저장본을 우선한다는
   방향까지는 정해졌으나, 버전 불일치 시 앱 화면의 복구 절차가 미정이다.
5. **본문 저장 시 media placement의 재계산.** 문단 인덱스가 밀렸을 때
   `anchor`로 얼마나 되찾을지, 못 찾으면 어디로 보낼지.

---

## 10. 산출물 `[신규]`

전자책·오디오북·스토리북. 셋 다 **`reviewed` 원고**를 입력으로 삼는다.

| 산출물 | 앱 | 최소 자격 |
|--------|-----|----------|
| 전자책 (PDF) | 열람·다운로드 | 챕터1 `reviewed` + 무료 포함 entitlement |
| 오디오북 (MP3) | 재생·다운로드 | 유료 entitlement + 해당 챕터 `reviewed` |
| 스토리북 (MP4) | **비범위** | 웹 전용 |

> **스토리북은 앱에 만들지 않는다.** 화면·route·CTA·완료 알림 어느 것도 넣지 않는다.
> 서버 계약은 웹과 공유하되 앱은 소비하지 않는다. 이 문서에도 계약을 적지 않는다.

### 10.1 전자책 자격 `[신규]`

```
GET /books/{book_id}/ebook/eligibility
```

**200**

```json
{
  "allowed": true,
  "included_chapters": [
    { "id": "c_01", "order": 1, "title": "탄생과 유아기 시절", "version": 3 },
    { "id": "c_02", "order": 2, "title": "가족환경과 성장환경", "version": 1 }
  ],
  "pending_chapters": 7,
  "cover_kind": "default",
  "downloadable": true,
  "title_suggest_available": false,
  "progress": 0.42
}
```

**담기는 것은 `reviewed`된 장 전부다.** 규칙이 하나다 — *"리뷰 저장된 장을 순서대로
담는다."*

"챕터1만" 같은 특수 규칙을 두지 않았다. 그 규칙은 서버와 앱 양쪽에 박아야 하고,
3장까지 리뷰한 사용자가 1장만 받는 상황이 생긴다. 이 규칙 하나면 **챕터1이 자연히
최소 조건**이 된다 — 한 장도 리뷰하지 않으면 담을 것이 없어 생성이 막힌다.

| 필드 | 설명 |
|------|------|
| `included_chapters` | 이번에 담기는 장과 그 시점의 원고 버전 |
| `pending_chapters` | 아직 `reviewed`가 아닌 장 수. 앱이 "7개 장이 더 있어요"를 그린다 |
| `cover_kind` | `default`(서비스 기본 표지) \| `user` |
| `title_suggest_available` | 전체 진행률 80% 이상일 때만 `true` |

`allowed: false`면 사유와 함께 온다.

```json
{ "allowed": false, "reason": "CHAPTER_NOT_REVIEWED" }
```

앱은 "챕터 리뷰를 저장하면 전자책을 확인할 수 있어요"와 리뷰 화면 CTA를 그린다.

### 10.2 전자책 생성·다운로드 `[신규]`

```
POST /books/{book_id}/ebook/generate
GET  /books/{book_id}/ebook/file
```

`generate`는 기존 생성본의 **장 구성과 원고 버전이 지금과 같으면** 그대로 돌려준다.
장이 늘거나 원고가 개정되면 새로 만든다.

```json
{
  "export_id": "ex_01",
  "status": "completed",
  "chapter_snapshot": [{ "chapter_id": "c_01", "version": 3 }]
}
```

`file`은 인증 확인 후 PDF 스트림 또는 **짧은 수명 URL**을 준다.

> ⚠️ **PDF는 자서전 원고다.** 영구 공개 URL을 만들지 않는다. 생성과 다운로드
> **양쪽 모두**에서 소유 관계·`reviewed` 장 존재 여부·entitlement를 다시 검사한다.
> 응답의 `chapter_snapshot`을 앱이 그대로 표시해, 완성본이 아닌데 완성본처럼
> 보이는 제목·페이지 수를 띄우지 않게 한다.

### 10.3 AI 제목 추천 `[신규]`

```
POST /books/{book_id}/ebook/titles/suggest
PATCH /books/{book_id}/ebook/metadata
```

**200** — 후보 4개

```json
{ "titles": ["해남에서 시작된 이야기", "볕이 좋던 날", "…", "…"] }
```

**전체 진행률 80% 이상일 때만 허용한다.** 앱이 버튼을 비활성으로 그리는 것과 별개로
서버가 진행률을 다시 계산해 확인한다. 미달이면 `403`.

### 10.4 오디오북 `[신규]`

```
GET  /books/{book_id}/audiobook                              목차별 상태·잔여 횟수
GET  /books/{book_id}/audiobook/voices                       선택 가능한 음성
POST /books/{book_id}/audiobook/voice-preview                음성 샘플
GET  /books/{book_id}/audiobook/bgms                         BGM 카탈로그
POST /books/{book_id}/audiobook/chapters/{chapter_id}/jobs   생성 요청
GET  /books/{book_id}/audiobook/jobs/{job_id}                진행 상태
POST /books/{book_id}/audiobook/jobs/{job_id}/cancel         취소
GET  /books/{book_id}/audiobook/chapters/{chapter_id}/stream 재생
POST /books/{book_id}/audiobook/chapters/{chapter_id}/downloads 다운로드
```

**`GET /books/{book_id}/audiobook`** — 화면 진입에 필요한 값을 한 번에 준다.

```json
{
  "book_title": "나의 이야기",
  "allowed": true,
  "plan_code": "T1",
  "total_char_count": 12840,
  "estimated_duration_ms": 5136000,
  "chapters": [
    {
      "chapter_id": "c_01", "order": 1, "title": "탄생과 유아기 시절",
      "state": "completed",
      "char_count": 1420,
      "estimated_duration_ms": 568000,
      "remaining_generations": 1,
      "latest_job": { "id": "aj_01", "status": "completed", "progress": 100, "stale": false }
    },
    {
      "chapter_id": "c_02", "order": 2, "title": "가족환경과 성장환경",
      "state": "not_ready",
      "char_count": 0, "estimated_duration_ms": null,
      "remaining_generations": 2, "latest_job": null
    }
  ]
}
```

| `state` | 화면 |
|---------|------|
| `not_ready` | "리뷰를 먼저 저장해 주세요" + 리뷰 CTA. `chapter_review`가 `reviewed`가 아니다 |
| `ready` | `생성하기` 활성 |
| `processing` | 진행률 표시. 중복 생성 버튼 차단 |
| `completed` | 재생·다운로드 |
| `failed` | 오류 문구 + 재시도 |

`latest_job.stale`은 **생성 이후 원고가 개정됐다**는 뜻이다. 파일은 살아 있지만
지금 원고와 다르므로 앱이 "이전 원고로 만든 파일이에요"를 띄운다.

**무료 플랜에는 목차 정보 자체를 주지 않는다.**

```json
{ "book_title": "나의 이야기", "allowed": false, "reason": "PLAN_REQUIRED", "chapters": [] }
```

이전 생성 파일의 메타데이터가 잠금 화면에 섞여 나가면 잠금이 아니다.

**생성 요청 본문**

```json
{
  "voice_code": "nara",
  "bgm_track_id": "bgm_02",
  "idempotency_key": "cli_8f21a"
}
```

**200**

```json
{ "job_id": "aj_01", "status": "pending", "remaining_generations": 1 }
```

**한도는 챕터당 생성 2회다. 재생·다운로드는 무제한이다.**

비용이 드는 건 TTS 생성이고, 이미 만든 파일을 다시 듣는 것은 스토리지 비용뿐이다.
만들어 둔 오디오북을 두 번밖에 못 듣게 하면 사용자가 납득하기 어렵다.
`stream`과 `downloads`는 권한만 확인하고 한도를 차감하지 않는다.

서버가 job 생성 전에 원자적으로 검사하는 것:

1. 책 소유 관계
2. 오디오북 entitlement
3. 해당 챕터의 `chapter_review.status = reviewed`
4. 남은 생성 횟수
5. 진행 중인 같은 챕터 job이 없는지 → 있으면 `409 JOB_IN_PROGRESS`

> ⚠️ **한도 검사를 UI에 맡기지 않는다.** `entitlement_ledger`의 조건부 삽입으로
> 처리하고, `idempotency_key`가 동시 클릭·HTTP 재시도로 두 번 차감되는 것을 막는다.
> 실패·취소 시 복구도 ledger에 사유와 함께 남긴다 — 카운터 하나로는 분쟁이 났을 때
> 왜 줄었다 늘었는지 설명할 수 없다.

**무료 플랜에는 미디어 메타데이터도 주지 않는다.** 잠금 화면에 이전 생성 파일 정보가
섞여 나가면 잠금이 아니다.

**에러**: `403 PLAN_REQUIRED`, `409 CHAPTER_NOT_REVIEWED`, `409 JOB_IN_PROGRESS`, `429 QUOTA_EXCEEDED`

### 확정 대기 — 산출물

1. **진행률 80%의 분모.** 전체 질문 / `reviewed` 챕터 / 다른 기준 중 무엇인지,
   건너뛴 질문을 포함하는지.
2. **실패·취소 시 한도 복구 시점.** 생성 2회로 정했으나, 어느 단계에서 실패해야
   돌려주는지(제공자 오류 / 사용자 취소 / 믹싱 실패)가 정해지지 않았다.
3. **BGM 라이선스.** 상업 이용·재배포·지역/기간, 출처 증빙, 음성 대비 볼륨,
   믹싱 실패 시 처리. 검수 전에는 사용자 선택지에 올리지 않는다.
4. **기본 표지의 디자인**과 제목·저자 기본값. 제목 변경 시 기존 생성본을
   재생성할지 무효화할지.
5. **파일 제공 방식.** 서버 스트림 / 서명 URL / 앱 로컬 암호화 저장 중 무엇인지,
   만료·재발급·접근 로그 정책. 한도와 무관해진 다운로드 이력을 남길지도 여기서 정한다.

---

## 11. 권한 `[신규]`

```
GET /books/{book_id}/entitlements
```

**200**

```json
{
  "plan_code": "free",
  "features": {
    "ebook":         { "allowed": true,  "reason": null,            "remaining_generations": null },
    "audiobook":     { "allowed": false, "reason": "PLAN_REQUIRED", "remaining_generations": 0 },
    "manual_photo":  { "allowed": false, "reason": "PLAN_REQUIRED", "remaining_generations": 0 },
    "ai_photo":      { "allowed": true,  "reason": null,            "remaining_generations": 1 },
    "ai_rewrite":    { "allowed": false, "reason": "PLAN_REQUIRED", "remaining_generations": 0 }
  }
}
```

`remaining_generations: null`은 한도 없음이다.

**한도는 생성에만 걸린다.** 재생·다운로드·조회는 권한만 보고 횟수를 세지 않는다.
챕터별로 세는 항목(`audiobook` 2회, `ai_photo` 1장)은 `GET /books/{id}/audiobook`처럼
챕터 단위 응답에서 챕터별 잔여를 따로 준다.

**이 응답은 화면이 잠금을 그리라고 주는 값이다.** 접근 통제가 아니다.
생성·조회·스트림·다운로드 각 요청에서 서버가 다시 판정한다. 버튼을 숨기거나
비활성으로 만드는 것은 안내일 뿐이고, 클라이언트가 보낸 플랜 값은 근거가 될 수 없다.

### 확정 대기 — 권한

1. **T1~T4의 기능별 권한표.** 랜딩 가격 스펙과 기존 운영 로드맵 사이에 티어
   재정의 이력이 있다. `plan_code`를 문자열로 둔 이유다.
2. **프로모션과 상시 무료 티어의 우선순위.** "사전신청 100명 무료 T2"와
   "상시 무료(챕터1까지)"가 서로 다른 메커니즘으로 공존한다.
3. **결제·주문 모델.** 이 명세의 범위 밖이다. entitlement를 무엇이 부여하는지는
   결제가 붙을 때 정한다.

---

## 12. 문의 (QnA) `[신규]`

```
POST /qna                내 문의 등록
GET  /qna/me             내 문의 목록
GET  /qna/published      공개 게시 문의 (인증 불필요)
```

```json
{ "category": "작성", "question": "음성이 잘 안 들리는데 어떻게 하나요?" }
```

**200 — `GET /qna/me`**

```json
{
  "items": [
    {
      "id": "qa_01", "category": "작성", "question": "…",
      "status": "answered", "answer": "…",
      "created_at": "2026-08-01T09:00:00Z"
    }
  ]
}
```

`GET /qna/published`는 `status: published`이고 답변이 있는 항목만 준다.
**문의자 정보·내부 메모는 공개 응답에 넣지 않는다.**

**FAQ는 API를 만들지 않는다.** 앱 번들의 정적 콘텐츠로 제공한다 —
운영자가 FAQ를 편집해야 한다는 요구가 확정되기 전에는 테이블과 CMS를 추가하지 않는다.

### 확정 대기 — 문의

1. **관리자 권한 모델.** 서버에 관리자 개념이 없어 답변·게시 상태를 바꿀 주체가
   없다. 관리자 인증·운영 UI 위치를 먼저 정해야 한다.
2. **QnA/FAQ의 앱 내 진입 위치.** 설정 하위인지 홈인지.
3. **FAQ 콘텐츠의 전달 방식**과 담당·갱신 절차.
4. 문의 수정·삭제·첨부·답변 알림·SLA는 근거가 없어 범위에 넣지 않았다.

---

## 13. 서버 구현 메모

### 13.1 AI 호출

| 시점 | 입력 | 출력 |
|------|------|------|
| 꼬리질문 생성 (§5.1) | 장 제목, 원질문, 1차 답변 | 요약+공감+질문 한 덩어리 |
| 윤문 (§5.2) | 원질문, 1차 답변, 꼬리질문·꼬리답변 N쌍 | 작가체 본문 |
| 챕터 종합 (§9.2) | 장 제목, 그 장의 모든 확정 답변 | 자서전 문체의 챕터 원고 |

- 프롬프트는 코드에 박지 말고 **테이블에 둔다** (`prompt_template`). 문구 조정이 배포 없이 되어야 한다
- 각 호출은 서버 내부에서 2회까지 재시도한 뒤 실패로 판정한다
- 호출 이력은 `ai_generation_log`에 남기되 **본문(프롬프트·응답)은 남기지 않는다** — 민감 개인정보다
- 사용자별 문체 메모리(웹 `user_style_memory`)는 2차

### 13.2 사용자별 스냅샷

목차 생성(§2.2) 시점에 카탈로그(대주제·질문)를 **책별로 복제**한다.

- 이유 1: 질문 문구 수정(§4.4)이 다른 사용자에게 번지면 안 된다
- 이유 2: 카탈로그 질문이 나중에 바뀌어도 이미 쓰기 시작한 자서전은 흔들리면 안 된다
- `user_question.text`가 그 사람이 실제로 본 문장이고, `answer.question_text`에 답변 시점의 문구를 한 번 더 박제한다

### 13.3 트랜잭션 경계

여러 표를 한 번에 바꿔야 하는 지점이다. 나뉘면 사용자가 갇힌다.

| 경계 | 이유 |
|------|------|
| 자기소개 제출 → 케이스 판정 → 목차 생성 (§2.2) | 답변만 저장되고 목차가 없으면 자기소개를 다시 할 수도, 진행할 수도 없다 |
| 가입 → 사용자 생성 + 동의 이력 (§1.10) | 약관에 동의하지 않은 계정이 생겨서는 안 된다 |
| 답변 확정 → 저장 + 장 진행 (§5.2) | 저장만 되고 진행이 안 옮겨지면 같은 질문이 계속 나온다. 사용자 눈에는 저장이 안 된 것으로 보인다 |
| job 생성 → 한도 차감 (§10.4) | 차감 없이 생성되면 한도가 무의미하고, 차감만 되면 사용자가 손해를 본다 |

### 13.4 개인정보

자서전 본문은 민감한 개인 기록이다.

- 답변 원문·윤문 결과·챕터 원고는 저장 시 암호화 대상으로 본다
- AI 제공자에 보내는 데이터의 학습 이용 여부를 계약에서 차단할 것
- **이미지·영상 생성은 본문을 외부로 보낸다.** 고지와 명시적 동의가 선행되어야 한다
- 생성 파일(PDF·MP3·MP4)은 비공개 저장소에 두고 인증된 스트림 또는 짧은 수명 URL로만 내보낸다
- 생성·재생·다운로드 접근 로그를 남긴다
- 생년월일·가족·학업·작성 가능 시간은 민감 프로필 데이터다. 보존 기간과 열람 범위를 정한다

---

## 14. 앱 코드와의 대응

### 14.1 `ApiClient` 메서드 ↔ 엔드포인트

| `lib/core/network/api_client.dart` | 엔드포인트 |
|---|---|
| `requestVerificationCode(phone)` | `POST /auth/phone/code` |
| `verifyCode(phone, code)` | `POST /auth/phone/verify` |
| `loginWithKakao()` | `POST /auth/kakao` |
| `me()` | `GET /users/me` |
| `logout()` | `POST /auth/logout` |
| `verificationCodeTtl` | **삭제** → §1.1의 `expires_in` |
| `introQuestions()` | `GET /intro/questions` |
| `generateToc(answers)` | `POST /intro/answers` |
| `confirmToc(chapters)` | `POST /intro/toc/confirm` |
| `introProfile()` | `GET /intro/profile` |
| `home(bookId)` | `GET /books/{book_id}/home` |
| `chapters(bookId)` | `GET /books/{book_id}/chapters` |
| `currentQuestion(bookId)` | `GET /books/{book_id}/questions/current` |
| `question(id)` | `GET /questions/{id}` |
| `saveAnswer(questionId, text)` | **분해** → `POST /questions/{id}/answer` + `POST …/followup/{fid}/answer` |
| `skipQuestion(id)` | `POST /questions/{id}/skip` |
| `book(bookId)` / `bookDetail(bookId)` | `GET /books/{book_id}` |
| `bookPages(bookId)` | `GET /books/{book_id}/pages` |
| `notifications()` | `GET /notifications` |
| `markAllNotificationsRead()` | `POST /notifications/read-all` |
| `settings()` / `updateSettings()` | `GET` / `PATCH /settings` |
| `shippingAddress()` / `updateShippingAddress()` | `GET` / `PUT /shipping-address` |
| — (신규) | `PATCH /questions/{id}` (문구 수정) |
| — (신규) | `POST /auth/refresh` |

**To-Be에서 늘어나는 메서드**

`ApiClient`는 추상 인터페이스이므로 `RealApiClient`와 `MockApiClient`를 **함께** 맞춰야
화면 테스트와 계약 검증이 갈라지지 않는다.

| 신규 메서드 | 엔드포인트 | 절 |
|---|---|---|
| `lookupPhone` / `requestOctomoChallenge` / `verifyOctomo` / `signUp` | `/auth/phone/lookup`, `/auth/octomo/*`, `/auth/signup` | §1.7~1.10 |
| `consentDocuments()` | `GET /consents/documents` | §1.11 |
| `withdraw()` | `DELETE /users/me` | §1.12 |
| `catalogChapters(bookId)` | `GET /catalog/chapters` | §2.3 |
| `saveTocDraft(bookId, chapters)` | `PATCH /intro/toc/draft` | §2.4 |
| `writingPlan()` / `updateWritingPlan()` | `GET` / `PUT /intro/writing-plan` | §2.6 |
| `saveDraft` / `loadDraft` / `deleteDraft` | `/questions/{id}/draft` | §5.6 |
| `synthesizeSpeech` / `transcribe` | `POST /voice/tts`, `POST /voice/stt` | §5.7 |
| `voiceSample(voiceCode)` | `GET /voice/sample` | §5.8 |
| `chapterCompletion(bookId, chapterId)` | `GET /books/{id}/chapters/{id}/completion` | §5.9 |
| `books()` / `createBook()` / `bookDetail(bookId)` | `/books`, `/books/{id}` | §6.1~6.2 |
| `chapterReview(bookId, chapterId)` / `synthesizeReview` / `saveReview` | `/books/{id}/chapters/{id}/review` | §9 |
| `ebookEligibility` / `generateEbook` / `downloadEbook` | `/books/{id}/ebook/*` | §10.1~10.2 |
| `audiobook*` (9종) | `/books/{id}/audiobook/*` | §10.4 |
| `entitlements(bookId)` | `GET /books/{id}/entitlements` | §11 |
| `submitQna` / `myQna` / `publishedQna` | `/qna*` | §12 |
| `registerPushToken` | `POST /device-push-tokens` | §7.3 |

**기존 메서드 중 시그니처가 바뀌는 것**

| 메서드 | 변화 |
|---|---|
| `introQuestions()` | 응답에 `answer_type`·`skippable`·`choices[].details` 추가 |
| `generateToc(Map<String, String>)` | **타입이 바뀐다** — 건너뛰기·상세 선택·복수 선택·날짜를 단일 문자열로 표현할 수 없다 |
| `confirmToc(chapters)` | 204 → `book_id`를 담은 200 |
| `chapters()` / `currentQuestion()` / `bookPages()` | `bookId` 인자를 받는다 |
| `submitFollowupAnswer(...)` | 응답이 `followup` 또는 `next_question` 둘 중 하나로 갈린다 |

### 14.2 앱에 필요한 변경

**반영 완료**

1. ✅ **꼬리질문 단계 추가** — `WriteStage`에 `generatingFollowup` / `saving` / `followupFailed`가 붙었다.
   1차 답변과 꼬리답변은 **같은 화면(ask·recording·keyboard·confirm)을 다시 쓰고** `isFollowup` 하나로 갈린다 —
   시니어 사용자가 배워야 할 화면을 늘리지 않으려는 것이다.
2. ✅ **`saveAnswer` 분해** — `submitAnswer` + `submitFollowupAnswer` 두 호출로 나뉘었다
3. ✅ **`FOLLOWUP_FAILED` 처리** — 전용 화면(D9)에서 같은 질문을 처음부터 다시 받는다
4. ✅ **`POLISH_FAILED` 처리** — 기존 D5 저장 실패 화면을 그대로 재사용한다
5. ✅ **AI 대기 화면** — 30~60초 무반응은 "앱이 멈췄다"로 읽힌다. D7·D8 전용 로딩을 추가했다
6. ✅ **`input_mode` / `spoken_seconds` 전달** — 음성·키보드를 서버가 구분한다

7. ✅ **`verificationCodeTtl` 제거** — 서버가 준 `expires_in`으로 타이머 (§1.1).
   만료와 재발송 대기를 분리했다 — 예전에는 하나로 묶여 있어 문자가 안 온 사람이
   3분을 기다려야 "다시 받기"가 눌렸다
8. ✅ **리프레시 토큰 저장·갱신** (§1.4). 액세스 토큰이 만료되면 `restore()`가
   리프레시로 한 번 되살린다. 리프레시까지 실패해야 로그인 화면으로 보낸다
9. ✅ **질문 문구 수정** (§4.4) — `⋯` 메뉴 → 바텀시트(D10)

10. ✅ **401 인터셉터** — `AuthInterceptor`가 `TOKEN_EXPIRED`에서만 갱신을 시도하고
    원래 요청을 1회 재시도한다. 갱신을 `Future<bool>?` 하나로 묶어 동시 401이
    여러 번 갱신을 쏘지 않게 했다

**남은 것**

11. ⬜ **리프레시 토큰을 보안 저장소로** — 지금은 GetStorage(평문 파일)에 있다.
    60일짜리라 새어 나가면 피해가 크다. `flutter_secure_storage`로 옮길 때
    가장 먼저 옮겨야 할 값이다
12. ⬜ **`generateToc`의 입력 타입 교체** — `Map<String, String>`으로는 건너뛰기·
    상세 선택·복수 선택·날짜를 표현할 수 없다(§2.2). 모델과 두 구현체
    (`RealApiClient`·`MockApiClient`)를 함께 바꿔야 한다
13. ⬜ **`bookId` 전달 경로** — Flutter에 웹식 `[id]` 경로를 만들지 않는다.
    정적 GetX 라우트를 유지하고 `Get.toNamed(..., arguments: {'bookId': ...})`로
    넘긴다. 바인딩·컨트롤러가 argument를 검증하고 API 요청에 싣는다
14. ⬜ **PDF 뷰어 의존성** — `dio`·`path_provider`·`open_filex`는 있으나
    PDF 렌더링 패키지가 없다. 라이선스·플랫폼 지원·대용량 성능을 비교해 고른다
15. ⬜ **오디오 재생 패키지** — 오디오북 재생·백그라운드 재생용. 현재 없다

### 14.3 Figma 신규 프레임

파일: `PickDam` / 섹션 `★★ 최종 · A~F 전체 (C+ 방향)` / D 행 (y=3032)

| 프레임 | node-id | 대응 |
|--------|---------|------|
| D6 꼬리질문 · 음성 대기 | `397:2` | `AskStage` + 배지 (`isFollowup=true`) |
| D7 꼬리질문 준비 중 | `398:6` | `AiLoadingStage` (`generatingFollowup`) |
| D8 이야기 정리 중 | `398:30` | `AiLoadingStage` (`saving`) |
| D9 꼬리질문 실패 | `397:26` | `FollowupFailedStage` |
| D10 질문 문구 고치기 | `401:2` | `showQuestionEditSheet` |

#### 작성 화면(D1·D2·D6)의 세로 배치 규칙

**아래에서부터 고정, 질문판이 나머지.** 화면 높이가 달라져도 이 규칙만 지키면 된다.

```
                     ↑ 남는 자리 전부 (판은 이 안에서만 큰다)
질문판                  최소 244. 넘치면 판 안에서 스크롤
   └ 받아쓴 글          D2만. 판 아래 빈자리에 **겹쳐** 뜬다 (자리를 안 뺏는다)
─────────────────
파문 여백 26            AppMicButton.bloom
마이크 160              ┐
간격 22                 │
라벨 22                 ├ 여기부터 아래는 **자리 고정** (282 + 62)
간격 28                 │
글로 답하기 50           ┘
아래 여백 62
```

- 844 화면이면 마이크 위쪽이 y=500에 온다. **D1·D2·D6이 모두 같은 값**을 써야
  녹음을 시작해도 버튼이 손 밑에서 움직이지 않는다.
- **D1과 D2의 질문판은 크기가 같다.** 말하는 동안에도 질문을 보며 답해야 한다.
  받아쓴 글에 자리를 내주느라 판이 줄어들면 정작 답할 때 질문이 안 보인다.
- 질문판에 **고정 상한을 두지 않는다.** 예전에 348을 박아 뒀더니 큰 기기에서는
  남는 자리를 두고도 글이 스크롤에 갇혔고, 작은 기기에서는 마이크를 밀어냈다.
- 꼬리질문 글자는 **명조 20**(1차 질문은 28). 원래 질문의 서너 배라 28로는 넘친다.

이 규칙은 `test/widget/write_stage_layout_test.dart`가 잰다 — D1·D2의 질문판 크기와
마이크 위치가 같은지 확인한다.

**"다시 들려주기"는 스크롤 영역 밖에 있다.** 스크롤하는 건 질문 글뿐이고, 이 링크는
늘 판 안에 남는다. 함께 스크롤시켰더니 긴 꼬리질문에 밀려 화면 밖으로 잘려 나갔다.

**"녹음 중"은 버튼에서 번지는 파문이 알린다.** 물에 돌을 던진 것처럼 원 셋이 밖으로
커지며 옅어진다(2.2초). 예전에는 버튼 위 막대 파형과 아래 "듣고 있어요 · 0:23"이
나눠 맡았는데 세로로 두 자리를 먹어 작은 화면이 깨졌다.
파문은 `Positioned.fill` + `OverflowBox`라 **자리를 차지하지 않는다.**
기기에서 애니메이션을 꺼 둔 사용자에게는 돌리지 않는다.

꼬리질문 · 녹음 중 / 글자 입력 / 답변 확인은 D2·D3·D4와 질문 글만 다르므로 프레임을 따로 만들지 않았다.
D6의 줄바꿈은 실기기에서 실제로 접히는 자리를 옮긴 것이다 — 앱은 어절 단위로 끊고(`keepAll`),
Figma는 그 결과를 손으로 적어 둔다.

---

## 15. 남은 항목

### 15.1 v1 열린 항목의 현재

| 항목 | 그때 | 지금 |
|------|------|------|
| 회원 탈퇴 | 화면에 없음 | **계약 확정** — `DELETE /users/me` (§1.12). 보존·파기 정책은 미정 |
| 이용약관·개인정보 처리방침 | 문서 URL 필요 | **계약 확정** — `GET /consents/documents` (§1.11). 실제 URL은 미정 |
| 완성된 책 파일(PDF/DOCX) | 앱 시안에 없어 제외 | **범위에 들어옴** — §10.1~10.2 |
| TTS(질문 읽어주기) | 서버 TTS와 OS TTS 중 미정 | **서버 TTS로 확정** — §5.7. 제공자 키를 앱에 두지 않기 위해서다 |
| 사진 첨부 | 2차 | **리뷰 화면에 한정해 들어옴** — §9.1·§9.5. 작성 화면은 여전히 없다 |
| 자녀 계정 연결 (`child_linked`) | 필드만 있고 흐름 없음 | 그대로. 가족 공유 참여자 모델과 함께 정한다 |
| 인쇄본 주문·결제 | 앱 2차 | 그대로. entitlement를 무엇이 부여하는지와 함께 정한다 |

### 15.2 이 명세에 없는 것

계약을 만들지 않았다. 확정되면 해당 절에 추가한다.

| 항목 | 왜 |
|------|-----|
| 스토리북(AI 영상 그림책) | **앱 비범위.** 웹 전용 후처리다 |
| 팩트 체크 | 화면 문서에서도 향후 TODO. 모델이 제안 단계다 |
| 가족 공유 참여자 | 권한·초대·철회·감사 로그가 정해지지 않았다 |
| 관리자 기능 | 서버에 관리자 개념 자체가 없다 |
| 결제·주문 | entitlement의 부여 주체가 미정 |
| 인생 방향 케이스(`direction_*`) | 웹에만 있고 앱 범위 밖 |
| FAQ API | 앱 번들 정적 콘텐츠로 두기로 결정했다 (§12) |

### 15.3 결정 기록

확정 대기에 있다가 결정되어 본문에 반영된 것들이다. 되짚어 볼 수 있게 근거를 남긴다.

| 날짜 | 결정 | 근거 | 버린 안 |
|------|------|------|--------|
| 2026-08-03 | **`reviewed`는 `chapter_review`가 단일 정의.** 웹 `chapter_notebook`은 이관 | 산출물이 고정할 원고 `version`을 원고 소유자가 들고 있어야 한다 | `done`을 그대로 간주 (리뷰 화면이 사라진다) / 웹이 원본 (두 DB를 거쳐야 한다) |
| 2026-08-03 | **건너뛴 결혼·자녀는 축을 `false`로 파생** = 해당 장을 뺀다 | 빈 장은 장 순차 잠금 때문에 뒤 장까지 막는다. 목차 편집으로 되돌릴 수 있다 | `has_*`를 nullable로 (케이스가 8 → 27개) |
| 2026-08-03 | **계정 식별은 번호 단독 unique 유지.** 바뀌는 건 생성 시점 | 복합 unique는 이름만 바꿔 무한 가입이 된다. 덤으로 기존 사용자 이관이 없어졌다 | `(name, phone)` 복합 unique |
| 2026-08-03 | **꼬리질문은 전체 3라운드** (최초 + 후속 2회). 상한은 설정값 | v1이 2라운드였다. 시니어에게 한 질문마다 네 번 말하게 하면 이탈이 크다 | 후속 3회 (총 4번) / v1 그대로 1회 |
| 2026-08-03 | **`book.status`는 컬럼이 아니라 파생값.** "제작 완료" = 모든 장 `reviewed` | 저장하면 갱신 주체가 필요하고 어긋나면 "완료인데 전자책이 안 나온다"가 된다 | 4값 enum 저장 / 완료 기준을 `done`으로 |
| 2026-08-03 | **가족 공유는 v1에 없다.** 대신 `:bookId` 조회를 판정 함수 하나로 좁힘 | 화면 문서가 일관되게 미래 모델로 뒀다. 나중에 표 1개 + 함수만 고치면 된다 | `book_participant` 최소 모델을 지금 추가 |
| 2026-08-03 | **학업 상세는 대학교 이상에서만.** 초등학교의 국민학교 표기는 유지 | "중학교 + 박사"가 `education_detail`에 원본으로 남으면 쓸 수 없는 값이 된다 | 화면 문서대로 세 단계 모두 |
| 2026-08-03 | **오디오북 한도는 생성 2회.** 재생·다운로드 무제한 | 비용이 드는 건 TTS 생성이다. 만든 파일을 두 번밖에 못 듣게 하면 납득하기 어렵다 | 생성·다운로드 각각 2회 / 다운로드만 2회 |
| 2026-08-03 | **건너뛰기는 답변 유무로 갈린다.** 1차 답변 후면 윤문해 확정 | 화면 문서의 모순된 두 문장은 건너뛰기 버튼이 두 화면에 있어서다. 말한 이야기를 버리지 않는다 | 언제나 폐기 / 언제나 윤문 |
| 2026-08-03 | **전자책은 `reviewed`된 장을 전부 담는다** | 규칙이 하나면 챕터1이 자연히 최소 조건이 된다. 3장 리뷰하고 1장만 받는 상황을 없앤다 | 챕터1만 부분 전자책 / 모든 장 완료 시에만 |
| 2026-08-03 | **`다시 답하기`·`기존 답에 추가`는 §5.1 재호출.** 새 계약 없음 | 답변이 바뀌면 꼬리질문도 다시 만들어야 한다. 앱이 입력칸을 비우냐 채우냐만 다르다 | 전용 엔드포인트 2개 / draft PUT만 |
| 2026-08-03 | **사용자 정의 장의 질문은 AI가 제목으로 생성.** 실패 시 범용 3개 | 범용 질문을 심으면 모든 커스텀 장이 같은 질문을 받아 장을 나눈 의미가 없다 | 범용 질문 고정 / 사용자가 직접 작성 |
| 2026-08-04 | **다권 `book.id` 확정. 레거시 단일 경로 제거.** `/books/{book_id}/…`만 사용. 홈도 `GET /books/{book_id}/home` | ERD·문서가 다권을 전제하는데 이중 경로를 두면 어긋난 채로 굳는다. 첫 책은 `POST /intro/answers`가 생성 | `/book`·`/chapters`를 첫 책으로 해석하는 전환 호환 / `book_id = user_id` |

### 15.4 절별 확정 대기 색인

각 절 끝에 붙어 있다. 결정이 필요한 순서대로 읽으려면 여기부터.

| 절 | 핵심 미결 |
|----|----------|
| §1 인증 | v1 OTP와 OCTOMO의 관계, 탈퇴 처리, 약관 운영 |
| §2 자기소개·목차 | 기간 추천 공식, 작성 후 목차 편집, 성함 문항의 거취 |
| §5 작성 | 재답변 시 버전 보존, 전사 후 자동 확정, 튜토리얼 저장 위치 |
| §6 책 | 새 책 생성 방식, 가족 공유(v1 제외 확정), 하단 정보 노출 |
| §7 알림 | 발송 경로 전체, 알림 카드 X의 의미 |
| §9 리뷰 | 웹 원고 이관 절차, AI 사진 슬롯 규칙 |
| §10 산출물 | 진행률 80%의 분모, 한도 복구 시점, 파일 제공 방식 |
| §11 권한 | T1~T4 권한표, 프로모션 우선순위 |
| §12 문의 | 관리자 권한 모델 |

**스키마와 계약 모양을 바꾸는 미결은 이제 대부분 정리됐다.** 남은 것 중 계약에
닿는 건 §5의 재답변 버전 보존과 §9의 웹 원고 이관 절차 정도이고, 나머지는
값·정책이거나 외부 확인(제공자 계약·법무·사업·디자인)이 필요한 것들이다.
