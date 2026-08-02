# 6-1-3. book/[id]/storybook — AI 스토리북 (Next.js 웹)

## 1. 개요

`/book/[bookId]/storybook`은 검수 완료 챕터 원고를 AI가 사실·사건 중심으로 요약하고, TTS 나레이션과 이미지+영상 하이브리드 미디어를 조합해 챕터별 MP4를 생성·관리·재생하는 **사용자용 웹** 화면이다.

- 현 Next.js에 `/book/[bookId]/storybook` 페이지, 사용자 Route Handler, `app/lib/storybook-video/`, `app/app/api/admin/users/[id]/storybook-video/**`는 없다.
- 하이브리드 설계는 기본 MVP를 `hybrid`로 권장하지만 상태가 Draft이고 Admin 전용 설계다. Admin UI·job schema·생성 파이프라인도 구현되지 않았다.
- 따라서 기존 설계를 사용자용 기능으로 오인하지 않는다. 이 문서는 그 설계를 우선 근거로 삼되, 사용자용 관리/생성/재생 기능은 모두 신규로 분리한다.

관련 문서: [책 상세 — 웹](./06-1-book-id-web.md), [챕터 리뷰 — 웹](./05-book-id-review-web.md), [오디오북 — 웹](./06-1-2-book-id-audiobook-web.md), `2026-08-02-chapter-storybook-hybrid-design.md`.

## 2. 유저 플로우

1. 사용자는 `/book/[bookId]`에서 스토리북을 선택해 `/book/[bookId]/storybook`으로 이동한다.
2. 서버 컴포넌트 또는 인증된 BFF는 세션 사용자, 책 소유/참여 관계, 챕터의 reviewed 원고, entitlement를 조회한다. 권한이 없으면 미디어 메타데이터·URL을 주지 않는다.
3. 사용자는 챕터별 원고 버전, 예상 길이·비용, 기존 생성 결과와 job 상태를 확인한다.
4. `AI로 생성하기`를 누르면 확인 모달에서 대상 챕터, 플랜 포함 여부·한도, 외부 AI 전송 동의, 예상 시간/비용을 확인한다.
5. **TODO — 백엔드 개발 완료 후:** 확인된 요청만 비동기 job을 만들고 플랜에 맞춰 `script → TTS → image/video media → mux`를 자동 실행한다. 현재 구현 완료 기능이 아니다.
6. 화면은 상태 조회로 대기·진행·실패·취소·재시도를 표시한다. 완료된 챕터 MP4만 웹 플레이어에서 재생한다.

현 설계가 챕터별 MP4를 전제로 하므로 생성 단위는 우선 챕터다. 전체 책을 하나의 장편으로 합치는 자동 생성은 현 설계의 non-goal이며, 별도 제품 결정을 기다린다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 사용자용 스토리북 페이지 | 책/챕터 상태, 잠금, 생성, 진행, 재생을 제공 | 신규 |
| 하이브리드 기본 모드 | 이미지(Ken Burns) + 핵심 영상 비트 20~30%를 TTS 길이에 맞춰 MP4로 mux | Draft 설계 |
| `video_only` / `image_only` | 품질 또는 저비용 운영 모드 | Draft 설계 |
| 사실 중심 스크립트 | reviewed 원고를 1인칭 facts/narration/visual prompt beats로 요약 | Draft 설계 |
| 길이 제어 | 챕터별 45~150초, TTS 실측 duration을 최종 타임라인 기준으로 사용 | Draft 설계 |
| 생성·재생 권한 | entitlement, reviewed 원고, 소유/참여, quota를 각 보호 요청에서 검증 | 신규 |
| 비동기 job 안전성 | 중복 요청 방지, 단계별 상태, 실패/재시도/취소, 동시성/비용 통제 | 신규 |

기본 `hybrid`는 LLM이 `mediaType`을 초안으로 정한 뒤 규칙 엔진이 영상 비율을 25%(최소 1, 최대 beat 절반)로 보정한다. 이미지에는 동일한 style bible·reference를 적용하고, 영상은 mute로 생성한 뒤 TTS를 mux한다.

## 4. 화면 구성

### 진입·잠금·챕터 목록

- 헤더에는 책 제목, `AI 스토리북`, 플랜 상태, 웹 전용 후처리임을 표시한다.
- entitlement가 없거나 reviewed 원고가 없으면 잠금/준비 필요 상태와 리뷰 이동 CTA만 제공한다. 버튼 비활성화는 안내일 뿐, 서버도 생성·상태·재생을 거부해야 한다.
- 챕터 행은 제목, 원고 버전, 예상 요약 길이·비용, 현재/최신 job 상태, `AI로 생성하기`, 취소·재시도·재생 액션을 둔다.

### 생성 확인·진행

- 확인 모달은 생성 대상과 플랜/한도, AI 제공자 전송 동의, 예상 비용과 결과물의 사실성·초상권 고지를 보여 준다.
- 상태는 `draft → script_ready → audio_ready → media_ready → muxed | failed`를 기준으로 표시한다. 단, 이것은 Draft 설계의 목표 상태이며 실제 DB/API는 아직 없다.
- 진행 화면은 job 전체와 beat 단위 오류를 분리한다. 동일 챕터·동일 원고 버전의 진행 중 job은 새로 만들지 않고 기존 job을 반환하거나 충돌을 알려야 한다.

### 재생·결과

- 완료 MP4는 자체 플레이어로 재생하고 재생 직전에 인증된 stream 또는 짧은 수명 URL을 요청한다.
- 원고가 수정되어 reviewed 버전이 바뀌면 이전 결과임을 표시하고 재생성 정책을 적용한다. 영구 공개 URL이나 클라이언트에 provider 키를 노출하지 않는다.
- 다운로드 제공 여부는 별도 정책이다. 사용자가 받은 파일의 저장·공유는 서비스의 접근 통제 밖이라는 고지를 포함한다.

## 5. API 엔드포인트 (Route Handler / 공유 NestJS 전환 방향)

### 현재 Next.js Route Handler

| 확인 항목 | 결과 |
|---|---|
| `app/app/api/admin/users/[id]/storybook-video/**` | 없음 |
| `app/lib/storybook-video/**` | 없음 |
| `UserDetailClient.tsx` 스토리북 UI | 없음 |
| 사용자 `book/[bookId]/storybook` route/API | 없음 |

현재 재사용 가능한 인접 기능은 Admin 전용 오디오북이다. `/api/admin/users/[id]/audiobook/*`는 `getValidAdmin()`을 요구하고, reviewed `chapter_notebook` 원고를 CLOVA TTS MP3로 만들며 일반 사용자용 계약이 아니다.

### 사용자 Route Handler 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/books/[bookId]/storybook` | 책 권한, 챕터 reviewed 상태, entitlement, 최신 job·결과 요약 |
| `POST` | `/api/books/[bookId]/storybook/chapters/[chapterId]/jobs` | 생성 확인 후 job 요청; entitlement·원고 버전·중복·quota 검사 |
| `GET` | `/api/books/[bookId]/storybook/jobs/[jobId]` | job/beat 상태·실패 사유·취소/재시도 가능 여부 |
| `POST` | `/api/books/[bookId]/storybook/jobs/[jobId]/cancel` | 취소 가능한 job에 취소 요청 |
| `POST` | `/api/books/[bookId]/storybook/jobs/[jobId]/retry` | 재시도 정책에 맞는 단계 재시도 |
| `GET` | `/api/books/[bookId]/storybook/chapters/[chapterId]/stream` | 완료 MP4 권한 재검증 후 stream/짧은 수명 URL |

### 공유 NestJS 전환 방향

1. 앱/웹이 같은 에디션·플랜·생성 상태를 보려면 NestJS에 `storybook`, `media`, `entitlement` 도메인과 `/v1/books/:bookId/storybook/*` 공통 계약을 먼저 만든다.
2. Next.js Route Handler는 NextAuth 세션을 검증하는 BFF로 공통 API를 호출하거나, 서버 컴포넌트가 공통 계약을 사용한다. 별도 Drizzle 원본을 병렬로 만들지 않는다.
3. 생성은 Route Handler 요청 수명에 묶지 않고 queue/worker가 수행한다. worker만 OpenRouter/NCP/영상 제공자 비밀을 사용하며, 키는 서버 secret manager 또는 환경변수에만 둔다.

## 6. 데이터 모델

| 모델 | 현재 상태 | 변경 방향 |
|---|---|---|
| `chapter_notebook` | `userId + contentId`별 원고, `draft/reviewed`, 이미지 placement | `bookId`/`chapterId`와 불변 원고 버전으로 확장; reviewed version만 입력 |
| `audiobook_job` / part | Admin 전용, `userId`·MP3 `BYTEA`·진행 필드 | 직접 재사용하지 않음. job 상태·취소 원칙은 참고만 하고 스토리북 전용 모델 신설 |
| `storybook_job` | 없음 | 책/챕터·요청자·입력 원고 버전·mediaMode·모델/voice/style snapshot·상태·비용·오류 |
| `storybook_beat` | 없음 | narration/facts/visual prompt, `mediaType`, audio duration, 외부 영상 ID, segment 상태 |
| `media_asset` | 없음 | private object key, 이미지·clip·MP4 메타데이터, checksum, 만료·삭제·접근 로그 |
| entitlement/quota ledger | 없음 | 플랜·프로모션·기능 권한, 예약/차감/복구, 멱등성 키, 만료를 서버 판정 |

Draft 계획의 스토리북 저장 경로 `app/.data/storybook-video/{jobId}/`와 JSON beat schema는 구현된 schema가 아니다. 사용자용 대용량 MP4는 `BYTEA`가 아닌 private object storage와 DB 메타데이터로 관리한다.

## 7. 기존 코드 참고

| 경로 | 참고 내용 |
|---|---|
| `docs/superpowers/specs/2026-08-02-chapter-storybook-hybrid-design.md` | 기본 MVP 하이브리드, beat mediaType, 150초 상한, Draft/Admin 설계 |
| `docs/superpowers/specs/2026-08-01-chapter-storybook-video-design.md` | 전 비트 영상 옵션, Admin 전용 전제, 하이브리드에 의해 기본 MVP가 대체됨 |
| `docs/superpowers/plans/2026-08-01-chapter-storybook-video.md` | `storybook_video_*` 계획과 미완료 체크리스트; 구현 근거가 아님 |
| `app/lib/openrouter.ts`, `app/lib/ai.ts` | 서버에서 OpenRouter text/image 호출과 `OPENROUTER_API_KEY` 사용. 영상 API client는 없음 |
| `app/lib/audiobook/clova-tts.ts` | 서버 전용 NCP CLOVA Voice TTS, 한국어 요청 한도 2,000자; Admin 오디오북용 |
| `app/app/api/admin/users/[id]/audiobook/route.ts`, `app/lib/audiobook/jobs.ts` | Admin 권한, `after()` 기반 재개/처리, job 진행 관리의 참고 |
| `app/lib/db/schema.ts` | `chapter_notebook`은 단일 사용자/대목차, `approval_request`는 tier·entitlement 없음, audiobook은 MP3 BYTEA |
| `app/components/admin/UserDetailClient.tsx` | 오디오북 UI는 존재하지만 storybook 섹션은 없음 |

## 8. 신규 개발 범위 요약

1. **웹 UI**: `/book/[bookId]/storybook` 서버 페이지와 작은 클라이언트 컴포넌트로 잠금·챕터 상태·생성 확인·진행/실패/취소/재시도·인증 재생을 구현한다.
2. **자동 생성 TODO**: 백엔드 개발 완료 뒤 `AI로 생성하기`가 플랜에 맞춰 챕터별 job을 자동 시작하도록 연결한다. 지금은 Admin 설계와 계획만 있으므로 완료 기능으로 표기하지 않는다.
3. **공통 API/worker**: NestJS storybook/media/entitlement와 queue worker, 원고 버전 고정·idempotency·조건부 상태 전이·비용/usage 감사 로그를 구현하고 Next.js를 BFF로 전환한다.
4. **미디어 보안**: provider 키의 서버 전용 관리, private object storage, 인증 stream/만료 URL, 삭제·보존·접근 기록을 구현한다.
5. **기존 Admin 분리**: Admin 오디오북은 운영 도구로 유지한다. Admin 경로·권한·MP3 `BYTEA` 저장 방식을 사용자 스토리북의 보안·스케일링 대체물로 사용하지 않는다.

## 9. 열린 이슈 / 가정

1. T1~T4별 storybook 접근/생성 횟수/해상도·길이/재생 권한은 확정되지 않았다. 랜딩의 “T2/T4 AI 영상” 문구만으로 API를 하드코딩하지 말고 entitlement 정책을 확정해야 한다.
2. 생성 단위는 기존 설계에 따라 챕터로 가정했다. 전체 책 합본, 일괄 생성, 합본 비용·재생 UX는 열린 결정이다.
3. 하이브리드 설계·관리자 UI·저장 위치·job schema는 모두 Draft/계획이다. 현재 route, 라이브러리, schema, UI가 존재한다고 전제하면 안 된다.
4. Naver/CLOVA는 현재 Admin 오디오북용이고 작성 TTS는 OpenRouter다. 스토리북 설계는 CLOVA TTS, OpenRouter Image/Video(Seedance 제안)를 가리킨다. 실제 제공자, API 계약, 모델 slug, 한도·가격·장애/지역 정책을 확인해야 한다.
5. 원고에는 민감한 개인정보가 있다. 이미지/영상/TTS 제공자 전송의 명시적 고지·동의, 학습 이용 여부, 보관·삭제·국외 이전, 최소 전송과 철회 처리 정책이 필요하다.
6. 생성물의 역사적 사실성은 보장되지 않는다. 허구 삽입·초상권·제3자 인물/사진·저작권·상업적 이용과 결과물 고지/신고/삭제 절차를 확정해야 한다.
7. 고비용 생성의 중복 클릭, HTTP 재시도, 동일 원고 버전 동시 요청, provider polling 실패, 취소 후 늦은 완료에 대한 idempotency·락·상태 전이·quota/비용 차감·환불 기준이 필요하다.
8. Next.js Drizzle과 Flutter/NestJS TypeORM은 현재 사용자 ID·DB·단일 책 모델이 분리돼 있다. `bookId` 매핑, 데이터 이전·롤백, 가족 참여 권한, 웹 우선 원고 충돌 정책이 선행되어야 한다.
