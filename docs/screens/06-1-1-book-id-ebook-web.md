# 6-1-1. book/[id]/ebook — 자서전 미리보기·전자책 (Next.js 웹)

## 1. 개요

`/book/[bookId]/ebook`은 한 에디션의 원고를 책 형태로 미리보고 PDF/DOCX를 내려받는 웹 화면이다. 현재 구현된 `/mypage/preview`와 `BookPreview`의 UX·조판·편집 기능을 **유지**하면서, 다권과 entitlement를 지원하는 방향으로 전환한다.

- 현재 공개 구현은 `/mypage/preview`다. 표지, 스프레드 미리보기, Word 형태 편집·이력, PDF/DOCX/표지 PDF 내보내기, 책 제목 AI 추천을 제공한다.
- 현 미리보기는 사용자당 단일 원고를 가정한다. 원고 우선순위는 reviewed notebook → 활성 `manuscript_edit` → 답변 조립이고, 모든 reviewed 장을 포함할 수 있다.
- 접근 최소 기준은 **챕터1 리뷰 저장 완료**다. 현재 웹의 사실상 기준은 `chapter_notebook.status = reviewed`이며, `GET/PATCH /api/notebook`도 이를 `isReviewed`로 반환한다.
- 사용자 스펙의 챕터1 기준 다운로드를 반영해, 무료/초기 진입은 **챕터1만 포함한 부분 ebook + 기본 표지**를 제안한다. 이 최소 자격이 전체 ebook 다운로드까지 여는지 여부는 단정하지 않는다.
- 무료 플랜도 전자책 다운로드를 제공한다. 기존 export는 entitlement를 확인하지 않으므로, 다권 전환에서는 서버 API가 자격을 검증해야 한다.
- 웹 표지 스튜디오(`/mypage/cover`)는 기존 기능을 유지한다. 이 문서는 앱 표지 제작 TODO와 혼동하지 않으며, 웹 UX를 불필요하게 재설계하지 않는다.

관련 화면: [5. 챕터 리뷰 — 웹](./05-book-id-review-web.md), [6-1. 책 상세 — 웹](./06-1-book-id-web.md), [01. 랜딩 가격·기능 매트릭스](./01-landing-web.md).

## 2. 유저 플로우

1. 사용자는 `/book/[bookId]` 상세 허브에서 `전자책 미리보기`를 선택한다.
2. 서버는 세션 사용자와 `bookId` 소유/참여 권한, entitlement, 챕터1의 `reviewed` 상태를 검증하고 ebook scope를 반환한다.
3. 챕터1이 아직 reviewed가 아니면 잠금 사유와 해당 챕터 리뷰로 이동하는 CTA를 보여 준다. 클라이언트 라우트 가드만으로 원고/export를 보호하지 않는다.
4. 자격이 있으면 기존 preview와 같은 표지·스프레드·Word 편집·편집 이력 UX를 보여 준다. 초기/무료 scope는 챕터1 원고와 기본 표지로 제한하는 것을 제안한다.
5. 사용자는 PDF 또는 DOCX를 내려받는다. 모든 export 요청은 서버에서 scope·챕터1 reviewed·무료 포함 entitlement를 재확인한다.
6. 전체 진행률이 80% 미만이면 AI 제목 추천은 비활성화한다. 80% 이상일 때만 기존 후보 4개 선택 UX를 사용하며, 제목 추천 Route Handler/공유 NestJS도 진행률을 재검증한다.
7. 사용자가 웹 표지 스튜디오로 이동하면 기존 템플릿·업로드·AI 배경·텍스트 편집 흐름을 그대로 쓴다. 부분 ebook의 기본 표지를 사용자 표지로 바꾸는 정확한 조건은 별도 정책으로 정한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 기존 책 미리보기 | `BookSpread`로 조판 결과·표지를 표시 | 기존 유지 |
| Word 편집·이력 | 블록 원고 편집, 저장본 활성화·복원·삭제 | 기존 유지 |
| 챕터1 reviewed 자격 | ebook 최소 진입/다운로드 조건을 서버가 판정 | 신규 정책 |
| 부분 ebook scope | 챕터1만 포함한 원고와 기본 표지로 초기/무료 미리보기·다운로드 제공 제안 | 신규 제안 |
| PDF 다운로드 | 미리보기 페이지를 PDF로 생성 | 기존, scope·entitlement 전환 필요 |
| DOCX 다운로드 | 서버 원고를 DOCX로 생성 | 기존, scope·entitlement 전환 필요 |
| 표지 PDF | 기존 사용자 표지를 전개 PDF로 출력 | 기존, 부분 ebook 기본 표지 정책과 분리 필요 |
| 웹 표지 스튜디오 | 템플릿, 업로드, AI 배경, 제목·저자 편집 | 기존 유지 |
| AI 제목 추천 | 후보 4개를 받고 표지 제목에 적용 | 기존, 80% 조건 추가 필요 |
| 무료 ebook 다운로드 | 무료도 다운로드 가능하되 entitlement/review를 API에서 검증 | 신규 정책 |

현재 `TitleSuggestPanel`은 preview와 notebook에서 `/api/titles/suggest`를 호출하며, API는 원고 길이만 검사한다. **진행률 80% 제한은 현재 구현되어 있지 않다.** UI의 `disabled`와 서버의 재검증을 함께 추가해야 한다.

## 4. 화면 구성

### 기존 preview를 유지하는 영역

- 상단 액션: 표지 만들기, Word 편집, 편집 기록, 원본 보기, Word/PDF 다운로드, 인쇄용 PDF, 표지 PDF를 현재 배치와 역할대로 유지한다.
- 표지와 스프레드: `CoverCanvas`, `BookSpread` 및 기존 조판(`typeset`) 결과를 재사용한다.
- 원고: 현재 `resolveManuscriptChapters`의 source 우선순위와 편집 이력 UX를 유지하되, 새 route에서는 서버가 반환한 `bookId`·ebook scope로 원고를 제한한다.
- 표지 만들기는 기존 `/mypage/cover`를 재사용하거나 다권 전환 후 동등한 책 범위 route로 매핑한다. 미리보기 화면에서 새 표지 제작 UX를 설계하지 않는다.

### 자격·부분 ebook 표시

- 헤더 또는 다운로드 영역에 `챕터 1 미리보기`처럼 실제 포함 범위를 표시한다.
- 챕터1 reviewed 전에는 preview 데이터 및 export 버튼을 제공하지 않고, 리뷰 완료 안내·CTA를 표시한다.
- 기본 표지로 발행되는 부분 ebook은 “내 표지”와 구별한다. 기존 `book_cover`가 있더라도 부분 ebook에서 이를 바로 쓸지 정책 확정 전에는 기본 표지로 처리한다.

### 제목 추천

- 진행률이 80% 미만이면 `AI 제목 추천`을 disabled하고 활성화 조건을 설명한다.
- 80% 이상이면 현재 dialog의 후보 4개, 재추천, 적용 동작을 그대로 사용한다.
- 제목 적용은 책 범위 metadata를 저장하고, 적용 뒤 PDF 조판/기존 export를 재생성하거나 버전을 무효화해야 한다.

## 5. API 엔드포인트 (Route Handler / 공유 NestJS 전환 방향)

### 현재 Next.js Route Handler

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/api/notebook/manuscript` | reviewed notebook 기반 미리보기 원고 조회 | 기존 |
| `GET` / `POST` / `DELETE` | `/api/manuscript-edit` | 활성 편집본 조회·저장·원본 복귀 | 기존 |
| `GET` / `DELETE` | `/api/manuscript-edit/[id]` | 편집본 단건 조회·삭제 | 기존 |
| `GET` | `/api/manuscript-edit/history` | 편집 이력 목록 | 기존 |
| `POST` | `/api/manuscript-edit/[id]/activate` | 편집 이력 활성화 | 기존 |
| `GET` / `PUT` | `/api/cover` | 사용자당 단일 표지 조회·저장 | 기존 |
| `POST` | `/api/export-pdf` | 클라이언트 조판 `pages`를 PDF로 출력 | 기존 |
| `GET` | `/api/export-pdf` | 서버 원고를 PDF로 출력 | 기존 |
| `GET` | `/api/export-docx` | 서버 원고 DOCX 다운로드 | 기존 |
| `GET` | `/api/export-cover-pdf` | 저장된 표지 전개 PDF 다운로드 | 기존 |
| `POST` | `/api/titles/suggest` | 책/장 제목 후보 4개 반환 | 기존 |

현재 export 경로는 세션 사용자만 확인하고 전체 `resolveManuscriptChapters(userId)`를 사용한다. `bookId`, entitlement, 챕터1 reviewed, 부분 scope를 검증하지 않으며, `export-cover-pdf`는 저장 표지가 없으면 실패한다. 따라서 챕터1 부분 PDF와 기본 표지를 만들려면 별도 요청 입력만 추가하는 수준을 넘어 새 원고/표지 해석 경로가 필요할 수 있다.

### 다권 Route Handler 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/books/[bookId]/ebook` | ebook 화면용 scope, 원고/조판 입력, title·cover metadata, entitlement 반환 |
| `GET` | `/api/books/[bookId]/ebook/eligibility` | 책 권한, 챕터1 reviewed, 제공 범위, 다운로드 가능 여부 반환 |
| `POST` | `/api/books/[bookId]/ebook/export/pdf` | scope별 PDF 생성·다운로드. 서버에서 모든 자격 재검증 |
| `GET` | `/api/books/[bookId]/ebook/export/docx` | scope별 DOCX 생성·다운로드. 서버에서 모든 자격 재검증 |
| `POST` | `/api/books/[bookId]/ebook/titles/suggest` | 진행률 80% 이상일 때 후보 4개 반환 |
| `PATCH` | `/api/books/[bookId]/ebook/metadata` | 제목 등 ebook metadata 저장 및 export 캐시 무효화 |
| `GET` / `PUT` | `/api/books/[bookId]/cover` | 다권 전환 뒤 기존 웹 표지 스튜디오가 사용할 책별 표지 |

### 공유 NestJS 전환 방향

1. 다권 책 권한, 챕터 review 상태, progress, entitlement, ebook scope, PDF/DOCX 생성 계약은 NestJS의 `/v1/books/:bookId/ebook/*`로 공통화한다.
2. Next.js Route Handler는 NextAuth 세션을 검증하고 NestJS를 호출하는 BFF로 유지하거나, 서버 컴포넌트가 공통 API를 사용한다.
3. 기존 `/mypage/preview`, `/api/export-pdf`, `/api/export-docx`는 즉시 삭제하지 않는다. 단일 책 사용자에게 현 UX를 계속 제공하며, 다권 rollout 후 새 scope resolver로 점진 이전한다.

어느 경로든 URL의 `bookId`, 브라우저 progress 값, disabled 버튼은 권한 근거가 될 수 없다. 다운로드와 제목 추천 모두 서버에서 재검증한다.

## 6. 데이터 모델

| 모델 | 현재 역할/한계 | ebook 전환 방향 |
|---|---|---|
| `chapter_notebook` | 사용자·`contentId`별 원고와 `draft/reviewed` 상태 | `book_id`, chapter 식별자, 원고 버전으로 확장 |
| `writing_progress` | `userId` unique, 단일 현재 위치·notebook 상태 | `book_id`별 진행률·80% 제목 추천 판정으로 전환 |
| `manuscript_edit_history` | 사용자별 snapshot·활성 편집본 | `book_id`, source scope/원고 버전 연결 |
| `book_cover` | `userId` unique 단일 표지 | `book_id`별 표지; 부분 ebook 기본 표지와 구분 |
| `answer` / `answer_attachment` | 답변·소질문 이미지 | ebook source와 원고 version/포함 범위의 원천 |
| `approval_request` | 승인/결제 상태만, 티어·권한 없음 | ebook entitlement와 분리하거나 구매/프로모션 모델로 확장 |
| entitlement | 없음 | 무료/유료/프로모션별 다운로드 권한, 사용 범위, 만료를 서버에서 판정 |
| ebook export | 없음 | `book_id`, scope, format, source version, cover kind, 생성 상태, 파일 참조/만료·감사 로그 모델 후보 |

현재 `chapter_notebook`의 `reviewed`는 preview 원고 사용 조건과 직접 연결된다. 그러나 전체 reviewed 장을 모두 조립하는 현재 resolver는 “챕터1만 포함” scope를 표현하지 못하므로, `bookId`와 scope를 입력으로 받는 resolver가 필요하다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 기존 preview UI | `app/app/(dashboard)/mypage/preview/page.tsx` | 표지·스프레드, Word 편집/이력, PDF·DOCX·표지 PDF 다운로드, 제목 추천 사용 위치 |
| 책 미리보기 컴포넌트 | `app/components/BookPreview/BookSpread.tsx`, `PageFrame.tsx`, `PageFooter.tsx`, `PageNavigation.tsx` | 기존 책 스프레드 렌더링 |
| 원고 resolver | `app/lib/book/resolveManuscript.ts` | reviewed notebook → 활성 편집본 → 답변 조립 우선순위 |
| notebook 조립 | `app/lib/book/buildManuscriptFromNotebook.ts` | reviewed notebook·문단·이미지 placement를 Chapter 블록으로 조립 |
| PDF export | `app/app/api/export-pdf/route.ts`, `app/lib/book/generatePdf.tsx` | 세션 확인 후 전체 resolver/클라이언트 pages로 PDF 생성 |
| DOCX export | `app/app/api/export-docx/route.ts`, `app/lib/book/generateDocx.ts` | 전체 resolver 기준 DOCX 생성 |
| 표지 PDF | `app/app/api/export-cover-pdf/route.ts`, `app/lib/book/generateCoverPdf.tsx` | 저장된 사용자 표지 전개 PDF 생성 |
| 제목 추천 | `app/components/mypage/TitleSuggestPanel.tsx`, `app/app/api/titles/suggest/route.ts` | preview·notebook에서 사용, 후보 4개, 현재 progress 검사 없음 |
| 표지 스튜디오 | `app/app/(dashboard)/mypage/cover/page.tsx`, `app/components/cover/CoverCanvas.tsx`, `app/app/api/cover/route.ts` | 기존 웹 전용 표지 제작·저장 |
| review 상태 | `app/app/api/notebook/route.ts`, `app/lib/db/schema.ts` | `chapter_notebook.status = reviewed`, `isReviewed` 반환 |
| 스키마 | `app/lib/db/schema.ts` | `chapter_notebook`, `manuscript_edit_history`, `book_cover`, `writing_progress`, `approval_request` |

## 8. 신규 개발 범위 요약

1. **웹 route 전환**: `/book/[bookId]/ebook`을 추가하되, `/mypage/preview`의 미리보기·편집·다운로드 UX를 재사용하고 기존 route를 유지한다.
2. **scope resolver**: `bookId`와 `chapter_preview`/전체 scope에 맞춰 reviewed 원고, 활성 편집본, 기본 표지를 해석하는 새 공통 경로를 만든다.
3. **권한 집행**: 무료를 포함한 ebook 다운로드, 챕터1 reviewed, 소유/참여 권한을 PDF·DOCX·원고 API에서 서버 검증한다.
4. **제목 추천**: 80% 미만 비활성 UI와 Route Handler/NestJS의 진행률 재검증을 추가한다. 현재 `/api/titles/suggest`의 원고 길이 검사는 유지하되 권한 조건을 대체하지 않는다.
5. **다권·공유 전환**: `book_id`를 notebook·진행률·표지·편집본·export에 도입하고, NestJS 공통 API/BFF로 앱·웹의 자격과 원고 범위를 일치시킨다.

## 9. 열린 이슈 / 가정

1. 챕터1 리뷰 완료가 ebook 접근 전체를 허용하는지, 챕터1 부분 ebook만 허용하는지는 미정이다. 이 문서는 사용자 스펙에 따라 후자를 무료/초기 미리보기 제안으로 설명하며, 전체 ebook 전환 조건을 확정하지 않는다.
2. 웹 `chapter_notebook.reviewed`와 NestJS의 `done` 장 상태는 다르다. 공통 API 전환 전에 review 완료의 저장 주체·시점·마이그레이션 기준을 정의해야 한다.
3. 현재 PDF/DOCX export는 전체 원고·사용자 표지 전제다. 챕터1 부분 PDF와 기본 표지는 새 scope option 및 원고/표지 생성 경로가 필요할 수 있다.
4. `export-cover-pdf`는 저장된 사용자 표지가 없으면 실패한다. 부분 ebook의 기본 표지와 기존 표지 전개 다운로드의 관계를 정해야 한다.
5. 무료 ebook 다운로드와 기존 T1~T4·사전신청 무료 T2 프로모션의 entitlement 우선순위, 다운로드 횟수/만료/재발급 정책이 미정이다.
6. 전체 진행률 80%의 분모(전체 질문·reviewed 장 등), 건너뛴 질문 포함 여부, 진행률 감소/원고 수정 시 제목 추천 허용 상태를 확정해야 한다.
7. AI 제목 추천의 현재 source는 notebook 원고 또는 답변이며, 서버는 현재 길이만 검증한다. 다권 scope가 부분 ebook일 때 제목 추천에 챕터1만 사용할지 전체 작성 원고를 사용할지 정해야 한다.
8. 사용자가 웹 표지 스튜디오에서 저장한 제목/표지와 앱에서 저장한 ebook metadata가 충돌할 때의 우선순위, export 캐시 무효화, 편집 이력의 `bookId` 이전 규칙이 필요하다.
9. PDF/DOCX에는 민감 원고가 담긴다. 인증 스트림/서명 URL, 브라우저 캐시·공유, 파일 수명·삭제, 접근 로그, 가족 참여자의 다운로드 권한을 정책화해야 한다.
10. Next.js Drizzle과 Flutter/NestJS TypeORM은 현재 사용자 ID·단일 책 모델이 분리돼 있다. 동일 ebook을 공유하기 전에 `bookId` 매핑, 데이터 이전, 소유/참여 권한, 웹 편집 우선 충돌 규칙을 확정해야 한다.
