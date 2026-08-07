# OLD(lifelegacy 웹) vs NEW(life-legacy-flutter) DB 스키마 비교

> **작성일:** 2026-08-06  
> OLD 웹(Drizzle)과 NEW Flutter Nest(TypeORM) PostgreSQL 스키마의 표·컬럼·관계 차이를 정리한 문서입니다.

## 근거·범위

| 구분 | 경로 |
|---|---|
| OLD | `C:\Users\laptop\Desktop\lifelegacy\app\lib\db\schema.ts` (+ `app\drizzle\0000`~`0030`) |
| NEW | Nest TypeORM 엔티티 `server\src\**\entities\` (+ `erd\new-erd.dbml`, `server\migrations\`) |

- Flutter 쪽 `erd\web-erd.dbml`은 OLD **초기** 스냅샷이라 `chapter_notebook` / `book_cover` / `audiobook_*` 등이 빠져 있음. 본 문서는 **현재 `schema.ts` 기준**.
- 「딥」에 해당하는 `deep` / `tv` / `티비` 테이블·모듈은 **양쪽 DB에 없음**. 문서의 「딥링크」만 등장. 질문은 **DB(디비)** 차이로 해석.

---

## 1. 각 프로젝트 DB 스택 개요

| | OLD (lifelegacy) | NEW (life-legacy-flutter) |
|---|---|---|
| ORM | **Drizzle ORM** (`drizzle-orm` + `drizzle-kit`) | **TypeORM** (`@nestjs/typeorm`) |
| DBMS | **PostgreSQL** (`postgres` 드라이버, Neon 등) | **PostgreSQL** (`uuid` / `jsonb` / `timestamptz`) |
| 스키마 정의 | `app\lib\db\schema.ts` 단일 소스 | `server\src\**\*.entity.ts` 글롭 로드 |
| 마이그레이션 | `app\drizzle\0000_init.sql` ~ `0030_pre_registration.sql` | `server\migrations\20260804_01`~`04_*.sql` (+ `DB_SYNCHRONIZE=true` 가능) |
| 인증 | NextAuth Drizzle Adapter (`user` / `account` / `session` / `verification_token`) | 전화 SMS OTP + OCTOMO 세션 + JWT refresh (`app_user` / `phone_verification` / `auth_verification_session` / `refresh_token`) |
| PK | `text` UUID 문자열 | `uuid` (`gen_random_uuid`) |
| 미디어 저장 | **BYTEA** in-DB (`answer_attachment`, `photo_inbox`, `book_cover.background_data`, `audiobook_job.data`) | **객체 스토리지 키** (`media_asset.object_key`) |
| 책 모델 | 유저당 암묵적 1권 (`userId` + `case_name`) | 명시적 **다권** `book` (1:N) |
| 표 개수 | **31** | **40** (엔티티 `@Entity` 기준) |

---

## 2. OLD에만 있고 NEW에 없는 표

| OLD 테이블 | 주요 컬럼 | 역할 / NEW에서의 대응 |
|---|---|---|
| `user` | `id`, `email`(unique), `password`, `role`, `phone`, `postal_code`, `road_address`, `address_detail`, `chat_font_size`, `write_ai_mode`, `write_input_mode` | NextAuth 사용자. NEW는 `app_user` + `shipping_address` + `user_setting`으로 분해 |
| `account` | PK(`provider`, `providerAccountId`), OAuth 토큰들 | NEW `social_account`(`provider`, `provider_user_id`) — 카카오 중심, 토큰 컬럼 없음 |
| `session` | `sessionToken`, `userId`, `expires` | 없음 → `refresh_token` |
| `verification_token` | PK(`identifier`, `token`), `expires` | 없음 → `phone_verification` / `auth_verification_session` |
| `profile` | `userId`(unique), `data`(자유텍스트), `case_name` | 없음 → `user_intro_answer` + `user_profile` |
| `outline` | `userId`, `chapters` jsonb | 없음 → `user_chapter` / `book` |
| `content` | `content_id`(unique int), `title`, `sort_order`, `is_required` | 없음 → `chapter_template`(`code` smallint) |
| `question` | `content_id`, `question_id`, `content`, `sort_order` | 없음 → `question_template` |
| `case_content` | `case_key`, `content_id`, `title`, `sort_order` | 없음 — NEW는 `chapter_template.condition`으로 파생 |
| `case_question` | `case_key`, `content_id`, `question_id`, … | 없음 — 케이스별 질문 복제 폐기 |
| `user_content` | `userId`, `case_name`, `content_id`, `title`, `sort_order` | 없음 → `user_chapter`(`book_id`, …) |
| `answer_attachment` | `userId`, `content_id`, `question_id`, `case_name`, **`data` bytea**, `ai_description`, `ai_highlights` | 없음 → `media_asset` + `media_placement` |
| `photo_inbox` | BYTEA + `suggestions` jsonb, `status` pending/applied/discarded | **없음** (일괄 업로드 임시함) |
| `manuscript_edit_history` | `snapshot` jsonb, `format`, `is_active` | **없음** (NEW `chapter_review.version`만) |
| `chapter_notebook` | `userId`, `content_id`, `case_name`, `body`, `ai_draft`, `image_placements`, `review_cache`, `status` draft/reviewed | 개념 대응: `chapter_review` (컬럼·키 다름) |
| `writing_progress` | `current_content_id` / `question_id`, `notebook_*` | 없음 → `user_chapter.status` + `user_question.status` |
| `app_setting` | `key` PK, `value` | **없음** |
| `notebook_review_check` | `key`, `label`, `category`, `default_severity`, `enabled` | **없음** |
| `user_style_memory` | `userId` PK, `style_notes`, `sample_excerpts` | **없음** |
| `approval_request` | `status` pending_review…shipped, `paid_at`, `shipped_at` | **없음** (인쇄/승인 워크플로) |
| `ai_usage_event` | `feature`, `model`, `prompt_tokens`, `cost_usd`, … | 부분 대응: `ai_generation_log` (본문·USD 비용 없음) |
| `book_cover` | `template_id`, `title`, `title_page_title`, `author`, 배경 BYTEA, 레이아웃 컬럼들 | **없음** (`ebook_export.cover_kind`만) |
| `pre_registration` | `name`, `phone`, `email` | **없음** |

---

## 3. NEW에만 있고 OLD에 없는 표

| NEW 테이블 | 주요 컬럼 | 역할 |
|---|---|---|
| `app_user` | `phone`(varchar 11 unique nullable), `name`, `child_linked`, `intro_completed_at`, `last_login_at`, `deleted_at` | 앱 계정 |
| `social_account` | `user_id`, `provider`, `provider_user_id` | 소셜 연동 |
| `phone_verification` | `phone`, `code_hash`, `expires_at`, `attempt_count`, `consumed_at` | SMS OTP |
| `auth_verification_session` | `normalized_phone`, `purpose`, `verify_text`, `receiver_number`, `verified_at`, `consumed_at` | OCTOMO |
| `refresh_token` | `user_id`, `token_hash`(unique), `expires_at`, `revoked_at` | JWT 갱신 |
| `consent_document` | `consent_key`, `version`, `url`, `is_required`, `effective_at` | 약관 버전 |
| `user_consent` | `user_id`, `consent_document_id`, `agreed_at`, `revoked_at`, `channel` | 동의 이력 |
| `device_push_token` | `platform`, `token`(unique), `last_used_at`, `revoked_at` | 푸시 |
| `intro_question` / `intro_choice` / `user_intro_answer` | `answer_type`, `parent_choice_id`, `value_json`, `is_skipped` 등 | 구조화 인트로 |
| `user_profile` | PK=`user_id`, `case_id`, `has_college` / `marriage` / `children`, `birth_date`, `toc_confirmed_at` | 케이스 판정 결과 |
| `writing_plan` | PK=`user_id`, `daily_minutes`, `available_weekdays` / `periods` jsonb, `duration_weeks` | 작성 계획 |
| `chapter_template` / `question_template` | `code`, `condition` enum, FK 연결 | 공용 카탈로그 |
| `book` | `id` PK, `owner_user_id`, `title`, `author_name`, `page_count`, `photo_count`, `is_complete` | **다권** |
| `user_chapter` | `book_id`, `chapter_template_id`, `source_type`, `status` locked/writing/done | 장 스냅샷+잠금 |
| `answer_followup` | `answer_id`, `seq`, `question_text`, `answer_text`, `input_mode` | 꼬리 Q&A 정규화 |
| `chapter_review` | `user_chapter_id`(unique), `body`, `ai_draft`, `version`, `status` draft/reviewed | 종합 원고 |
| `media_asset` / `media_placement` | `kind`, `source`, `object_key`, `paragraph_index`, `anchor` | 미디어+배치 |
| `ebook_export` | `book_id`, `format`, `chapter_snapshot`, `cover_kind`, `media_asset_id` | 전자책 job |
| `bgm_track` | `title`, `object_key`, `license_source`, `is_active` | BGM 카탈로그 |
| `storybook_job` / `storybook_beat` | `media_mode`, `stage`, `narration`, `visual_prompt` | 스토리북(웹 전용 계약) |
| `user_entitlement` / `entitlement_ledger` | `feature`, `plan_code`, `delta`, `idempotency_key` | 권한·한도 |
| `book_page` | `book_id`, `user_chapter_id`, `page_number`, `paragraphs` jsonb | 미리보기 쪽 |
| `notification` | `type`, `title`, `link_user_question_id`, `read_at` | 인앱 알림 (**엔티티에 `book_id` 없음** — ERD와 드리프트) |
| `user_setting` | `daily_question_alarm` | 알림 선호 |
| `shipping_address` | `recipient`, `phone`, `postal_code`, `line1`, `line2` | 배송지 |
| `ai_generation_log` | `kind` enum, `succeeded`, tokens, `user_question_id` / `user_chapter_id` | AI 운영 로그 |

이름만 같은 `audiobook_job` / `audiobook_job_part` / `qna_question` / `prompt_template` / `answer` / `answer_draft` / `user_question` / `case_definition`은 **§4** 참고.

---

## 4. 같은 개념 · 이름 겹치는 표의 컬럼/관계 차이

### 4.1 사용자·인증

| | OLD `user` | NEW `app_user` |
|---|---|---|
| 식별 | `email` unique + optional `password` | `phone` unique (숫자 11자리, nullable) |
| 역할 | `role` text default `user` | 역할 컬럼 없음 |
| 주소 | 유저 테이블에 `postal_code` / `road_address` / `address_detail` | `shipping_address` 분리 |
| 작성 UX 설정 | `chat_font_size`, `write_ai_mode`, `write_input_mode` | **없음** (`user_setting`은 알림만) |
| Soft delete | 없음 | `deleted_at` |

### 4.2 `case_definition`

| OLD | NEW |
|---|---|
| `case_key`, **`group`**(`legacy`\|`direction`), `title`, `description`, `sort_order` | `case_key`, `title`, `description`, **`has_college` / `has_marriage` / `has_children`**, `sort_order` |
| legacy+direction ≈ 15종 (문서) | **8종 = 2×2×2**, unique(`has_*`) |

### 4.3 목차·질문 (`user_question` 등)

| OLD | NEW |
|---|---|
| `user_question`: `userId`, `case_name`, **`content_id` int**, **`question_id` int**, `content`, `sort_order` | `user_question`: **`user_chapter_id` FK**, `question_template_id`, `text`, **`status`** pending/answered/skipped, `is_edited`, `answered_at` |
| FK 약함 (정수 코드 조합) | `user_chapter` → `book` → `owner_user_id` 체인 |
| 장 상태: `writing_progress` | `user_chapter.status` locked/writing/done (+ writing 부분 unique 설계) |

### 4.4 `answer` / `answer_draft`

| | OLD | NEW |
|---|---|---|
| 키 | (`userId`, `content_id`, `question_id`, `case_name`) | **`user_question_id` unique** |
| 확정본 | `response` (+ `first_answer`, `followups` jsonb, `skipped`, `image_url`) | `first_text` + `polished_text` + `polish_status` / `attempts`; 건너뛰기는 **행 없음** |
| 꼬리질문 | draft/answer의 **jsonb** | **`answer_followup` 정규화** (`seq`) |
| draft phase | `first` \| `followup` \| **`polished`** | `first` \| `followup` only |
| draft 기타 | `polished_draft`, `edit_text`, `image_url`, `case_name` | `followup_round`, `followup_id`, `first_input_mode`, `first_spoken_seconds` |

### 4.5 챕터 원고: `chapter_notebook` ↔ `chapter_review`

| OLD `chapter_notebook` | NEW `chapter_review` |
|---|---|
| 키: (`userId`, `content_id`, `case_name`) | 키: `user_chapter_id` unique |
| `title`, `image_placements` jsonb, `review_cache` jsonb | `version` int, `reviewed_at` |
| status: draft/reviewed | status: draft/reviewed (enum) |
| 이미지: attachment questionId 참조 | `media_placement` |

### 4.6 `audiobook_job` / `audiobook_job_part`

| | OLD | NEW |
|---|---|---|
| 범위 | **유저 전체** job (`userId`) | **책+챕터** (`book_id`, `user_chapter_id`) |
| 오디오 | **`data` bytea**, `mime_type`, `size_bytes` | `object_key` / part→`media_asset_id` |
| 음성 | `voice_id` | `voice_code` |
| BGM | `bgm_volume` real on job | `bgm_track_id` → `bgm_track` |
| part | `sort_order`, `chapter_title`, chunk 진행, **BYTEA** | `seq`, `text_length`, `media_asset_id` |
| 기타 | `notify_email`, `created_by_admin_id`, `cancel_requested` | `requested_by`, `source_version`, `cost_snapshot`, `idempotency_key` |

### 4.7 `qna_question` / `prompt_template`

- `qna_question`: 컬럼 세트 유사. OLD status는 text, NEW는 enum `pending|answered|published|closed`. 둘 다 `admin_note` / `published_at`.
- `prompt_template`: 둘 다 `key` unique + `body`. NEW만 **`version` int**. 키 네이밍: OLD `second_question|polish|…` vs NEW `followup|polish|synthesize|custom_questions` (엔티티 주석과 ERD가 약간 어긋남).

### 4.8 AI 로그

- OLD `ai_usage_event`: 호출당 토큰·**USD 비용**·`generation_id`
- NEW `ai_generation_log`: 성공/실패·재시도·토큰, **본문·비용 없음**, `kind` enum

---

## 5. 패리티를 위한 마이그레이션·시드 함의

1. **DB는 이미 분리** (`web-erd` 주석: 사용자 ID·단일 책 모델 불일치). 단순 dump/restore 불가. **ID 매핑 테이블** + 충돌 정책 필수.
2. **사용자**
   - OLD `user.email` / `password` → NEW 전화 중심 `app_user`로 직접 이식 불가.
   - 주소·역할·작성 UX 설정을 각각 `shipping_address` / (관리자 모델 부재) / (미구현 컬럼)로 재매핑.
3. **카탈로그**
   - OLD `content` / `question` / `case_*` 전량 복제 → NEW `chapter_template` / `question_template` + 축 파생.
   - OLD `case_definition.group=direction` 계열은 NEW에 **표 자체 없음**.
4. **목차·답변**
   - `user_content` → `book` 1권 생성 + `user_chapter`
   - `user_question` / `answer`: 정수 (`content_id`, `question_id`) → UUID `user_question_id`
   - `answer.response` / `first_answer` / `followups` → `first_text` / `polished_text` / `answer_followup`
   - `skipped=true` → NEW는 answer 행 없이 `user_question.status=skipped`
5. **원고**
   - `chapter_notebook` → `chapter_review` (+ `version=1`, `user_chapter_id` 연결).
   - `manuscript_edit_history`는 NEW에 대응 표 없음 → 스냅샷 정책 별도 결정.
6. **미디어**
   - BYTEA(`answer_attachment`, `photo_inbox`, `book_cover`, `audiobook_*.data`) → 객체 스토리지 + `media_asset`.
   - `photo_inbox` / `book_cover` UI·스키마 패리티는 NEW에 **미구현**.
7. **오디오북**
   - OLD 유저 단위·Admin·BYTEA → NEW 챕터 단위·entitlement·object key. job 재생성 또는 파일 이관 후 `audiobook_job` 재작성.
8. **시드**
   - NEW: intro/choice, chapter/question template, case 8축, consent_document, bgm_track, prompt_template.
   - OLD 전용 시드(`notebook_review_check`, `app_setting`, `pre_registration`)는 NEW 미보유.
9. **의도적 NEW 전용** (웹 패리티 목표가 아니면 “누락”이 아님): `storybook_*`, `user_entitlement`, `ebook_export`, `writing_plan`, OCTOMO / `consent_*`.
10. **의도적 OLD 전용** (앱 1차에 안 옮긴 것): `approval_request`, `photo_inbox`, `book_cover`, NextAuth 4표, `user_style_memory`, `pre_registration`.
11. **구현 vs ERD 드리프트 (패리티 시 주의)**
    - 엔티티 `app_user.phone` vs ERD `normalized_phone`
    - ERD `notification.book_id` / `answer_draft.recording_meta`는 **엔티티에 없음**

---

## 빠른 대응 맵 (개념 → 표)

| 개념 | OLD | NEW |
|---|---|---|
| 계정 | `user` | `app_user` |
| 자기소개 | `profile` | `user_intro_answer` + `user_profile` |
| 대주제 카탈로그 | `content` | `chapter_template` |
| 질문 카탈로그 | `question` / `case_question` | `question_template` |
| 유저 목차 | `user_content` | `user_chapter` (+ `book`) |
| 유저 질문 | `user_question` | `user_question` (스키마 다름) |
| 확정 답변 | `answer` | `answer` + `answer_followup` |
| 챕터 원고 | `chapter_notebook` | `chapter_review` |
| 사진 | `answer_attachment` / `photo_inbox` | `media_asset` / `media_placement` |
| 표지 | `book_cover` | (없음 / `ebook_export.cover_kind`) |
| 오디오북 | `audiobook_job(+part)` BYTEA | 동명 + `media_asset` / `bgm_track` |
| 스토리북 | (스키마 없음, 설계문서만) | `storybook_job` / `beat` |
| 인쇄 승인 | `approval_request` | (없음) |
