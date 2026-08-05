# DB 스키마 요약 (Nest / `life_legacy`)

로컬 Nest 서버가 쓰는 PostgreSQL DB **`life_legacy`** 기준이다.  
형제 웹앱 lifelegacy(`C:\Users\laptop\Desktop\lifelegacy`)는 Neon **`neondb`**를 쓰며 **이 DB와 공유하지 않는다.**

| 항목 | 값 |
|---|---|
| DB 이름 | `life_legacy` (로컬 `.env.local`) |
| ORM | TypeORM (`server/src/**/entities`) |
| 로컬 스키마 반영 | `DB_SYNCHRONIZE=true` (운영은 `false` + DDL) |
| 시드 | `cd server && npm run seed` |
| 상세 ERD (DBML) | [`erd/new-erd.dbml`](../erd/new-erd.dbml) — [dbdiagram.io](https://dbdiagram.io) |
| 엔티티 공통 | UUID PK · `created_at` / `updated_at` (`BaseModel`) |

현재 로컬 DB 기준 **약 40개 테이블**.

---

## 도메인 묶음

```text
[카탈로그·시드]          [사용자·인증]           [자기소개·목차]
chapter_template         app_user                intro_question / intro_choice
question_template        social_account          user_intro_answer
case_definition          refresh_token           case_definition → user_profile
prompt_template          phone_verification      writing_plan
consent_document         auth_verification_session
bgm_track                user_consent
                         device_push_token
                         user_setting
                         shipping_address

[책·진행]                [작성]                   [산출·후처리]
book                     answer_draft            chapter_review
user_chapter             answer                  ebook_export
user_question            answer_followup         audiobook_job / _part
book_page                                        storybook_job / beat
                                                 media_asset / media_placement

[권한]                   [부가]
user_entitlement         notification
entitlement_ledger       ai_generation_log
                         qna_question
```

---

## 핵심 관계 (작성 플로우)

다권 모델: 사용자는 여러 `book`을 가질 수 있고, 장·질문은 **책 단위**로 매달린다.

```text
app_user
  └── book (owner_user_id)
        ├── user_chapter (sort_order, status…)
        │     └── user_question (text 사본 — 템플릿에서 복사)
        │           ├── answer_draft   ← 확정 전 초안 (있으면 진행 중)
        │           ├── answer         ← 확정 원문 + polished_text
        │           └── answer_followup (seq 1..N)  ← 꼬리 Q&A
        ├── book_page
        ├── chapter_review
        ├── ebook_export / audiobook_* / storybook_*
        └── …
```

### 질문 → 답변 → 재질문

1. 사용자가 `user_question`에 1차 답 → `answer_draft`에 저장 + AI `second_question` 프롬프트로 꼬리질문 생성  
2. 꼬리답변을 이어 받으면 `draft.followups`에 쌓임 (`FOLLOWUP_MAX_ROUNDS`, 기본 2회 꼬리)  
3. 마지막 라운드에서 `polish` / `polish_sparse`로 윤문 → `answer` + `answer_followup` 확정, draft 삭제  

프롬프트 본문은 **`prompt_template`** (`second_question`, `polish`, `polish_sparse`).  
시드: `server/src/ai/seed/prompt.seed.ts` (lifelegacy 웹 기본 문구와 맞춤).

---

## 테이블 역할 한눈에

| 묶음 | 테이블 | 역할 |
|---|---|---|
| **카탈로그** | `chapter_template`, `question_template` | 장·질문 원본. 사용자에게는 **복사**되어 나감 |
| | `intro_question`, `intro_choice` | 자기소개 5문항·선택지 |
| | `case_definition` | 결혼·자녀 등으로 목차 케이스 판정 |
| | `prompt_template` | AI 프롬프트 (배포 없이 문구 조정) |
| | `consent_document` | 약관 문서 버전 |
| | `bgm_track` | 오디오북 BGM 메타 |
| **사용자** | `app_user` | 계정. `normalized_phone` unique |
| | `user_profile` | 자기소개 파생 프로필 |
| | `social_account` | 카카오 등 |
| | `user_setting`, `shipping_address`, `device_push_token` | 설정·배송·푸시 |
| **인증** | `auth_verification_session` | OCTOMO 등 세션 |
| | `phone_verification` | (레거시/보조) 번호 인증 |
| | `refresh_token` | 리프레시 토큰 해시 |
| | `user_consent` | 약관 동의 기록 |
| **자기소개** | `user_intro_answer` | 원본 답 (건너뜀 포함) |
| | `writing_plan` | 목차 확정 전 작성 계획 |
| **책·진행** | `book` | 다권. PK=`id`, 소유=`owner_user_id` |
| | `user_chapter` | 책의 장 사본·상태 |
| | `user_question` | 장 안 질문 사본 (`text`는 사용자가 본 문장) |
| | `book_page` | 미리보기 페이지 캐시 자리 |
| **작성** | `answer_draft` | 확정 전. phase / followup_id / followups JSON |
| | `answer` | 확정 답 + 윤문 본문 |
| | `answer_followup` | 확정된 꼬리 질문·답 (`seq`) |
| **리뷰·미디어** | `chapter_review` | 장 단위 reviewed 원고 |
| | `media_asset`, `media_placement` | 파일 메타·배치 |
| | `ebook_export` | 전자책 내보내기 |
| | `audiobook_job`, `audiobook_job_part` | TTS 작업 |
| | `storybook_job`, `storybook_beat` | 스토리북(웹 쪽 확장) |
| **권한** | `user_entitlement` | feature별 플랜 (예: audiobook T1) |
| | `entitlement_ledger` | 생성 한도 소모 이력 |
| **부가** | `notification` | 인앱 알림 |
| | `ai_generation_log` | AI 호출 로그 자리 (쓰기 미완일 수 있음) |
| | `qna_question` | 고객 QnA |

---

## 설계 원칙 (짧게)

1. **템플릿은 참조가 아니라 복사** — `user_question.text` / `answer.question_text`에 당시 문구를 박제. 원본 개정해도 이미 답한 사람 질문이 바뀌면 안 됨.  
2. **다권** — API는 `/v1/books/{bookId}/…` 만. “첫 책” 레거시 경로 없음.  
3. **책 완료 상태는 컬럼이 아니라 파생** — 모든 장이 `reviewed`면 완료.  
4. **비밀값은 해시** — 리프레시 토큰 등.  
5. **권한은 서버 판정** — `user_entitlement` + ledger. 로컬은 `AUDIOBOOK_AUTO_GRANT`로 T1 자동 부여 가능.

---

## 관련 문서

| 문서 | 내용 |
|---|---|
| [`erd/new-erd.dbml`](../erd/new-erd.dbml) | 컬럼·FK 전체 |
| [`docs/server-architecture.md`](server-architecture.md) | Nest 모듈·시퀀스 |
| [`docs/api-spec.md`](api-spec.md) | HTTP 계약 |
| [`docs/server-feature-definition.md`](server-feature-definition.md) | 기능 정의·환경변수 |

시드 후 프롬프트 확인 예:

```sql
SELECT key, title, version, left(body, 60) FROM prompt_template ORDER BY key;
-- second_question | polish | polish_sparse
```
