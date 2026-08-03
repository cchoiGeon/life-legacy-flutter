# 6-1. book/[id] — 특정 자서전 에디션 상세 (Next.js 웹)

## 1. 개요

`/book/[bookId]`는 한 권/에디션의 작성 진행, 현재 Question, 목차별 리뷰 상태, 전자책·오디오북·AI 영상 그림책 진입을 제공하는 웹 허브다.

- 현재 웹에는 `/book`·`/book/[bookId]`가 없다. `/mypage`가 단일 사용자·단일 자서전의 진행 허브이며, `/write/[contentId]`는 대목차 기반 작성 경로다.
- 현재 Question의 웹 진입 후보는 `/book/[bookId]/write?questionId=...`이다. 현 UI/API는 `/write/[contentId]?questionId=...`를 사용하므로, 다권 전환 전에는 위 경로를 기존 화면의 별칭으로 단정하지 않고 **신규 라우트**로 취급한다.
- “목차 완주율 길 이정표”에 대응하는 확인된 Figma 노드는 없다. 클릭 가능한 이정표와 상세 진행 route는 제안 범위다.

관련 화면: [6 내 책](./06-book-web.md), [4 작성](./04-book-id-write-web.md), [5 리뷰](./05-book-id-review-web.md).

## 2. 유저 플로우

1. `/book` 목록 또는 `/continue` 전환 뒤 사용자가 `/book/[bookId]`에 진입한다.
2. 서버 컴포넌트 또는 인증된 Route Handler가 세션 사용자와 `bookId`의 소유/참여 권한을 확인하고, 현재 Question·진행도·review 상태·entitlement를 조회한다.
3. 현재 소질문이 있으면 상단 알림 카드에 표시한다. `답변하러 가기`는 신규 `/book/[bookId]/write?questionId=...`로 이동한다.
4. 사용자는 목차별 답변 진행, 리뷰 완료, 전체 진행률을 본다. 길 이정표 버튼은 후보 상세 route(`/book/[bookId]/progress`)로 이동한다.
5. 리뷰 완료 상태에 따른 전자책 미리보기 자격을 확인하고 ebook으로 이동한다. 무료는 ebook만 활성화하며, 오디오북/AI 영상 그림책은 entitlement가 없으면 잠금 UI를 보인다.
6. 팩트 체크가 구현되면 리뷰 완료 원고에서 뽑은 “검토가 필요한 후보”를 사용자가 원본/공식 자료로 확인하고 수정·무시하거나 Question으로 전환한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 단일 자서전 허브 | `/mypage`의 진행 요약, 대목차/답변 관리, 노트북·미리보기 CTA | 기존 |
| 다권 상세 허브 | `/book/[bookId]` 범위의 진행·후처리·권한 통합 | 신규 |
| 현재 Question 카드 | 책 범위 다음 소질문 및 작성 진입 | 신규 |
| 목차 진행률 | `/api/dashboard-summary`, `writing_progress`의 사용자 전체 집계 | 기존, 다권 전환 필요 |
| 챕터 리뷰 완료 | `chapter_notebook.status=reviewed` | 기존 일부, `bookId` 범위 필요 |
| 길 이정표 상세 뷰 | 목차 완주율을 버튼형 이정표로 연결 | 신규 제안 |
| ebook 미리보기·내보내기 | 노트북/편집본/답변 기반 책 미리보기·PDF/DOCX | 기존, 다권 전환 필요 |
| 오디오북 | Clova TTS job 생성·다운로드는 Admin 전용 | 사용자 기능 신규 |
| AI 영상 그림책 | 설계 문서만 존재, 구현 Route/API는 확인되지 않음 | 신규 |
| 플랜 잠금 | 현재 entitlement·quota 모델 없음 | 신규 |
| 팩트 체크 | 검토 후보 추출·확인·수정/무시·Question 전환 | 향후 TODO |

### 플랜 잠금과 보안 경계

- 랜딩 가격 스펙은 무료=챕터1 작성/노트북 리뷰, 유료 T1=전자책+오디오북, T2=AI 영상 추가, T3=전자책+오디오북+인쇄, T4=전체로 정의한다. 다만 `approval_request`에는 티어·금액·entitlement 컬럼이 없고 실제 결제는 상태 변경 목업이다.
- 이 화면은 사용자 스펙에 따라 무료 ebook만 활성화하고 오디오북/AI 영상 그림책을 잠근다. 세부 T1~T4 허용 여부는 서버 권한표가 확정될 때까지 고정하지 않는다.
- 버튼을 숨기거나 비활성화하는 것은 보안 통제가 아니다. 원고 조회/내보내기, 오디오 다운로드·생성, 영상 생성·재생 API 각각에서 entitlement를 검증한다.

### 팩트 체크의 제품 원칙

- 날짜·이름·장소·숫자는 “사실” 또는 “오류”로 판정하지 않고 **검토가 필요한 후보**로만 제시한다.
- 외부 검색으로 자동 검증하지 않는다. 사용자가 원문, 공식 자료, 가족 확인 등을 통해 검토하고 수정·무시·Question 전환을 결정한다.
- AI의 환각이나 문맥 누락으로 인한 후보 오류를 고려해 사용자 승인 없이 원고를 바꾸지 않는다.

## 4. 화면 구성

### 현재 Question 카드

- 카드에는 다음 소질문, 해당 목차, `답변하러 가기`, X를 둔다.
- 현재 `/mypage`의 “다시 답변” 링크는 `/write/[contentId]?questionId=...`를 사용한다. 다권 상세에서는 `bookId`와 `questionId`를 모두 유지하는 신규 경로/세션 API가 필요하다.
- X는 화면 카드 닫기, 오늘 알림 해제·미루기, 읽음 중 어느 정책인지 미정이다. 정책 확정 전에는 지속 상태 변경을 하지 않는다.

### 진행 현황과 이정표

- 상단에는 전체 질문 진행률·완료 목차 수·review 완료 수를 둔다.
- 각 목차에는 답변 수/전체 수, 작성/완료 상태, review 완료 배지, ebook 자격 상태를 표시한다.
- 길 이정표는 각 목차 구간을 버튼으로 제공하고 상세 진행 route로 연결한다. 현 Figma 시안이 확인되지 않았으므로 화면 배치와 동작은 별도 디자인 결정이 필요하다.

### 출판 액션

- **자서전 미리보기(ebook)**: 기존 `/mypage/preview`의 표지, BookPreview, Word 편집, PDF/DOCX 내보내기를 다권 route로 이관한다.
- **음성책 관리**: 현재 `/api/admin/users/[id]/audiobook/*`는 관리자만 접근할 수 있다. 사용자용 생성 상태·재생·다운로드 화면은 별도 개발이 필요하다.
- **AI 영상 그림책 관리**: 관리자 전용 파이프라인 설계 문서만 존재하며 사용자 route, 작업 API, 실제 생성 파이프라인은 확인되지 않았다.
- ebook의 버튼 범위(전체 책/챕터별)와 “챕터 완료+리뷰 완료”가 최소 자격인지 여부는 API 응답의 preview scope로 명시해야 한다.

### 팩트 체크 패널 (TODO)

- 리뷰 완료된 챕터 원고를 입력으로 후보 JSON을 생성한다. 각 항목은 유형(날짜/이름/장소/숫자), 텍스트, 최소 문맥, 원고 위치, 추출 근거, 사용자 상태를 가진다.
- 사용자에게 확인 방법을 안내하고, `수정`, `무시`, `Question으로 확인`만 제공한다. 자동 수정과 자동 검증은 제공하지 않는다.
- AI 전송 전 고지와 동의를 확인하고, 처리 중/실패/재시도 및 원고 버전 불일치 상태를 보여 준다.

## 5. API 엔드포인트 (Route Handler / 공유 NestJS 전환 방향)

### 현재 Next.js Route Handler

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/api/dashboard-summary` | 사용자 전체 질문·목차 진행 요약 | 기존 |
| `GET` | `/api/progress` | 현재 `contentId`/`questionId`와 상태 | 기존 |
| `GET` / `POST` / `PATCH` | `/api/user-contents` | 사용자 목차 조회·추가·순서 변경 | 기존 |
| `GET` / `PATCH` | `/api/notebook` | 대목차 원고, 사진 배치, `reviewed` 상태 | 기존 |
| `GET` / `PUT` | `/api/cover` | 사용자당 한 표지 | 기존 |
| `GET` / `POST` | `/api/manuscript-edit` | 사용자당 활성 편집본/편집 이력 | 기존 |
| `POST` | `/api/export-pdf` | 미리보기 페이지 PDF 생성 | 기존 |
| `GET` | `/api/export-docx` | DOCX 내보내기 | 기존 |
| `GET` / `POST` | `/api/admin/users/[id]/audiobook` | 관리자 권한의 오디오북 상태/생성 | 기존, 사용자 비노출 |

현재 경로는 세션 사용자 조건으로 조회하지만 모두 사용자당 단일 책 전제다. Next.js에서 사용자 알림 구현은 확인되지 않았으므로 웹 상단의 Question 카드는 별도 인앱 알림 기능으로 가정하지 않는다.

### 다권 Route Handler 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/books/[bookId]` | 상세 허브용 책·권한·기본 상태 |
| `GET` | `/api/books/[bookId]/dashboard-summary` | 현재 Question, 진행·review 집계, 목차별 상태 |
| `GET` | `/api/books/[bookId]/progress` | 길 이정표/상세 진행 데이터 |
| `GET` | `/api/books/[bookId]/contents` | 책 범위 목차와 소질문 상태 |
| `GET` | `/api/books/[bookId]/chapters/[chapterId]/ebook-eligibility` | review·완료 상태 기반 미리보기 scope |
| `GET` | `/api/books/[bookId]/entitlements` | ebook/audio/storybook별 권한·한도 |
| `GET` / `PUT` | `/api/books/[bookId]/cover` | 책별 표지 |
| `GET` / `PATCH` | `/api/books/[bookId]/notebook` | 책 범위 챕터 원고·review 상태 |
| `POST` | `/api/books/[bookId]/fact-checks` | 리뷰 완료 원고의 후보 추출 작업 생성 |
| `GET` | `/api/books/[bookId]/fact-checks` | 후보와 사용자 처리 상태 조회 |
| `PATCH` | `/api/books/[bookId]/fact-checks/[candidateId]` | 수정/확인/무시 상태 기록 |
| `POST` | `/api/books/[bookId]/fact-checks/[candidateId]/questions` | 후보를 확인 Question으로 전환 |

### 공유 NestJS 전환 방향

Flutter와 웹의 같은 에디션·진행·권한을 공유하려면 Next.js 단독으로 `/api/books`를 만들지 않는다.

1. NestJS에 다권 `GET /v1/books/:bookId/dashboard`, 진행, entitlement, 팩트 체크 API를 먼저 만든다.
2. Next.js Route Handler는 세션을 검증하는 BFF로서 NestJS API를 호출하거나, 서버 컴포넌트가 공통 계약을 사용한다.
3. 기존 Drizzle 데이터는 `book_id`를 추가해 마이그레이션한다. 웹과 NestJS를 별도 원본으로 유지하면 동일 사용자가 다른 진행률과 잠금을 보게 된다.

어느 방식이든 URL의 `bookId`, client-side plan 값, hidden button은 권한 근거가 될 수 없다.

## 6. 데이터 모델

| 모델 | 현재 역할/한계 | 변경 방향 |
|---|---|---|
| `user_content` / `user_question` | 사용자 직접 귀속 | `book_id`와 책 범위 유니크 제약 필요 |
| `answer` / `answer_draft` | 사용자·대목차·질문 단위 | 책/에디션 범위, 원고 버전과 팩트 후보 원천 연결 |
| `writing_progress` | `userId` unique, 단일 현재 위치 | `book_id`별 진행·현재 Question·review 집계로 전환 |
| `chapter_notebook` | 사용자/대목차별 원고와 `draft/reviewed` | `book_id`, 챕터/원고 버전, ebook 자격 판단 연결 |
| `book_cover` | `userId` unique | `book_id`별 표지 |
| `manuscript_edit_history` | 사용자 편집본 | `book_id` 연결 |
| `approval_request` | 승인/결제 상태만 보유 | 책/에디션과 주문/entitlement로 분리 또는 확장 |
| `audiobook_job` / `audiobook_job_part` | 관리자 생성 원고·MP3 작업 | 책별 사용자 작업/재생 권한/다운로드 정책으로 재설계 |
| storybook 작업 모델 | 없음 | 책/챕터, 생성 입력·출력·상태·권한·비용 추적 신규 |
| entitlement | 없음 | 요금제·프로모션·기능·사용량/만료를 서버에서 판정하는 모델 신규 |
| fact-check candidate | 없음 | 원고 버전, 후보/문맥, AI 추출 이력, 사용자 처리/Question 연결 모델 신규 |

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 단일 허브 UI | `app/app/(dashboard)/mypage/page.tsx` | 진행 요약, 목차별 답변 상태, `/write/[contentId]?questionId=...`, 노트북/미리보기 CTA |
| 진행 API | `app/app/api/dashboard-summary/route.ts`, `app/app/api/progress/route.ts` | 세션 사용자 전체 집계·현재 위치 |
| 목차 API | `app/app/api/user-contents/route.ts` | 사용자 범위 목차 CRUD/재정렬 |
| 노트북 | `app/app/(dashboard)/mypage/notebook/NotebookClient.tsx`, `app/app/api/notebook/route.ts` | 챕터 원고·사진 placement·`reviewed` 상태 |
| ebook 미리보기 | `app/app/(dashboard)/mypage/preview/page.tsx`, `app/components/BookPreview/`, `app/lib/book/resolveManuscript.ts` | 표지·미리보기·편집·PDF/DOCX 기반 |
| 표지/편집 스키마 | `app/lib/db/schema.ts` | `answer`, `answer_draft`, `writing_progress`, `chapter_notebook`, `book_cover`, `approval_request` |
| Admin 오디오북 | `app/app/api/admin/users/[id]/audiobook/route.ts`, `app/components/admin/UserDetailClient.tsx`, `app/lib/audiobook/` | 관리자 권한의 Clova TTS job·MP3 처리 |
| 그림책 설계 | `docs/superpowers/specs/2026-08-02-chapter-storybook-hybrid-design.md`, `docs/superpowers/specs/2026-08-01-chapter-storybook-video-design.md` | 관리자 중심 설계 문서; 구현 route/API 미확인 |
| 가격 스펙 | `docs/screens/01-landing-web.md` | 무료~T4 기능 매트릭스, entitlement 미구현 근거 |

## 8. 신규 개발 범위 요약

- Next.js: `/book/[bookId]` 서버 페이지와 현재 Question·진행·review·잠금 상태 UI, 이정표 상세 route, 로딩/권한 오류/빈 상태.
- Next.js: `/book/[bookId]/write?questionId=...`, preview/cover/notebook/export의 책 범위 경로 및 기존 `/mypage`·`/write/[contentId]` 호환 전략.
- API/데이터: 책별 진행·목차·원고·표지·편집본, 챕터 ebook 자격, entitlement와 모든 보호 리소스의 서버 검사.
- 후처리: 사용자용 오디오북/AI 영상 그림책 관리와 비동기 작업·미디어 접근 모델. 현재 Admin/API 설계를 곧바로 사용자 기능으로 재사용하지 않는다.
- 팩트 체크: AI 후보 추출의 동의·보존 통제, human-in-the-loop 처리, Question 전환과 감사 가능한 원고 버전 연결.
- 통합: 공유 NestJS API 또는 명시적 BFF 전환, 기존 Drizzle 데이터의 `bookId` migration 및 앱/웹 충돌 정책.

## 9. 열린 이슈 / 가정

1. X의 의미가 단순 카드 닫기인지, 오늘 알림 해제/미루기/읽음인지 미정이다. 지속 상태를 바꾸려면 알림별 정책과 API가 필요하다.
2. 웹은 현재 확인된 사용자 알림/푸시 구현이 없다. 앱의 NestJS 인앱 알림 목록과 웹 알림 UX를 공유할지, 이 카드만 진행 CTA로 둘지 결정해야 한다.
3. 길 이정표 Figma 시안/노드가 확인되지 않았다. 페이지 구조, 클릭 대상, 접근성 표현, 세부 route를 디자인 확정 후 결정한다.
4. 무료 ebook 지원과 T1~T4의 실제 활성화 규칙은 entitlement·결제·프로모션 모델이 없으므로 아직 집행할 수 없다. 랜딩 가격 스펙과 기존 운영 로드맵의 티어 재정의/무료 프로모션 관계를 확정해야 한다.
5. ebook의 범위가 전체 책인지 챕터별인지, 리뷰 완료가 어떤 미리보기 범위를 여는지 결정해야 한다.
6. 오디오북은 현재 Admin 전용이고, AI 영상 그림책은 설계 문서만 있다. 사용자 관리 화면, 생성 실패/재시도, 다운로드/스트리밍, 비용/쿼터 및 권한 검증이 모두 신규이다.
7. 팩트 체크는 AI가 사실을 확정하거나 외부 검색으로 자동 검증해서는 안 된다. 후보 문구·사용자 확인 절차·수정 전후 버전/되돌리기·무시 이력 정책이 필요하다.
8. 날짜·이름·장소·숫자 추출과 AI 전송은 민감 개인정보 처리다. 명시적 고지/동의, 전송 최소화, 제공자 학습 이용·보관·삭제, 암호화·접근 로그·보존 기간을 확정해야 한다.
9. 후보 추출 모델의 환각, 원고 버전 변경, 동명이인/표기 차이, 문맥 누락을 어떻게 사용자에게 설명하고 재실행/삭제할지 결정해야 한다.
10. Next.js Drizzle과 Flutter/NestJS TypeORM은 사용자 ID·DB·단일 책 모델이 분리돼 있다. 동일 에디션 공유 전에 `bookId` 매핑, migration 순서·롤백, 소유/가족 참여 권한, 웹 우선 편집 충돌 정책을 확정해야 한다.
