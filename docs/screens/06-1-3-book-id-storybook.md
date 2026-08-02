# 6-1-3. book/[id]/storybook — AI 스토리북 (Flutter 앱 비범위 + NestJS)

## 1. 개요

`book/[bookId]/storybook`은 검수된 챕터 원고를 사실 중심으로 요약하고, TTS 나레이션과 이미지·영상 하이브리드 미디어를 조합해 챕터별 MP4 스토리북을 만드는 **웹 전용** 기능이다.

- **Flutter 앱에서는 제공하지 않는다.** 스토리북 목록·생성·진행 상태·재생·다운로드 화면이나 GetX route, 앱 내 CTA를 만들지 않는다.
- 앱은 작성 중심, 스토리북은 웹 후처리라는 역할 분리를 따른다. 앱은 생성 완료 결과의 동기화·인앱 알림·푸시 알림도 제공하지 않는다.
- 앱에 향후 책 상세 등에서 스토리북을 노출할 요구가 생겨도 기본 정책은 CTA를 추가하지 않는 것이다. 별도 제품 결정이 있을 때만 웹 URL 유도 방식을 검토한다. 앱 내 재생 화면으로 확장하지 않는다.
- 기존 하이브리드 설계는 Admin 중심 Draft이며, 실제 Next.js 파이프라인과 NestJS 모듈은 아직 없다. 이 문서는 이를 사용자용 웹과 공통 NestJS로 전환하기 위한 가이드다.

관련 문서: [책 상세](./06-1-book-id.md), [챕터 리뷰](./05-book-id-review.md), [오디오북](./06-1-2-book-id-audiobook.md), `2026-08-02-chapter-storybook-hybrid-design.md`.

## 2. 유저 플로우

```text
Flutter 앱: 스토리북 진입/CTA/재생 없음

웹 책 상세 → /book/[bookId]/storybook
  → 소유/참여 권한·플랜 entitlement·reviewed 원고 확인
  → 챕터별 생성 가능 상태 및 기존 job 조회
  → "AI로 생성하기" 확인
  → 비동기 job 생성 → script → TTS → image/video media → mux
  → 상태 조회(대기/진행/실패/취소/완료)
  → 완료 MP4를 웹에서 재생
```

`AI로 생성하기`를 누르면 플랜에 맞는 범위·한도에 따라 백엔드가 자동 생성하는 흐름은 **백엔드 개발 완료 후 구현할 TODO**다. 현재 완료 기능이 아니다. 기존 설계가 챕터별 MP4를 전제로 하므로 우선 챕터 단위 job으로 설명하며, 전체 책 합본은 포함하지 않는다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| Flutter 화면/CTA/재생 | 스토리북 UI·route·알림·결과 동기화를 제공하지 않음 | 앱 비범위 |
| 사용자용 웹 관리 | 챕터별 생성 가능 여부, job 상태, 실패/재시도/취소, 재생을 제공 | 신규 |
| 하이브리드 생성 | 기본 `hybrid`: 정지 이미지(Ken Burns)와 핵심 영상 비트 20~30%를 TTS 길이에 맞춰 mux | 설계만 존재 |
| `video_only` / `image_only` | 품질 또는 저비용 운영 옵션 | 설계만 존재 |
| 사실 중심 요약 | reviewed 원고 → 1인칭 요약 beats, 45~150초, TTS 실측 길이를 타임라인 기준으로 사용 | 설계만 존재 |
| 플랜별 권한 | 생성·상태·재생 각각에서 entitlement와 quota를 서버가 검증 | 신규 |
| 중복·동시성 제어 | 진행 중인 동일 입력/챕터 job 중복 방지, 멱등성 키와 원자적 상태 전이 | 신규 |

하이브리드 기본값은 이미지·영상의 일관성과 비용을 고려한 기존 설계를 따른다. 기본 영상 비율은 25%(최소 1개, 최대 beat 절반)이며, LLM 초안 후 규칙 엔진과 운영자 override가 최종 `mediaType`을 정한다.

## 4. 화면 구성

### Flutter 앱

- `AppRoutes`와 `AppPages`에는 `/book`, `/book/preview`, `/book/complete`만 있고 storybook route가 없다.
- `lib/feature/book/`도 책 목록·미리보기·완료 화면만 있다. 앱의 `BookView`는 장 목록과 작성/미리보기 분기만 다룬다.
- 따라서 Flutter 작업은 화면 추가가 아니라, 공통 NestJS 데이터 모델에 스토리북 엔터티가 생겨도 앱 DTO/동기화/알림을 소비하지 않는 **명시적 비연동 정책**을 유지하는 것이다.

### 웹 생성·재생 화면을 위한 공통 백엔드 계약

- 헤더: 책 제목, 스토리북, entitlement/잠금 사유 및 웹 전용 안내.
- 챕터 행: reviewed 원고 준비 여부, 원고 버전, 예상 길이·비용, 최신 job 상태, `AI로 생성하기`/취소/재시도/재생.
- 생성 확인: 생성 대상 챕터, 플랜 포함 여부·한도, 외부 AI 전송 동의, 예상 시간·비용을 명시적으로 확인한다.
- 진행: script/audio/media/mux 단계, beat별 실패 사유와 안전한 재시도 가능 여부를 보여 준다. 클라이언트 폴링은 표시용이며 상태 전이는 서버 job worker가 소유한다.
- 재생: 완료된 MP4만 인증된 stream 또는 짧은 수명 URL로 제공한다. Flutter에 결과를 전달하거나 앱 알림을 발송하지 않는다.

## 5. API 엔드포인트 (NestJS)

### 현재 API

현재 NestJS에는 storybook, media, video, TTS, queue/job 모듈·엔드포인트가 없다. `/v1/book`, `/v1/book/pages`는 단일 책의 완료 장 텍스트만 조립한다. Next.js의 storybook-video Admin Route Handler와 `lib/storybook-video/`도 존재하지 않는다.

### 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/v1/books/:bookId/storybook` | 책 접근 권한, 챕터 reviewed 상태, entitlement, 최신 job 요약 |
| `POST` | `/v1/books/:bookId/storybook/chapters/:chapterId/jobs` | 확인된 챕터 생성 job 요청. entitlement·원고 버전·중복·quota를 원자 검증 |
| `GET` | `/v1/books/:bookId/storybook/jobs/:jobId` | job/beat 진행, 실패·취소 가능 여부 조회 |
| `POST` | `/v1/books/:bookId/storybook/jobs/:jobId/cancel` | 아직 취소 가능한 job에 취소 요청 |
| `POST` | `/v1/books/:bookId/storybook/jobs/:jobId/retry` | 정책상 재시도 가능한 실패 단계만 새 시도 생성 또는 재개 |
| `GET` | `/v1/books/:bookId/storybook/chapters/:chapterId/stream` | 완료 MP4의 권한 재검증 후 스트림/짧은 수명 URL 제공 |

`AccessTokenGuard`는 사용자 ID만 주입하므로, service/transaction 계층이 `bookId` 소유·참여 관계, 원고의 책 소속, entitlement를 검사해야 한다. 작업 생성은 큐/worker에서 처리하고 조건부 갱신·유니크 제약·idempotency key로 동시에 눌린 요청을 막는다.

## 6. 데이터 모델

| 모델 | 현재 상태 | 신규 방향 |
|---|---|---|
| `book` / `user_chapter` | NestJS는 사용자당 단일 책·챕터 구조 | 독립 `bookId`, 소유/참여 권한, `chapterId` 범위로 전환 |
| 챕터 reviewed 원고 | NestJS에는 없음 | 원고 본문·버전·reviewed 시각을 생성 입력으로 고정 |
| `storybook_job` | 없음 | 책/챕터, 요청자, 입력 원고 버전, `mediaMode`, 모델·voice·style snapshot, 상태·비용·오류·취소 정보 |
| `storybook_beat` | 없음 | narration, facts, visual prompt, `mediaType`, TTS 실측 시간, 외부 video job ID, segment 상태 |
| `media_asset` | 없음 | private object key, MIME/크기/checksum, 이미지·클립·최종 MP4, 만료/삭제/접근 로그 |
| entitlement/quota ledger | 없음 | 플랜/프로모션/기능·사용량·만료와 생성 예약·차감·복구를 서버에서 판정 |

기존 Next.js `chapter_notebook`은 `userId + contentId` 단일 사용자 원고이고, `audiobook_job`은 관리자 생성 MP3를 PostgreSQL `BYTEA`에 저장한다. 둘은 사용자용 스토리북 job의 구현이 아니며, 대용량 영상은 private object storage와 DB 메타데이터 분리를 우선한다.

## 7. 기존 코드 참고

| 영역 | 경로 | 확인 내용 |
|---|---|---|
| Flutter 라우팅 | `lib/core/route/app_routes.dart`, `app_pages.dart` | storybook route 없음; 책 관련은 `/book`, `/book/preview`, `/book/complete`뿐 |
| Flutter 책 UI | `lib/feature/book/` | book/preview/complete 7개 파일만 존재, storybook UI·재생기 없음 |
| NestJS 책·소유권 | `server/src/book/`, `server/src/chapters/services/chapters.service.ts` | 단일 책 API; 질문 소유권을 서비스에서 검사하고 타 사용자 리소스는 404 |
| NestJS 모듈 현황 | `server/src/**` | storybook/media/video/TTS/job 모듈 없음 |
| 하이브리드 설계 | `docs/superpowers/specs/2026-08-02-chapter-storybook-hybrid-design.md` | Admin 중심 Draft, hybrid·beat·단계 설계 |
| 전 비트 영상 설계·계획 | `2026-08-01-chapter-storybook-video-design.md`, `plans/2026-08-01-chapter-storybook-video.md` | Admin 설계/미완료 체크리스트, 실제 구현 아님 |
| 기존 TTS 참조 | `app/lib/audiobook/clova-tts.ts` | NCP CLOVA 서버 전용 키·MP3 합성, Admin 오디오북용 |

## 8. 신규 개발 범위 요약

1. **Flutter**: 구현하지 않는다. 화면, route, deeplink CTA, 생성 상태 동기화, 완료 알림, MP4 재생을 추가하지 않는다.
2. **NestJS**: 다권/참여 권한과 entitlement 기반 `storybook`·`media` 도메인, 비동기 queue/worker, job·beat·media asset·감사 모델을 신규 구현한다.
3. **자동 생성 TODO**: 백엔드 완료 뒤 웹의 `AI로 생성하기`가 플랜에 맞는 챕터 job을 생성하고, 요약→TTS→이미지/영상→mux를 자동 수행하도록 구현한다.
4. **보안·운영**: provider 키는 서버 시크릿에만 보관하고, private storage·인증 재생·짧은 수명 URL·상태/비용/접근 감사 로그를 둔다.

## 9. 열린 이슈 / 가정

1. T1~T4의 정확한 스토리북 entitlement·쿼터·프로모션 우선순위는 확정되지 않았다. UI나 경로로 하드코딩하지 않고 서버 정책으로 결정해야 한다.
2. 현 설계는 챕터별 MP4다. 전체 책 합본, 자동 일괄 생성, 합본 재생은 비범위이며 별도 결정이 필요하다.
3. job 저장 위치와 schema는 현재 구현이 아니라 계획이다. 계획의 `app/.data/storybook-video/{jobId}/`는 로컬 MVP 제안일 뿐, 사용자 서비스에는 객체 저장소·보존/삭제 정책이 필요하다.
4. 이미지/영상/TTS 제공자는 NCP CLOVA, OpenRouter Image/Video 등 설계별로 다르다. NestJS에는 제공자 구현이 없고, 현재 Next.js 작성용 TTS는 OpenRouter·오디오북은 CLOVA다. 실제 제공자 계약·한도·가격·지역·장애/재시도 정책을 정합화해야 한다.
5. 사용자 원고는 민감 개인정보다. AI 이미지·영상·TTS 제공자 전송 전 고지와 명시적 동의, 학습 이용 여부, 보존·삭제·국외 이전 정책을 확정해야 한다.
6. 생성물은 역사적 사실을 보장하지 않고, 이미지/영상의 초상권·허구 삽입·저작권/상업 이용·제3자 권리 고지를 마련해야 한다.
7. 긴 작업의 실패·취소·재시도 때 quota/비용을 언제 예약·차감·복구할지, 같은 챕터·원고 버전의 동시 요청을 어떻게 합칠지, worker 동시성·rate limit을 정해야 한다.
