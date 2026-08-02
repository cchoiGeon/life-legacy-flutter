# 6. book — 내 책 목록·허브 (Next.js 웹)

## 1. 개요

`/book`은 한 사용자의 여러 자서전을 관리하는 웹 책 목록/허브다. 현재 웹에는 `/book` 라우트가 없고, `/mypage`가 단일 사용자·단일 자서전의 사실상 허브 역할을 한다. 이 화면은 그 허브의 진행 요약, 대목차 관리, 노트북, 표지, 미리보기 기능을 다권 `bookId` 범위로 재구성한다.

- 목표 경로: `/book`은 목록, `/book/[bookId]`는 6-1 상세 허브, `/book/[bookId]/write`와 `/book/[bookId]/review`는 후속 화면이다.
- 현재 `/continue`는 프로필/진행 상태에 따라 `/intro`, `/write/[contentId]`, `/mypage`로만 분기한다.
- 현 Next.js Route Handler + Drizzle은 사용자당 최신 목차·진행 상태를 직접 보유하며, 공유 NestJS/TypeORM 데이터와 분리되어 있다. 다권 공유를 실제화하려면 Route Handler 확장 또는 NestJS 공통 API 전환을 선택해야 한다.

관련 화면: [3-1 intro2](./03-1-intro-toc-web.md), [4 작성](./04-book-id-write-web.md), [5 리뷰](./05-book-id-review-web.md).

## 2. 유저 플로우

1. 로그인한 사용자는 내비게이션, `/continue`, 목차 완료 CTA 등에서 `/book`으로 진입한다.
2. 서버 컴포넌트 또는 인증된 목록 Route Handler가 세션의 사용자 ID로 접근 가능한 책 목록을 조회한다. 요청의 클라이언트 user ID를 신뢰하지 않는다.
3. 상단에 제작 중인 책과 제작 완료된 책을 카드로 표시한다.
   - 모바일: 카드 폭을 유지한 가로 스크롤 또는 스냅 캐러셀을 우선 검토한다.
   - 태블릿/데스크톱: 카드 수·컨테이너 폭에 따라 다열 그리드 또는 가로 목록을 선택한다.
   - 구현을 하나로 확정하지 않고, 작은 화면은 터치 스크롤과 충분한 카드 폭, 넓은 화면은 여러 책의 비교·빠른 탐색을 보장하는 반응형 기준으로 둔다.
4. 카드를 클릭하면 `/book/[bookId]` 상세 허브로 이동한다.
5. 하단에는 기본 프로필과 간단한 문구, 책/진행 후보 정보를 표시한다. 연락처·주소는 기본 노출하지 않는다.
6. 상세 허브에서 이어쓰기, 노트북 기반 리뷰, 표지, 미리보기, 내보내기로 이동한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| `/mypage` 단일 허브 | 진행률, 대목차/답변 관리, 사진 임시함, 노트북·미리보기 CTA | 기존 |
| `/book` 목록 라우트 | 소유/참여 가능한 여러 책을 카드로 조회 | 신규 |
| 반응형 카드 배치 | 모바일 가로 스크롤/캐러셀, 넓은 화면 그리드 또는 가로 목록을 화면 폭과 카드 수로 선택 | 신규 |
| 제작 중/완료 분리 | 서버가 판정한 책 상태로 두 섹션 구성 | 신규 |
| 상세 진입 | `/book/[bookId]`로 선택한 책의 허브 진입 | 신규 |
| 기존 후처리 재사용 | 책 범위로 노트북, 표지, 미리보기·PDF/DOCX 내보내기 기능을 전환 | 변경 필요 |
| 하단 최소 정보 | 이름, 책 수, 진행률, 마지막 활동 시각 등의 후보 표시 | 신규 |
| 개인정보 최소 노출 | `user`의 phone·postalCode·roadAddress·addressDetail은 기본 비노출 | 신규 정책 |

상태 `draft` / `writing` / `reviewing` / `completed`는 카드 표시를 위한 **후보**다. 현재 `writing_progress.status`의 의미 및 노트북 `draft` / `reviewed`와 같다고 단정하지 않는다.

## 4. 화면 구성

### 상단 목록과 반응형 기준

- `제작 중인 자서전`: 작성/리뷰/후처리 중인 책 카드.
- `제작 완료된 자서전`: 제품이 합의한 완료 기준을 충족한 책 카드.
- 카드에는 표지, 제목, 저자 또는 표시 이름, 후보 상태 라벨, 진행률/최근 활동 후보를 둔다.
- 모바일(좁은 뷰포트)은 한 카드의 제목·진행률이 읽히는 최소 폭을 보장하고, 수평 스크롤 또는 스냅을 제공한다. 키보드 포커스와 스크린리더 순서도 카드 배열과 동일해야 한다.
- 중간/넓은 뷰포트는 컨테이너 폭과 카드 수에 따라 2~N열 그리드 또는 수평 목록을 적용한다. 카드가 적을 때 불필요한 캐러셀을 강제하지 않는다.
- 로딩은 카드 스켈레톤, 실패는 재시도와 기존 `/mypage` 또는 안전한 대시보드로 돌아갈 수 있는 안내를 제공한다.

### 카드와 상세 허브 연결

- 카드 전체를 링크로 구성하고 `/book/[bookId]`에서 서버가 세션 사용자와 `bookId`의 소유/참여 권한을 재검증한다.
- 현재 `/mypage/preview`, `/mypage/cover`, `/mypage/notebook`은 URL에 책 범위가 없으므로 책 카드에서 곧바로 이 경로들로 연결하지 않는다. 6-1 상세 허브가 `bookId` 범위를 유지해 후속 경로로 전달한다.
- 목록이 없을 때는 `/intro` 시작 CTA를 제공한다. 새 책 시작은 기존 `user_content`·`answer`를 초기화하는 현 생성 로직과 분리해야 한다.

### 하단 정보

| 후보 | 실제 구현 근거 | 기본 노출 |
|---|---|---|
| 이름 | `user.name` | 노출 가능 |
| 책별 제목/표지 | `book_cover`에 제목·저자·배경 보유 | 다권 연결 후 노출 가능 |
| 질문/목차 진행률 | `writing_progress`, `getDashboardSummary` | 노출 가능 |
| 노트북 검토 진행 | `chapter_notebook`, `writing_progress.notebookStatus` | 후보 |
| 마지막 수정 시각 | 다수 테이블 `updated_at` | 집계 규칙 확정 후 후보 |
| 전화번호·우편번호·도로명·상세 주소 | `user` 테이블 | 기본 비노출 |

## 5. API 엔드포인트 (Route Handler / 공유 NestJS 전환 방향)

### 현재 Next.js Route Handler

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` | `/api/dashboard-summary` | 사용자 전체 질문·대목차 진행 요약 | 기존 |
| `GET` | `/api/progress` | 현재 `contentId`/`questionId`와 상태 조회 | 기존 |
| `GET` / `POST` / `PATCH` | `/api/user-contents` | 사용자 대목차 조회·마지막 추가·전체 순서 변경 | 기존 |
| `PATCH` / `DELETE` | `/api/user-contents/[id]` | 제목 변경/대목차와 관련 질문·답변 삭제 | 기존 |
| `GET` / `PATCH` | `/api/notebook` | 대목차 노트북 원고·사진 배치·검토 상태 | 기존 |
| `GET` / `PUT` | `/api/cover` | 사용자당 한 표지 설정 | 기존 |
| `GET` / `POST` | `/api/manuscript-edit` | 사용자당 활성 편집본/편집 이력 기반 원고 | 기존 |

현재 Route Handler는 세션 또는 `getValidUserId()`로 사용자 ID를 얻어 `userId` 조건을 적용한다. 그러나 전부 사용자당 단일 책 전제이므로 `/book` 목록을 제공하지 않으며, `bookId` 조건도 없다.

### 다권 Route Handler 제안

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` | `/api/books` | 세션 사용자에게 허용된 책 카드 목록과 상태/진행 요약 | 신규 제안 |
| `POST` | `/api/books` | 새 책 또는 에디션 초안 생성 | 신규 제안 |
| `GET` | `/api/books/[bookId]` | 6-1 상세 허브용 책, 권한, 진행 요약 | 신규 제안 |
| `GET` | `/api/books/[bookId]/dashboard-summary` | 선택 책의 진행 요약 | 신규 제안 |
| `GET` | `/api/books/[bookId]/contents` | 선택 책의 사용자 목차 | 신규 전환 |
| `GET` / `PATCH` | `/api/books/[bookId]/notebook` | 선택 책의 챕터 원고/리뷰 상태 | 신규 전환 |
| `GET` / `PUT` | `/api/books/[bookId]/cover` | 선택 책 표지 | 신규 전환 |

각 handler는 URL의 `bookId`를 받더라도 세션 사용자 기준으로 `book.ownerUserId` 또는 허용된 참여 관계를 서버에서 검증해야 한다. 미래 가족 공유는 `book_participant` 같은 서버 관계로 필터링하며, 브라우저의 current user ID·로컬 상태를 권한 근거로 쓰지 않는다.

### 공유 NestJS 전환 방향

Flutter와 웹의 책 목록·진행 데이터를 실제로 공유하려면 다음 중 하나를 명시적으로 선택한다.

1. Next.js Route Handler가 NestJS `/v1/books` 및 `/v1/books/:bookId/*`를 인증된 BFF로 호출한다.
2. 웹 클라이언트/서버 컴포넌트가 공통 NestJS API 계약을 사용하고, 기존 Next.js Drizzle 데이터를 마이그레이션한다.

현재 NestJS에는 `/v1/book`, `/v1/book/pages`만 있고 `book.user_id`가 PK이므로, 먼저 NestJS의 다권 모델·소유/참여 검사·목록 API가 필요하다. Next.js의 신규 `/api/books`만 별도로 만들면 앱과 웹은 다시 서로 다른 책 목록을 보게 된다.

## 6. 데이터 모델

| 모델 | 현재 역할/한계 | 다권 전환 방향 |
|---|---|---|
| `user` | 이름, 이메일, 연락처, 주소, 작성 UI 설정 | 사용자 기본 정보 유지. 민감 연락처는 책 목록 DTO에서 제외 |
| `profile` | 사용자당 1개 자기소개/케이스 | 책별 인트로를 지원할지 사용자 프로필 공용으로 둘지 결정 필요 |
| `outline` | 사용자별 최신 목차 JSON | `book_id`를 추가하거나 책별 모델로 대체 |
| `user_content` / `user_question` | 사용자 직접 귀속, `contentId`/`questionId` 기반 사본 | `book_id`를 추가하고 `(book_id, sort_order)` 범위로 전환 |
| `answer` / `answer_draft` | 사용자·콘텐츠·질문 단위 답변/초안 | `book_id`로 범위를 명시하고 기존 행을 첫 책으로 backfill |
| `writing_progress` | `userId`가 unique인 단일 진행 상태 | `book_id`별 진행 행으로 전환 |
| `chapter_notebook` | 사용자/대목차 단위 원고·사진 placement | `book_id`와 장 식별 범위, 원고 버전 정책 필요 |
| `book_cover` | `userId`가 unique인 사용자당 한 표지 | `book_id`별 표지로 전환 |
| `manuscript_edit_history` | 사용자 편집본 | 어느 책의 편집본인지 `book_id` 연결 필요 |
| `approval_request` | 사용자 단위 승인·제작 상태 | 책/에디션 단위 주문·승인으로 전환 필요 |
| 책/참여 관계 | 없음 | `book`과 `book_participant` 또는 동등 모델 신규 |

현 데이터는 사용자당 한 권을 전제로 한다. 마이그레이션에서는 기존 사용자마다 첫 책/에디션을 생성한 뒤 기존 표지·목차·질문·답변·노트북·진행·편집본·승인 데이터가 그 첫 책을 가리키도록 backfill한다. 특히 `userId unique`인 `writing_progress`, `book_cover` 같은 제약을 책 범위로 바꾸고, 무결성 검증 및 롤백 계획을 마련해야 한다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 현 단일 허브 | `app/app/(dashboard)/mypage/page.tsx` | 진행 요약, 대목차 카드, 사진 임시함, 노트북/미리보기 CTA |
| 이어쓰기 분기 | `app/app/continue/page.tsx` | 현재 `/intro`·`/write/[contentId]`·`/mypage` 분기, `/book` 없음 |
| 진행 API | `app/app/api/dashboard-summary/route.ts`, `app/app/api/progress/route.ts` | 인증 사용자 전체 요약/현재 위치 |
| 대목차 API | `app/app/api/user-contents/route.ts`, `app/app/api/user-contents/[id]/route.ts` | 사용자 범위 CRUD·순서·삭제 시 질문/답변 삭제 |
| 노트북 API | `app/app/api/notebook/route.ts` | `contentId`별 원고·사진 배치·reviewed 상태 |
| 노트북 UI | `app/app/(dashboard)/mypage/notebook/NotebookClient.tsx` | 단일 사용자 대목차 원고 종합·편집 |
| 미리보기 | `app/app/(dashboard)/mypage/preview/page.tsx`, `app/components/BookPreview/` | 기존 원고/노트북/편집본 우선순위, 표지·PDF/DOCX |
| 표지 | `app/app/(dashboard)/mypage/cover/page.tsx`, `app/app/api/cover/route.ts` | 사용자당 표지 설정/업로드/AI 배경 |
| 데이터 스키마 | `app/lib/db/schema.ts` | `user`, `profile`, `outline`, `user_content`, `user_question`, `answer`, `writing_progress`, `chapter_notebook`, `book_cover`, `approval_request` |
| NestJS 공통 전환 근거 | `server/src/book/book.controller.ts`, `services/book.service.ts`, `entities/book.entity.ts` (별도 Flutter 저장소) | 현재 `/v1/book` 단일 책 API와 1:1 `user_id` PK |

실제 `/book` 또는 `/book/[bookId]` Next.js 라우트는 확인되지 않았다.

## 8. 신규 개발 범위 요약

- Next.js: `/book` 서버/클라이언트 화면, 상태별 책 카드, 반응형 레이아웃 기준, 카드 스켈레톤·빈/오류 상태, `/book/[bookId]` 진입을 구현한다.
- Next.js: 기존 `/mypage`, `/continue`, `/write/[contentId]`, 노트북·표지·미리보기를 `bookId` 범위로 단계적으로 이전하고 기존 URL의 호환/리다이렉트 정책을 정한다.
- 데이터: 책·참여 관계, 책별 진행/목차/답변/표지/원고/승인 모델과 기존 단일 데이터 backfill을 설계한다.
- API: Route Handler를 다권 전용으로 확장하거나 공유 NestJS BFF/직접 전환을 선택하고, 모든 요청에서 서버 권한 검증을 적용한다.

## 9. 열린 이슈 / 가정

1. 카드용 `draft` / `writing` / `reviewing` / `completed`는 **후보**다. 현재 `writing_progress.status`, 노트북 `draft`/`reviewed`, 승인 상태와의 상태 머신을 별도로 확정해야 한다.
2. “제작 완료”의 기준이 질문 완료, 챕터 리뷰 저장, 전자책/PDF 생성, 인쇄 제작·배송 중 무엇인지 미정이다. 목록의 완료 섹션은 이 정의가 정해진 뒤 서버에서 판정한다.
3. 새 책은 새 인트로로 생성하는지, 기존 목차를 복제하는지, 기존 원고 가져오기를 포함하는지 결정이 필요하다. 현 목차 생성/선택 로직이 기존 사용자 작성 상태를 초기화할 수 있으므로 그대로 재사용하지 않는다.
4. 하단에 표시할 프로필/기타 정보의 확정 필드와 카피가 없다. 전화번호·주소는 기본 비노출이며, 가족 연결 정보도 공유 동의/권한 모델 전에는 표시하지 않는다.
5. 가족 공유 참여자의 목록 노출, 읽기·편집 권한, 초대·철회, 감사 로그와 웹 우선 충돌 처리 정책이 미정이다.
6. Next.js Drizzle과 Flutter/NestJS TypeORM은 사용자 ID·콘텐츠 ID·데이터베이스가 분리돼 있다. 통합 전 book ID 매핑, 데이터 이전 순서, 쓰기 중단/롤백, 동시 편집 충돌 기준을 합의해야 한다.
7. `/mypage`를 유지할지 `/book`으로 완전히 전환할지, 그리고 `/continue`의 기존 목적지를 언제 `/book` 또는 `/book/[bookId]/write`로 바꿀지는 호환 기간과 함께 결정해야 한다.
