# PickDam API 명세 (v1)

앱(Flutter) 기준 서버 계약. 산출 근거는 Figma 시안을 옮긴 현재 앱 코드와
`lib/core/network/api_client.dart`의 추상 인터페이스다.

- 대상 클라이언트: Flutter 앱 1종 (웹 `lifelegacy-web`은 별도 서비스, 이 명세의 대상 아님)
- 1차 범위 제외: 사진 첨부, 관리자, 승인·결제·인쇄 발주, 인생 방향 케이스(`direction_*`)

---

## 0. 공통 규약

### 0.1 기본

| 항목 | 값 |
|------|-----|
| Base URL | `https://api.pickdam.app/v1` |
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

### 0.5 호출 제한

| 대상 | 제한 |
|------|------|
| `POST /auth/phone/code` | 전화번호당 5회 / 1시간 |
| `POST /questions/{id}/answer` (AI 호출) | 사용자당 60회 / 시간 |
| 그 외 | 사용자당 100회 / 10초 |

---

## 1. 인증

### 1.1 인증번호 발송

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

### 1.2 인증번호 확인 (로그인/가입)

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

### 1.3 카카오 로그인

```
POST /auth/kakao
```

```json
{ "kakao_access_token": "…" }
```

**200** — `AuthSession` (§1.2와 동일)

카카오 계정에 전화번호가 없으면 `needs_phone: true`를 함께 내려보내고, 앱은 전화번호 화면으로 보낸다.

> 📌 현재 앱은 카카오 SDK를 붙이지 않았다. `MockApiClient.loginWithKakao()`가 바로 세션을 돌려준다.

### 1.4 토큰 갱신

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

### 1.5 내 정보

```
GET /users/me
```

**200** — `User` (§1.2의 `user`와 동일 형태)

### 1.6 로그아웃

```
POST /auth/logout
```

**204**. 리프레시 토큰을 폐기한다.

---

## 2. 자기소개 → 목차

### 2.1 자기소개 문항

```
GET /intro/questions
```

인증 필요. **5문항 고정**이며 순서대로 내려준다.

**200**

```json
{
  "items": [
    {
      "id": "i1", "order": 1,
      "text": "성함을\n알려주세요",
      "subtitle": "책 표지에 들어갈 이름이에요",
      "hint": "성함을 적어 주세요",
      "choices": []
    },
    {
      "id": "i5", "order": 5,
      "text": "학교는 어디까지\n다니셨나요?",
      "subtitle": "학창 시절 질문을 고를 때 써요",
      "hint": null,
      "choices": ["초등학교", "중학교", "고등학교", "대학교 이상"]
    }
  ]
}
```

| 필드 | 설명 |
|------|------|
| `text` | 화면 제목. **`\n`이 줄바꿈 위치다** — 시안이 두 줄로 끊어 놓은 자리라 서버가 그대로 준다 |
| `subtitle` | 왜 묻는지 알려주는 한 줄 |
| `hint` | 입력칸 placeholder. `choices`가 비었을 때만 쓴다 |
| `choices` | 비어 있으면 텍스트 입력, 있으면 선택지. 앱은 **세로로 쌓아** 그리며 개수 제한이 없다 |

앱은 `choices`의 유무로 입력 방식을 정한다(`IntroAnswerType`). 별도 `type` 필드는 두지 않는다.

### 2.2 자기소개 제출 → 목차 생성

```
POST /intro/answers
```

```json
{
  "answers": [
    { "question_id": "i1", "value": "김영희" },
    { "question_id": "i2", "value": "여성" },
    { "question_id": "i3", "value": "했어요" },
    { "question_id": "i4", "value": "있어요" },
    { "question_id": "i5", "value": "대학교 이상" }
  ]
}
```

**답변은 고른 문자열 원본을 그대로 보낸다.** 서버가 `대학 O/X` 같은 불리언으로 접어서
저장하지 않고 원본을 남긴다 — 나중에 "고등학교 졸업"과 "중학교 졸업"을 나눠 질문을
주고 싶어질 때 데이터가 있어야 한다. 케이스 판정값은 원본에서 파생시킨다.

**200**

```json
{
  "case_key": "legacy_college_married_children",
  "chapters": [
    {
      "id": "c_01", "order": 1, "title": "탄생과 유아기 시절",
      "status": "writing", "answered_count": 0, "question_count": 5,
      "next_question_text": null
    },
    {
      "id": "c_02", "order": 2, "title": "가족환경과 성장환경",
      "status": "locked", "answered_count": 0, "question_count": 5,
      "next_question_text": null
    }
  ]
}
```

- 케이스 판정 규칙과 8종 정의는 [`목차-케이스.md`](목차-케이스.md) 참조
- 이 시점에 사용자별 목차·질문 **스냅샷을 복제해 둔다** (§9.2)
- 오래 걸리는 작업이다. 앱은 전용 로딩 화면(B6)을 띄우고 기다린다. **타임아웃 60초**

**에러**: `400 INVALID_REQUEST` (5문항이 다 오지 않음)

### 2.3 목차 확정

```
POST /intro/toc/confirm
```

사용자가 B7에서 "순서 바꾸기"로 재배열했으면 **바뀐 순서 그대로** 보낸다.

```json
{ "chapter_ids": ["c_02", "c_01", "c_03"] }
```

**204**. 서버는 배열 순서대로 `order`를 1부터 다시 매기고, 1번 장을 `writing`,
나머지를 `locked`로 초기화한다. 이후 `needs_intro`는 `false`가 된다.

**에러**: `409 TOC_ALREADY_CONFIRMED`

### 2.4 자기소개 프로필 조회 (F3 내 정보)

```
GET /intro/profile
```

**200**

```json
{
  "entries": [
    { "label": "성별", "value": "여성" },
    { "label": "결혼", "value": "했어요" },
    { "label": "자녀", "value": "있어요" },
    { "label": "학력", "value": "대학교 이상" }
  ]
}
```

라벨과 값을 **서버가 짝지어** 내려준다. 화면이 `i2`·`i5` 같은 질문 id를 알 필요가 없다.
성함(i1)은 이 목록에 넣지 않는다 — 화면 상단에 이미 이름이 있다.

---

## 3. 홈

### 3.1 홈 요약

```
GET /home
```

**200**

```json
{
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
| `today_question` | 지금 답해야 할 질문. `null`이면 앱이 빈 상태 화면을 그린다 |
| `progress` | 0.0~1.0. 전체 질문 중 답변 완료 비율 |

화면 하나가 필요한 값을 한 번에 준다. 서버가 여러 도메인에서 모아야 하더라도 이 모양으로 합쳐서 준다.

---

## 4. 목차 · 질문 조회

### 4.1 장 목록

```
GET /chapters
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

### 4.2 지금 답할 질문

```
GET /questions/current
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

### 4.3 질문 단건

```
GET /questions/{question_id}
```

**200** — §4.2와 동일. **에러**: `404 NOT_FOUND`, `409 CHAPTER_LOCKED`

### 4.4 질문 문구 수정

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
        ▼  200 { next_question, chapter_completed }
        서버: 원문 2개 + 윤문 결과를 확정 저장하고 다음 질문을 돌려준다
```

**질문 1개 = 묶음 1개.** 한 묶음은 (원질문, 1차 답변, 꼬리질문, 꼬리답변, 윤문 결과)로 구성된다.
꼬리질문은 **정확히 1회**다.

**사용자에게 보여주는 것은 자기가 답한 원문뿐이다.** AI가 작가처럼 다듬은 글은 저장만 하고
작성 화면에서는 보여주지 않는다. 처음 눈에 띄는 곳은 자서전 미리보기(§6.2)다.

### 5.1 1차 답변 전송

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

**에러**

| HTTP | code | 처리 |
|------|------|------|
| 409 | `ALREADY_ANSWERED` | 이미 확정된 질문 |
| 409 | `CHAPTER_LOCKED` | 잠긴 장 |
| 422 | `FOLLOWUP_FAILED` | §5.3 |

### 5.2 꼬리질문 답변 → 확정 저장

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

**200**

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
| `next_question` | 다음에 답할 질문. **`null`이면 모든 장을 끝냈다는 뜻** — 앱은 자서전 화면으로 이동 |
| `chapter_completed` | 이 답변으로 장이 끝났으면 `true`. 다음 장이 열린다 |

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

### 5.3 꼬리질문 생성 실패 — 처음부터 다시

AI가 꼬리질문을 만들지 못하면(서버 내부 재시도 후에도) `422 FOLLOWUP_FAILED`.

```json
{ "code": "FOLLOWUP_FAILED", "message": "질문을 만들지 못했어요. 잠시 후 다시 시도해 주세요" }
```

- **서버는 임시 저장한 1차 답변을 폐기한다.**
- 앱은 질문 화면으로 되돌아가 처음부터 다시 답을 받는다.
- 사용자가 답을 다시 해야 한다 — 감수하기로 한 동작이다.

> 📌 확장 지점: 초안을 남겨 두고 `GET /questions/{id}/draft`로 복원하면 다시 답하지 않아도 된다.
> v1에서는 만들지 않는다.

### 5.4 윤문 실패 — 저장만 재시도

`422 POLISH_FAILED`.

```json
{ "code": "POLISH_FAILED", "message": "저장에 실패했어요. 다시 시도해 주세요" }
```

- **초안(1차 답변 + 꼬리질문 + 꼬리답변)은 지우지 않는다.**
- 앱은 이미 있는 저장 실패 화면(D5)에 머물면서 글을 화면에 남겨 두고 "다시 저장하기"를 띄운다.
- "다시 저장하기"는 §5.2를 **같은 파라미터로 재요청**한다. 서버는 멱등하게 처리한다.

꼬리질문 실패(§5.3)와 다른 이유: 그때는 아직 사용자가 한 번밖에 답하지 않았지만, 여기서는
두 번 답한 상태다. 두 번의 이야기를 날리고 처음부터 시키는 건 다른 문제다.

### 5.5 건너뛰기

```
POST /questions/{question_id}/skip
```

**200** — §5.2와 같은 형태

```json
{ "next_question": { … }, "chapter_completed": false }
```

건너뛴 질문은 `skipped`로 표시하고 답변 없이 완료 처리한다. 장의 `answered_count`에는 포함된다
(그래야 장이 끝난다). 자서전 본문에는 실리지 않는다.

---

## 6. 나의 자서전

### 6.1 책 요약

```
GET /book
```

**200**

```json
{
  "title": "나의 이야기",
  "author_name": "김영희",
  "chapter_count": 5,
  "question_count": 40,
  "page_count": 34,
  "photo_count": 0,
  "is_complete": false
}
```

| 필드 | 설명 |
|------|------|
| `question_count` | 책에 실린 질문 수(건너뛴 것 제외) |
| `photo_count` | **v1은 항상 0.** 사진 첨부는 2차 |
| `is_complete` | 모든 장이 `done`이면 `true`. 완성 화면(E3) 진입 조건 |

### 6.2 미리보기 쪽

```
GET /book/pages
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
- 쪽 나누기는 **서버가 계산한다.** 앱은 받은 대로 그린다

---

## 7. 알림

### 7.1 목록

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

### 7.2 모두 읽음

```
POST /notifications/read-all
```

**200** — 갱신된 목록 (§7.1과 동일). 앱이 다시 조회하지 않아도 되게 결과를 돌려준다.

---

## 8. 설정

### 8.1 앱 설정

```
GET  /settings
PATCH /settings
```

```json
{ "daily_question_alarm": true }
```

**200** — 갱신된 `AppSettings`

v1에서 켜고 끌 수 있는 건 "오늘의 질문 알림" 하나뿐이다.

### 8.2 인쇄본 배송지

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

## 9. 서버 구현 메모

### 9.1 AI 호출

| 시점 | 입력 | 출력 |
|------|------|------|
| 꼬리질문 생성 (§5.1) | 장 제목, 원질문, 1차 답변 | 요약+공감+질문 한 덩어리 |
| 윤문 (§5.2) | 원질문, 1차 답변, 꼬리질문, 꼬리답변 | 작가체 본문 |

- 프롬프트는 코드에 박지 말고 **테이블에 둔다** (웹의 `prompt_template`과 같은 방식). 문구 조정이 배포 없이 되어야 한다
- 각 호출은 서버 내부에서 2회까지 재시도한 뒤 실패로 판정한다
- 사용자별 문체 메모리(웹 `user_style_memory`)는 2차

### 9.2 사용자별 스냅샷

목차 확정(§2.3) 시점에 카탈로그(대주제·질문)를 **사용자별로 복제**한다.

- 이유 1: 질문 문구 수정(§4.4)이 다른 사용자에게 번지면 안 된다
- 이유 2: 카탈로그 질문이 나중에 바뀌어도 이미 쓰기 시작한 자서전은 흔들리면 안 된다
- 웹의 `user_content` / `user_question`과 같은 구조다

### 9.3 개인정보

자서전 본문은 민감한 개인 기록이다.

- 답변 원문·윤문 결과는 저장 시 암호화 대상으로 본다
- AI 제공자에 보내는 데이터의 학습 이용 여부를 계약에서 차단할 것
- 접근 로그를 남긴다

---

## 10. 앱 코드와의 대응

### 10.1 `ApiClient` 메서드 ↔ 엔드포인트

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
| `home()` | `GET /home` |
| `chapters()` | `GET /chapters` |
| `currentQuestion()` | `GET /questions/current` |
| `question(id)` | `GET /questions/{id}` |
| `saveAnswer(questionId, text)` | **분해** → `POST /questions/{id}/answer` + `POST …/followup/{fid}/answer` |
| `skipQuestion(id)` | `POST /questions/{id}/skip` |
| `book()` | `GET /book` |
| `bookPages()` | `GET /book/pages` |
| `notifications()` | `GET /notifications` |
| `markAllNotificationsRead()` | `POST /notifications/read-all` |
| `settings()` / `updateSettings()` | `GET` / `PATCH /settings` |
| `shippingAddress()` / `updateShippingAddress()` | `GET` / `PUT /shipping-address` |
| — (신규) | `PATCH /questions/{id}` (문구 수정) |
| — (신규) | `POST /auth/refresh` |

### 10.2 앱에 필요한 변경

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

**남은 것**

10. ⬜ **리프레시 토큰을 보안 저장소로** — 지금은 GetStorage(평문 파일)에 있다.
    60일짜리라 새어 나가면 피해가 크다. `flutter_secure_storage`로 옮길 때
    가장 먼저 옮겨야 할 값이다
11. ⬜ **401 인터셉터** — 지금은 앱 시작(`restore()`)에서만 갱신한다. 실제 dio
    구현이 들어오면 모든 요청이 `TOKEN_EXPIRED`에서 한 번 갱신하고 재시도해야 한다

### 10.3 Figma 신규 프레임

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
─────────────────
받아쓰기 자리 124        D2만. 글이 없어도 비워 둔다
원형 파형 여백 26        AppMicButton.bloom
마이크 160              ┐
간격 22                 │
라벨 22                 ├ 여기부터 아래는 **자리 고정** (282 + 62)
간격 28                 │
글로 답하기 50           ┘
아래 여백 62
```

- 844 화면이면 마이크 위쪽이 y=500에 온다. **D1·D2·D6이 모두 같은 값**을 써야
  녹음을 시작해도 버튼이 손 밑에서 움직이지 않는다.
- 질문판에 **고정 상한을 두지 않는다.** 예전에 348을 박아 뒀더니 큰 기기에서는
  남는 자리를 두고도 글이 스크롤에 갇혔고, 작은 기기에서는 마이크를 밀어냈다.
- D2의 질문판이 244보다 얇아지는 건 정상이다(844에서 202). 받아쓰기 자리를
  내주고 남은 만큼만 쓴다.
- 꼬리질문 글자는 **명조 20**(1차 질문은 28). 원래 질문의 서너 배라 28로는 넘친다.

**"다시 들려주기"는 스크롤 영역 밖에 있다.** 스크롤하는 건 질문 글뿐이고, 이 링크는
늘 판 안에 남는다. 함께 스크롤시켰더니 긴 꼬리질문에 밀려 화면 밖으로 잘려 나갔다.

**"녹음 중"은 버튼 둘레의 원형 파형이 알린다.** 예전에는 버튼 위 막대 파형과 아래
"듣고 있어요 · 0:23"이 나눠 맡았는데 세로로 두 자리를 먹어 작은 화면이 깨졌다.
파형은 `Positioned.fill` + `OverflowBox`라 **자리를 차지하지 않는다.**

꼬리질문 · 녹음 중 / 글자 입력 / 답변 확인은 D2·D3·D4와 질문 글만 다르므로 프레임을 따로 만들지 않았다.
D6의 줄바꿈은 실기기에서 실제로 접히는 자리를 옮긴 것이다 — 앱은 어절 단위로 끊고(`keepAll`),
Figma는 그 결과를 손으로 적어 둔다.

---

## 11. 열린 항목

| 항목 | 상태 |
|------|------|
| 회원 탈퇴 | 설정 화면에 없다. 스토어 심사에서 요구되면 `DELETE /users/me` 추가 |
| 자녀 계정 연결 (`child_linked`) | 모델에 필드만 있고 흐름이 없다 |
| 인쇄본 주문·결제 | 웹에는 `approval_request`가 있다. 앱 2차 |
| 사진 첨부 | 2차 확정 |
| 이용약관·개인정보 처리방침 | 앱이 "준비 중"만 띄운다. 문서 URL 필요 |
| 완성된 책 파일(PDF/DOCX) 내려받기 | 웹에는 있다. 앱 시안에 없어 제외 |
| TTS(질문 읽어주기) | 앱에 자리만 있다(`replayQuestion`). 서버 TTS 붙일지, OS TTS 쓸지 미정 |
