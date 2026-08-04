# 6-1-2. book/[id]/audiobook — 목차별 오디오북 (Flutter 앱 + NestJS)

## 1. 개요

`book/[bookId]/audiobook`은 검수 완료 원고를 목차(챕터)별 MP3로 생성·다운로드하고 관리하는 사용자용 화면이다. 유료 플랜 entitlement가 있는 소유자/참여자만 쓸 수 있으며, 무료 플랜은 안내와 업그레이드 진입만 제공하고 생성·재생·다운로드는 허용하지 않는다.

- 현재 Flutter 앱과 NestJS에는 audiobook/TTS/media/job 모듈 및 사용자용 오디오북 API가 없다. 따라서 이 화면과 서버 기능은 **신규**다.
- Next.js에는 관리자 전용 CLOVA Voice 생성 기능이 있다. 이를 앱으로 직접 호출하거나 API 키를 전달하지 않고, NestJS가 공통 사용자용 job·미디어 API와 Naver/CLOVA 연동을 소유하는 방향을 제안한다.
- `bookId`는 다권 에디션 식별자이며, 다음 `storybook`의 챕터 영상·미디어 작업과 같은 작업 모델로 합치지 않는다.

관련 화면: [6-1. 책 상세](./06-1-book-id.md), [5. 챕터 리뷰](./05-book-id-review.md), [6-1-1. 전자책](./06-1-1-book-id-ebook.md).

## 2. 유저 플로우

1. 사용자는 책 상세에서 `오디오북`을 선택한다. 앱은 `bookId`의 소유/참여 권한과 오디오북 entitlement를 조회한다.
2. 무료 플랜이거나 권한이 없으면 잠금 사유·플랜 안내만 보이며, 생성·미리듣기·다운로드 API는 호출하지 않는다.
3. 권한이 있으면 리뷰 완료 원고가 있는 목차 목록, 각 목차의 생성/다운로드 상태와 잔여 제공 횟수를 확인한다. 원고가 없거나 review가 끝나지 않은 목차는 생성할 수 없다.
4. 사용자는 Naver/CLOVA Voice 목록에서 음성을 샘플로 미리 듣고 선택한다. BGM도 카탈로그에서 선택하거나 끌 수 있다.
5. 목차의 `생성하기`를 누르면 확인 모달이 비용·플랜·생성 한도(2회/챕터)를 설명한다. 사용자가 확인해야만 서버에 job 생성을 요청한다.
6. 서버는 entitlement, 책 소유/참여, 챕터 review 상태, 한도와 진행 중 job을 원자적으로 검사한 뒤 작업을 생성한다. 앱은 `pending`/`processing` 진행률을 폴링 또는 이후 이벤트로 갱신한다.
7. 완료된 목차는 앱 내 재생 또는 인증된 다운로드로 제공한다. 다운로드 때도 서버가 권한·한도·파일 상태를 재검증한다. 실패/취소/재시도 결과와 한도 차감 여부는 명시적으로 보여 준다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 플랜 잠금 | 무료 플랜은 오디오북 비활성·접근 불가, 유료 entitlement만 사용 가능 | 신규 |
| 목차별 작업 | review 완료 원고를 챕터별 MP3 job으로 생성·상태 표시 | 신규 |
| 생성 확인 | 생성 전 비용·한도·예상 시간 안내 및 확인 필수 | 신규 |
| 목차별 생성 한도 | 생성 2회/챕터. 재생·다운로드는 무제한 | 신규 정책 (결정 완료) |
| Voice 미리듣기·선택 | 서버가 CLOVA 샘플을 생성하고 사용자가 음성을 선택 | 신규 |
| BGM 선택 | 서버 카탈로그의 라이선스 검증된 트랙 선택/미사용, 믹싱 설정 저장 | 신규 |
| 생성 진행·실패·재시도 | job/part 상태, 청크 진행률, 오류·취소·재시도 UX | 신규 |
| 재생·다운로드 | 인증된 stream 또는 짧은 수명의 URL로 MP3 제공 | 신규 |
| 완료 알림 | 앱 내 알림 우선, 이메일은 운영 정책 확정 후 선택 | 신규 |

클라이언트의 잠금·잔여 횟수 표시는 안내일 뿐이다. 생성, stream, 다운로드마다 서버가 다시 권한과 한도를 검사한다.

## 4. 화면 구성

### 접근 상태와 책 정보

- 헤더에는 책 제목, `오디오북`, 플랜 상태를 표시한다.
- 무료 사용자는 잠금 아이콘, “유료 플랜에서 이용할 수 있어요”, 플랜 안내 CTA만 본다. MP3 URL이나 이전 생성 파일 메타데이터를 응답에 포함하지 않는다.
- 사용 가능 사용자는 전체 예상 길이·원고 글자 수와 목차별 `준비 필요`/`생성 가능`/`생성 중`/`완료`/`실패` 상태를 본다.

### 음성·BGM 선택과 생성 확인

- Voice 카드에는 이름, 특성, `미리 듣기`, 선택 상태를 큰 터치 영역으로 제공한다. 샘플 MP3는 앱이 CLOVA를 직접 호출하지 않고 인증된 서버 endpoint에서만 받는다.
- BGM은 트랙 제목·분위기·라이선스 출처와 끄기를 제공한다. 실제 선택 가능한 카탈로그와 라이선스 검수 전에는 기본 트랙을 사용자 선택 기능으로 노출하지 않는다.
- 생성 확인 모달에는 선택한 목차/음성/BGM, 예상 길이, 비용 또는 플랜 포함 여부, 한도 정책, 원고 변경 뒤 재생성 정책을 표시한다. “확인하고 생성”을 눌러야 job 요청이 전송된다.

### 목차별 결과

- 각 목차는 생성 버튼, 진행률, 오류 메시지, 완료 시 재생·다운로드 버튼과 잔여 제공 횟수를 표시한다.
- 작업 중에는 중복 생성 버튼을 막되 서버의 conflict 응답도 처리한다. 실패 시 재시도 가능 여부와 한도 영향은 서버 응답에 따른다.
- 다운로드는 기기 파일 저장과 공유를 지원할 수 있으나, 내려받은 MP3의 기기 보관·공유는 서비스 접근 통제 밖이라는 안내가 필요하다.

## 5. API 엔드포인트 (NestJS)

### 현재 API

현재 NestJS는 `/v1/book`, `/v1/book/pages`와 단일 사용자 책만 제공한다. MP3, TTS, 미디어 저장, job, entitlement API는 없다.

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/book` | 단일 사용자 책 요약 | 기존 |
| `GET` | `/v1/book/pages` | `done` 장의 텍스트 페이지 조립 | 기존 |

### 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/v1/books/:bookId/audiobook` | 책 권한, review 가능 목차, job/part 상태, 한도·잔여 횟수 반환 |
| `GET` | `/v1/books/:bookId/audiobook/voices` | 사용 가능한 Voice 메타데이터 반환 |
| `POST` | `/v1/books/:bookId/audiobook/voice-preview` | 선택 Voice의 짧은 샘플 MP3 스트림 반환 |
| `GET` | `/v1/books/:bookId/audiobook/bgms` | 라이선스 검증된 BGM 카탈로그 반환 |
| `POST` | `/v1/books/:bookId/audiobook/chapters/:chapterId/jobs` | 확인 뒤 목차 생성 job 생성; entitlement·review·한도·중복을 원자 검증 |
| `GET` | `/v1/books/:bookId/audiobook/jobs/:jobId` | job/part 진행·실패·완료 상태 조회 |
| `POST` | `/v1/books/:bookId/audiobook/jobs/:jobId/cancel` | 허용된 처리 중 작업 취소 요청 |
| `GET` | `/v1/books/:bookId/audiobook/chapters/:chapterId/stream` | 인증·권한 확인 후 MP3 스트림 또는 짧은 수명 URL |
| `POST` | `/v1/books/:bookId/audiobook/chapters/:chapterId/downloads` | 다운로드 제공 기록/한도 원자 차감 후 파일 응답 또는 URL 발급 |

NestJS controller는 `AccessTokenGuard`로 사용자 ID를 받고, service/transaction 계층에서 책 소유·참여 관계와 entitlement를 판정한다. CLOVA API 키는 NestJS 환경변수/secret manager에만 저장한다.

## 6. 데이터 모델

| 모델 | 현재 상태 | 변경 방향 |
|---|---|---|
| `book` | 사용자당 단일 책 | 독립 `book.id`, 소유/참여 관계 도입 |
| 챕터 review 원고 | NestJS에 없음 | `book_id`, `chapter_id`, 원고 버전, `reviewed_at`을 가진 공통 원고 모델 필요 |
| entitlement/plan | 없음 | 책·사용자·기능(audio)·플랜·프로모션·만료를 서버에서 판정 |
| `audiobook_job` | 없음 | `book_id`, 요청자, 챕터/전체 범위, 원고 버전, Voice/BGM, 상태·오류·비용 스냅샷·시각 |
| `audiobook_job_part` | 없음 | job별 챕터, 청크 진행, 출력 파일 참조, 취소·재시도 상태 |
| `audiobook_delivery` | 없음 | 챕터별 생성/다운로드 이벤트, 한도 종류·소모 시각·결과·멱등성 키 |
| `media_asset` | 없음 | 비공개 MP3 object key, MIME/크기/기간, 삭제·만료 상태, 접근 로그 연결 |
| BGM catalog | 없음 | 트랙 ID, 출처·라이선스 증빙, 허용 지역/기간, 믹싱 가능 여부 |

원고 버전과 오디오 결과를 연결해 원고가 수정되면 구버전임을 표시하고, 재생성 판단을 할 수 있어야 한다. 원고·MP3는 민감정보로 보고 DB BYTEA 장기 저장 대신 접근 제어된 객체 저장소와 파일 수명 정책을 우선 검토한다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 책 화면 | `lib/feature/book/book_view.dart`, `book_controller.dart` | 단일 `/book`, 장 목록과 미리보기 진입; audiobook route/UI 없음 |
| Flutter 라우팅·API | `lib/core/route/app_routes.dart`, `app_pages.dart`, `lib/core/network/api_client.dart`, `real_api_client.dart` | 정적 GetX 경로와 `/v1` API 추상화; audiobook 계약 없음 |
| Flutter 음성 입력 | `lib/common/widgets/ds/app_voice.dart`, `pubspec.yaml` | STT 마이크 UI와 `speech_to_text`; audio player 패키지 없음. `dio`/`path_provider`/`open_filex`는 존재 |
| NestJS 인증 | `server/src/auth/guard/access-token.guard.ts` | Bearer JWT 검증 후 `request.userId` 주입 |
| NestJS 소유권 패턴 | `server/src/chapters/services/chapters.service.ts` | 질문의 사용자 소유권 검사, 타 사용자 리소스는 404 처리 |
| NestJS 책 | `server/src/book/book.controller.ts`, `server/src/book/services/book.service.ts` | 단일 사용자 `book/pages`; 완료 장 텍스트 조립 |
| NestJS 기능 현황 | `docs/api-spec.md`, `docs/server-feature-definition.md`, `docs/server-architecture.md` | MP3/TTS/media/job API가 현재 없고, Controller→Service→Repository·트랜잭션 규약을 명시 |

## 8. 신규 개발 범위 요약

1. **Flutter**: `bookId` argument 기반 audiobook route/binding/controller/view, 잠금·빈·준비·진행·완료·실패·재시도 상태, Voice/BGM 선택·미리듣기·생성 확인 모달, 안전한 재생/다운로드 UX를 구현한다.
2. **Flutter 의존성**: 현 `pubspec.yaml`에는 재생 전용 패키지가 없다. audio player, 백그라운드 재생, 다운로드·공유 패키지는 Android/iOS 지원·라이선스·접근성을 검토해 추가한다.
3. **NestJS**: `audiobook` 도메인과 필요 시 `media`/외부 TTS provider를 신설한다. entity/repository/service/transaction/DTO/controller/module 및 Swagger 계약을 추가한다.
4. **권한·한도**: 플랜 entitlement, book 소유/참여, chapter reviewed, 2회 한도, 진행 중 중복 job을 생성/재생/다운로드마다 서버에서 검증한다.
5. **비동기 처리**: 재시도 가능한 worker/queue, 청크 체크포인트·취소·실패 복구, 원자적 카운터·멱등성 키, 작업/접근 감사 로그를 구현한다.
6. **미디어 보안**: 서버 전용 CLOVA 키, private object storage, 인증 stream/짧은 수명 URL, 파일 만료·삭제와 원고/오디오 접근 로그를 설계한다.

## 9. 열린 이슈 / 가정

1. **[결정 완료] 한도 정책**: 생성 2회/챕터. 재생·다운로드는 무제한. (결정기록 08-03)
2. 생성 확인의 비용 문구는 유료 플랜 포함, 추가 과금, 무료 프로모션 중 무엇인지 확정해야 한다. 결제/프로모션 entitlement의 우선순위도 필요하다.
3. 한도 검증은 UI가 아니라 DB 조건부 갱신/트랜잭션으로 원자 처리해야 한다. 동시 생성 중복, 실패·취소·네트워크 재시도 시 한도 소모 시점과 환불 규칙을 정해야 한다.
4. 현재 Next.js 구현은 reviewed notebook 원고만 사용한다. NestJS의 `done` 장과 웹의 `reviewed`는 다르므로, 어떤 원고 버전을 음성화할지와 수정 후 구버전 MP3의 유지·삭제·재생성 규칙을 정해야 한다.
5. BGM 파일의 저작권·상업 이용·배포/지역/기간 라이선스, 출처 증빙, 업로드 제한, 음성 대비 볼륨, 길이 정합, 루프·페이드·믹싱 실패 시 처리 기준이 필요하다.
6. Voice/BGM 미리듣기와 생성 요청은 서버에서만 CLOVA를 호출해야 한다. Flutter 앱에 Naver/CLOVA 키를 넣거나 직접 API를 호출하면 안 된다.
7. MP3는 개인 원고를 재구성한 민감정보다. 소유자·가족 참여자의 생성/재생/다운로드 권한, 파일 만료·삭제, 기기 저장·공유 고지, 접근 로그와 관리자 열람 범위를 정책화해야 한다.
8. queue provider, 동시 작업 수, TTS 제공자 장애·rate limit, 긴 원고 청크/타임아웃, 작업 알림 채널과 재시도 횟수는 미정이다.
9. 다권 `bookId` 도입, Next.js Drizzle과 NestJS TypeORM의 데이터 이전·소유/참여 권한, 웹 우선 편집 충돌 정책을 먼저 확정해야 앱·웹이 같은 오디오를 제공할 수 있다.
