# 6-1-2. book/[id]/audiobook — 목차별 오디오북 (Next.js 웹)

## 1. 개요

`/book/[bookId]/audiobook`은 한 에디션의 검수 완료 원고를 목차별로 오디오북 생성·관리·재생·다운로드하는 **사용자용** 웹 화면이다. 앱과 같은 entitlement, 한도, 원고 버전, job 계약을 사용한다.

- 현재 웹 오디오북은 `/admin/users/[id]`의 관리자 전용 기능이다. 일반 사용자 UI·Route Handler·권한/플랜 모델은 없다.
- 기존 구현은 `chapter_notebook.status = reviewed` 원고를 CLOVA Voice TTS로 청크 생성하고 MP3 part와 전체 병합본을 DB에 저장하며, 관리자 이메일 완료 알림을 보낸다.
- 신규 사용자 흐름은 기존 Admin endpoint를 노출하거나 완화하는 작업이 아니다. 다권 `bookId`, 사용자 소유/참여 권한, 플랜 entitlement, 챕터별 한도, private media delivery를 갖춘 별도 계약으로 전환한다.

관련 화면: [6-1. 책 상세 — 웹](./06-1-book-id-web.md), [5. 챕터 리뷰 — 웹](./05-book-id-review-web.md), [6-1-1. 전자책 — 웹](./06-1-1-book-id-ebook-web.md).

## 2. 유저 플로우

1. 사용자는 `/book/[bookId]` 허브에서 오디오북을 선택한다. 서버 컴포넌트 또는 인증된 BFF가 세션 사용자와 `bookId` 소유/참여 권한, audio entitlement를 확인한다.
2. 무료 플랜은 비활성/잠금 상태와 플랜 안내만 보며, 생성 상태·MP3 URL·다운로드 API에는 접근할 수 없다.
3. 사용 가능 사용자는 review 완료 목차, 원고 기반 예상 길이, 이전 job/part 상태, 챕터별 잔여 제공 횟수를 확인한다.
4. 사용자는 Naver/CLOVA Voice를 샘플로 미리 듣고 하나를 선택하며, 라이선스가 검증된 BGM을 선택하거나 끈다.
5. `생성하기` 클릭 시 선택 목차·Voice·BGM·예상 시간, 비용/플랜 포함 여부, 한도 고지와 확인 모달을 먼저 표시한다. 확인 뒤에만 job 생성 요청을 보낸다.
6. 서버는 소유/참여·entitlement·챕터 review·한도·진행 중 job을 원자 검사해 job을 만든다. 화면은 job/part 진행률, 실패, 취소, 재시도 상태를 표시한다.
7. 완료된 MP3는 페이지 내 재생과 인증된 다운로드로 제공한다. 다운로드 요청도 서버가 권한·한도·파일 만료를 재검증한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 사용자 오디오북 화면 | `/book/[bookId]/audiobook`의 생성·관리·재생·다운로드 | 신규 |
| 무료 잠금 | 무료 플랜은 비활성·접근 불가, 유료 entitlement만 허용 | 신규 |
| reviewed 원고 자격 | 챕터별 reviewed notebook 원고만 생성 입력으로 사용 | 기존 원천/사용자 적용 신규 |
| 목차별 job/part | 챕터 단위 생성, 청크 진행률·취소·실패·재시도 | 기존 Admin 로직/사용자 계약 신규 |
| 생성 확인 | 비용·한도·예상 시간 고지 후 명시적 확인 | 신규 |
| 2회 제공 한도 | “각 2회”의 보수적 제안: 챕터별 제공/다운로드 한도 2회 | 신규 제안 |
| CLOVA Voice 선택 | 한국어 Voice 선택, 서버 생성 샘플 미리듣기 | 기존 Admin/사용자 UI 신규 |
| BGM 선택 | 검증된 카탈로그에서 선택/미사용, 믹싱 정보 표시 | 기존 단일 기본값/사용자 선택 신규 |
| MP3 재생·다운로드 | private stream 또는 짧은 수명 URL로 제공 | 기존 Admin 다운로드/사용자 제공 신규 |
| 완료 알림 | 현재 SMTP는 관리자 알림; 사용자 알림은 신규 정책 | 부분/신규 |

## 4. 화면 구성

### 접근·준비 상태

- 책 제목과 `오디오북` 헤더, 플랜 배지, 접근 상태를 표시한다.
- 무료 플랜에는 잠금 설명과 업그레이드 안내를 표시한다. 비활성 버튼만으로 끝내지 않고, 서버 응답도 미디어와 job 정보를 누락하거나 권한 오류를 반환한다.
- 유료 사용자는 챕터별 reviewed 준비 상태, 예상 분량, 생성/다운로드 잔여 횟수를 확인한다. reviewed 원고가 없으면 생성 버튼 대신 리뷰 이동 CTA를 제공한다.

### Voice·BGM·확인 모달

- Voice 목록은 이름·특성·선택 상태·`미리 듣기`를 제공한다. Next.js Route Handler/NestJS가 키를 보관하고 오디오 blob만 반환한다.
- BGM 목록은 제목·분위기·라이선스 출처·선택/끄기를 제공한다. 현재 Admin 구현은 환경변수 기반 단일 트랙과 고정 20% 기본 볼륨이므로, 사용자 선택은 신규 범위다.
- 확인 모달은 “이 목차의 오디오를 생성합니다”, 선택 설정, 예상 시간, 비용/플랜, 한도, 원고 수정 시 재생성 안내를 표시하고 `취소`와 `확인하고 생성`을 분리한다.

### 목차별 작업·플레이어

- 각 행은 목차명, 글자 수/예상 길이, 상태 배지, 진행률, 오류 문구, 생성·취소·재시도 버튼을 둔다.
- 완료 행은 웹 플레이어와 다운로드 버튼을 제공한다. 미디어 URL을 HTML/응답에 영구 노출하지 않으며, 재생/다운로드 직전에 인증된 stream 또는 짧은 만료 URL을 요청한다.
- 생성·다운로드 한도 차감이 언제 일어났는지와 남은 횟수를 보여 주되, 실제 수치는 서버가 반환한 값만 사용한다.

## 5. API 엔드포인트 (Route Handler / 공유 NestJS 전환 방향)

### 현재 Next.js Admin Route Handler

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` / `POST` | `/api/admin/users/[id]/audiobook` | 관리자 상태 조회·전체 job 생성. reviewed notebook 원고만 입력으로 사용 | 기존, Admin 전용 |
| `POST` | `/api/admin/users/[id]/audiobook/parts/[sortOrder]` | 관리자 목차 단건 생성 | 기존, Admin 전용 |
| `POST` | `/api/admin/users/[id]/audiobook/parts/[sortOrder]/cancel` | 관리자 단건 생성 취소 | 기존, Admin 전용 |
| `GET` | `/api/admin/users/[id]/audiobook/download` | 관리자 전체 MP3 다운로드 | 기존, Admin 전용 |
| `GET` | `/api/admin/users/[id]/audiobook/parts/[sortOrder]/download` | 관리자 챕터 MP3 다운로드·BGM 믹싱 | 기존, Admin 전용 |
| `POST` | `/api/admin/audiobook/voice-preview` | 관리자 CLOVA Voice 샘플 | 기존, Admin 전용 |
| `GET` / `PUT` | `/api/admin/audiobook/tts-prefs` | 관리자 전역 TTS preset 조회·저장 | 기존, Admin 전용 |

이 경로들은 `getValidAdmin()`을 요구한다. 일반 사용자가 자신의 ID를 넣어 호출할 수 없으며, 사용자 화면에서 그대로 재사용하면 안 된다.

### 사용자 Route Handler 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/books/[bookId]/audiobook` | 권한, reviewed 챕터, job/part 상태, 한도/잔여 제공 횟수 |
| `GET` | `/api/books/[bookId]/audiobook/voices` | 선택 가능한 Voice 메타데이터 |
| `POST` | `/api/books/[bookId]/audiobook/voice-preview` | 인증 사용자의 선택 Voice 샘플 스트림 |
| `GET` | `/api/books/[bookId]/audiobook/bgms` | 라이선스 검증 BGM 카탈로그 |
| `POST` | `/api/books/[bookId]/audiobook/chapters/[chapterId]/jobs` | 확인 뒤 챕터 job 생성 |
| `GET` | `/api/books/[bookId]/audiobook/jobs/[jobId]` | job/part 상태·진행률 조회 |
| `POST` | `/api/books/[bookId]/audiobook/jobs/[jobId]/cancel` | 권한 있는 요청자의 취소 |
| `GET` | `/api/books/[bookId]/audiobook/chapters/[chapterId]/stream` | 재생용 인증 stream/짧은 수명 URL |
| `POST` | `/api/books/[bookId]/audiobook/chapters/[chapterId]/downloads` | 다운로드 권한/한도 재검증·기록 후 파일 제공 |

### 공유 NestJS 전환 방향

1. 앱과 웹이 같은 책·플랜·한도를 보려면 NestJS에 `/v1/books/:bookId/audiobook/*` 공통 계약과 `audiobook`/`media` 도메인을 먼저 만든다.
2. Next.js Route Handler는 NextAuth 세션을 검증하는 BFF로 NestJS를 호출하거나, 서버 컴포넌트가 공통 API를 사용한다. Naver/CLOVA 키는 Next.js 또는 NestJS 서버 환경에만 두고 브라우저로 보내지 않는다.
3. 기존 Admin route와 `audiobook_job`은 운영 도구로 유지한다. 사용자용 다권 job 모델로 검증 후 점진 이전하며, 관리자 UI가 일반 사용자 파일을 우회 제공하는 경로가 되지 않게 한다.

## 6. 데이터 모델

| 모델 | 현재 역할/한계 | 사용자용 전환 방향 |
|---|---|---|
| `chapter_notebook` | 사용자·`contentId`별 원고, `draft/reviewed` 상태 | `book_id`, chapter ID, 원고 버전 도입; 오디오 생성 입력 범위 명시 |
| `audiobook_job` | `userId` 중심 전체 병합 MP3 BYTEA, 관리자 생성자·이메일 | `book_id`, 요청자, scope, 원고 version, Voice/BGM 스냅샷, 상태·비용·보존 기간 |
| `audiobook_job_part` | job별 sort order, 청크 진행, MP3 BYTEA | 안정적인 chapter ID, 출력 media asset, 취소·재시도·원고 version 연결 |
| `entitlement` | 없음 | 책/사용자/참여자·플랜/프로모션·audio 권한·만료·제한 서버 판정 |
| 제공 한도 ledger | 없음 | 생성/다운로드 구분 가능 카운터, 멱등성 키, 차감·복구 사유와 시각 |
| media asset | 없음 | private object key, MIME/크기/checksum, 파일 만료·삭제·접근 로그 |
| BGM catalog | 로컬 catalog JSON, 환경변수 기본 트랙 | 트랙 라이선스/출처/사용 가능 기간·지역, 사용자 선택 가능 여부 |

현재 Admin job은 이전 job을 삭제하고, job/part 데이터와 병합본을 PostgreSQL `BYTEA`에 저장한다. 사용자 서비스는 파일 용량·보존·삭제·접근 제어를 고려해 private object storage와 DB 메타데이터 분리를 우선 검토한다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Admin 오디오북 UI | `app/components/admin/UserDetailClient.tsx` | reviewed 원고 상태, 목차별/전체 생성·취소·다운로드, Voice 미리듣기/선택, 1.5초 폴링. BGM 볼륨 UI는 주석 처리되어 20% 고정 |
| Admin job API | `app/app/api/admin/users/[id]/audiobook/route.ts`, `parts/[sortOrder]/route.ts`, `parts/[sortOrder]/cancel/route.ts` | 관리자 권한 확인, 전체/단건 job 생성과 취소 |
| Admin 파일 API | `app/app/api/admin/users/[id]/audiobook/download/route.ts`, `parts/[sortOrder]/download/route.ts` | 관리자 전용 `private, no-store` MP3 응답과 Content-Disposition |
| Admin Voice/TTS 설정 API | `app/app/api/admin/audiobook/voice-preview/route.ts`, `tts-prefs/route.ts` | 관리자만 CLOVA 샘플 생성, 전역 preset 관리 |
| 작업 처리 | `app/lib/audiobook/jobs.ts`, `source.ts`, `script.ts`, `mp3.ts`, `pause.ts` | reviewed notebook 원고 해석, 1,800자 이하 청크 TTS, part 진행·취소·병합, 전체 완료 SMTP 호출 |
| CLOVA 연동 | `app/lib/audiobook/clova-tts.ts`, `clova-voices.ts` | 서버 환경변수 `NCP_CLOVA_CLIENT_ID/SECRET`, Voice 목록과 MP3 요청 |
| BGM | `app/lib/audiobook/bgm.ts`, `bgm-mix.ts` | 로컬/preview BGM, ffmpeg 믹싱, 기본 20%, 최대 35%, 믹싱 실패 시 음성만 반환 |
| 메일·스키마 | `app/lib/mail/audiobook.ts`, `app/lib/db/schema.ts` | 현재 완료 메일은 관리자 대상, `audiobook_job`/`audiobook_job_part` BYTEA·진행 필드 |
| 현재 사용자 TTS | `app/app/api/tts/route.ts`, `app/app/api/tts/voices/route.ts`, `app/hooks/useTTS.ts` | 작성 흐름용 OpenRouter TTS와 보이스 목록; 오디오북 CLOVA job과 별개 |
| 플랜/승인 현황 | `app/lib/approvals.ts`, `app/lib/db/schema.ts`, `docs/screens/01-landing-web.md` | approval에는 티어·entitlement가 없고, 랜딩의 오디오북 플랜 정책은 신규 집행 대상 |

## 8. 신규 개발 범위 요약

1. **웹 화면**: `/book/[bookId]/audiobook` 서버 페이지와 작은 client 컴포넌트로 잠금, Voice/BGM 선택·미리듣기, 명시적 생성 확인, 챕터 상태·플레이어·다운로드, 로딩/오류/빈 상태를 구현한다.
2. **공통 API/도메인**: NestJS의 다권 audiobook/media/entitlement/job 계약과 worker를 우선 구현하고, Next.js는 BFF 또는 공통 계약 클라이언트로 전환한다.
3. **기존 Admin 분리**: Admin route와 UI는 운영 생성 도구로 유지하되, 사용자 권한·플랜·카운터를 Admin 검사로 대체하지 않는다. user-facing endpoint는 별도 소유/참여 검사를 갖는다.
4. **미디어 처리**: CLOVA 요청 청크·취소/재개·중복 방지, BGM 라이선스 카탈로그·안전한 믹싱, private storage, 인증 stream·만료 URL·접근 로그를 구현한다.
5. **권한·한도**: 무료 잠금, 유료 entitlement, 챕터 reviewed, “2회” 정책, 동시 요청·실패 재시도는 서버 transaction/조건부 갱신으로 집행한다.
6. **완료 통지**: 기존 SMTP는 관리자에게만 보낸다. 사용자 이메일·앱 내 알림을 새로 제공할지, 민감 MP3 링크를 메일에 넣지 않을지 정한다.

## 9. 열린 이슈 / 가정

1. “각 2회”가 생성·다운로드 중 무엇인지, 또는 양쪽 모두인지 미정이다. 이 문서는 **챕터별 제공/다운로드 한도 2회**를 보수적 제안으로만 두며, 생성·다운로드·재생 카운터 분리와 사용자 고지를 확정해야 한다.
2. 생성 확인의 비용/플랜 포함 문구, 프로모션·환불·재생성 비용, `approval_request`를 대체할 entitlement/order 모델이 미정이다.
3. UI disable은 권한 통제가 아니다. 책/챕터/사용자별 entitlement와 카운터를 job 생성, stream, 다운로드에서 원자적으로 재검증해야 하며, 동시 생성 중복과 HTTP 재시도 멱등성 키가 필요하다.
4. 실패·취소·CLOVA 제공자 오류·BGM 믹싱 실패 때 한도를 언제 소모/복구하는지 정해야 한다. 현재 Admin BGM 믹싱은 실패해도 음성 파일을 반환하므로 사용자 고지 기준도 필요하다.
5. 기존 전체 job 생성은 같은 사용자 이전 job을 삭제한다. 사용자용 다권/챕터 제공에서는 이전 버전 보존·삭제·원고 수정 후 무효화·재생성 규칙을 별도로 설계해야 한다.
6. BGM은 파일 라이선스·상업 이용·재배포·지역/기간 제한, 출처 증빙, 업로드 파일 검증, 음성 대비 볼륨·길이·루프/페이드·믹싱 품질을 해결해야 한다.
7. 원고와 MP3는 민감정보다. 소유자/참여자 권한, 브라우저 캐시와 기기 공유 안내, 파일 만료·삭제, 관리자 접근 범위, 생성·재생·다운로드 접근 로그와 보존 기간이 필요하다.
8. Naver/CLOVA API 키를 브라우저에 노출하거나 클라이언트에서 직접 호출하면 안 된다. Next.js 또는 NestJS 서버만 secret을 보관하고, 앱/웹은 인증된 job·stream/download API만 호출한다.
9. 현재 Next.js Drizzle과 Flutter/NestJS TypeORM은 사용자 ID·단일 책 모델이 분리되어 있다. `bookId` 매핑, 데이터 마이그레이션·롤백, 가족 참여 권한, 웹 우선 편집 충돌을 정하기 전에는 동일 오디오북을 공유한다고 가정할 수 없다.
