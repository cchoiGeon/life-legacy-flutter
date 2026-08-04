# 6-1-1. book/[id]/ebook — 자서전 미리보기·전자책 (Flutter 앱 + NestJS)

## 1. 개요

`book/[bookId]/ebook`은 리뷰가 끝난 원고를 전자책(PDF)으로 확인하고 내려받는 화면이다. 앱에서는 PDF를 **세로 스크롤**로 읽고, 무료 플랜도 다운로드할 수 있게 한다.

- 현재 Flutter의 `/book/preview`는 `GET /v1/book/pages` 응답을 쪽 단위로 넘기는 화면이며, PDF 뷰어·파일 다운로드는 없다.
- NestJS의 `GET /v1/book/pages`는 `done` 장의 `polished_text`를 3문단 단위 쪽으로 조립한다. PDF/DOCX 생성·파일 제공 API는 아직 없다.
- 최소 접근 기준은 **챕터 1의 리뷰 저장 완료**다. 현재 NestJS 장 상태는 `locked | writing | done`만 가지며 `reviewed`가 없다. 반면 웹은 `chapter_notebook.status = reviewed`를 사용하므로, 공유 전환 시 같은 상태로 간주하지 않는다.
- 사용자 스펙의 “챕터1 기준 다운로드”에 따라, 초기/무료 미리보기는 **reviewed된 장 전부**를 포함한다. 챕터1이 자연히 최소 조건이 된다. 전체 ebook 조건은 확정하지 않고 §9에 남긴다.
- 앱의 표지 제작·편집은 이 화면에서 제공하지 않는다. 향후 TODO다. 웹의 기존 표지 스튜디오와 기능 범위를 혼동하지 않는다.

관련 화면: [5. 챕터 리뷰](./05-book-id-review.md), [6-1. 책 상세](./06-1-book-id.md), [01. 랜딩 가격·기능 매트릭스](./01-landing-web.md).

## 2. 유저 플로우

1. 사용자는 책 상세에서 전자책을 선택한다.
2. Flutter는 `bookId`의 소유/참여 권한과 ebook 자격을 요청한다. 서버는 entitlement뿐 아니라 챕터1의 리뷰 저장 완료를 검증한다.
3. 챕터1이 미완료 또는 리뷰 미저장이면, 앱은 잠금 사유와 리뷰 화면으로 돌아갈 CTA를 보여 준다. URL/버튼 노출 여부는 권한 근거가 아니다.
4. 자격이 있으면 서버가 기본 표지와 챕터1 원고를 포함한 부분 PDF를 생성하거나 기존 생성본을 반환한다. 앱은 PDF viewer에서 세로 스크롤로 연다.
5. 사용자는 `다운로드`로 같은 PDF를 기기에 저장하고, 플랫폼 공유 기능을 이용할 수 있다. 다운로드·재발급 요청도 서버가 매번 자격을 확인한다.
6. 전체 진행률이 80% 미만이면 `AI 제목 추천`은 비활성화하고 조건을 설명한다. 80% 이상이면 후보를 요청·선택하고 전자책 제목에 적용한다. 서버도 진행률 조건을 확인한다.
7. 앱에서 표지를 만들거나 편집하려는 요구는 “준비 중” 안내만 표시한다. ebook 열람·다운로드와 별개 TODO로 유지한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 챕터1 리뷰 자격 | 챕터1의 완료된 리뷰 저장 상태를 ebook 최소 접근 조건으로 서버에서 판정 | 신규 |
| 부분 ebook | reviewed된 장 전부를 기본 표지와 함께 PDF로 생성·열람. 챕터1이 자연히 최소 조건 | 신규 제안 |
| PDF 세로 읽기 | 앱 내 PDF viewer의 연속 세로 스크롤, 로딩/실패/재시도 | 신규 |
| 무료 PDF 다운로드 | 무료 플랜도 자격 충족 시 다운로드 가능. API에서 entitlement·reviewed 검증 | 신규 |
| 기기 파일 저장·공유 | 다운로드 후 열기/공유, 저장 위치·보관 정책을 플랫폼별로 처리 | 신규 |
| AI 제목 추천 | 전체 진행률 `>= 0.8`일 때만 활성화·요청 허용 | 신규 정책 |
| 기본 표지 | 챕터1 부분 ebook에 서비스 기본 표지와 제목/저자 기본값 적용 | 신규 |
| 앱 표지 제작/편집 | 이 화면에서 제공하지 않음 | TODO |
| 기존 쪽 미리보기 | `GET /v1/book/pages`의 done 장·쪽 단위 표시 | 기존, PDF/자격 모델로 확장 필요 |

`progress >= 0.8`은 클라이언트의 버튼 상태만으로 지키지 않는다. 제목 추천 API와 제목 적용/ebook 생성 API 모두 서버가 책 범위 진행률을 다시 계산해 검증한다.

## 4. 화면 구성

### 자격·상태 영역

- 헤더에는 책 제목, “전자책 미리보기”, 현재 제공 범위(예: `챕터 1 미리보기`)를 표시한다.
- 진입 전/생성 중/다운로드 중/오프라인 파일 있음/오류 상태를 구분한다.
- 챕터1 리뷰가 완료되지 않은 경우 PDF 자체를 내려주지 않고, “챕터 1 리뷰를 저장하면 전자책을 확인할 수 있어요”와 리뷰 CTA를 제공한다.
- 초기 범위가 부분 ebook임을 명확히 보인다. 전체 ebook처럼 보이는 제목·페이지 수 표시는 피한다.

### PDF reader·다운로드

- reader는 확대/축소와 세로 스크롤을 지원하고, 큰 글자·터치 영역·현재 페이지 표시를 제공한다.
- `다운로드`와 `공유`는 파일 준비 상태에서만 활성화한다. 다운로드 실패, 저장 공간 부족, 네트워크 단절은 사용자에게 재시도 가능한 한국어 문구로 알린다.
- 현재 `open_filex`, `path_provider`, `dio`는 의존성에 있으나 PDF 렌더링 패키지는 없다. `pdfx`, `syncfusion_flutter_pdfviewer` 등은 구현 시 라이선스·플랫폼 지원을 비교해 신규 의존성으로 결정한다.

### 제목·표지

- AI 제목 추천 버튼은 80% 미만에서 disabled 처리하고 “전체 작성 진행률 80% 이상에서 사용할 수 있어요”를 표시한다.
- 앱은 추천 제목을 선택·저장할 수 있으나, 표지 템플릿·이미지 업로드·AI 표지 생성·텍스트 배치 편집은 제공하지 않는다.
- 기본 표지는 서버가 재현 가능하게 생성한다. 책 제목/저자 미입력 시 사용할 기본 문자열과 디자인은 별도 디자인 결정이 필요하다.

## 5. API 엔드포인트 (NestJS)

### 현재 API

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/book` | 단일 사용자 책 요약 | 기존 |
| `GET` | `/v1/book/pages` | `done` 장의 윤문 문단을 쪽 단위로 반환 | 기존 |
| `GET` | `/v1/chapters` | 장별 `locked/writing/done` 진행 상태 | 기존 |

현재 API에는 `reviewed` 상태, PDF 생성/다운로드, ebook entitlement, 제목 추천, 파일 저장이 없다.

### 신규/전환 제안

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/books/:bookId/ebook/eligibility` | 책 권한, 챕터1 reviewed 판정, 제공 범위(`chapter_preview` 등), 다운로드 가능 여부 반환 | 신규 제안 |
| `POST` | `/v1/books/:bookId/ebook/generate` | 기본 표지+허용 원고로 PDF 생성 작업을 시작하거나 재사용 가능한 결과 반환 | 신규 제안 |
| `GET` | `/v1/books/:bookId/ebook/file` | 서버 검증 후 PDF 스트림 또는 짧은 수명의 다운로드 URL 반환 | 신규 제안 |
| `POST` | `/v1/books/:bookId/ebook/titles/suggest` | 진행률 80% 이상인지 서버에서 검증 후 제목 후보 반환 | 신규 제안 |
| `PATCH` | `/v1/books/:bookId/ebook/metadata` | 허용된 제목을 저장. 표지 편집 요청은 앱 범위 밖 | 신규 제안 |

`generate`와 `file` 모두 인증 사용자, `bookId` 소유/참여 관계, 챕터1 review 상태, 무료 포함 ebook entitlement를 검사한다. 생성 결과의 원고 범위·원고 버전·표지 종류를 응답에 포함해 앱이 “부분 ebook”을 정확히 표시하도록 한다.

## 6. 데이터 모델

| 모델 | 현재 상태 | ebook 전환 방향 |
|---|---|---|
| `book` | `user_id`가 PK인 사용자당 한 권 | 독립 `book.id`와 소유/참여 관계로 전환 |
| `user_chapter` | `locked/writing/done` 진행 상태 | `book_id`와 review 완료 원고 연결 필요 |
| `answer` / `answer_followup` | 원문·윤문 결과 | ebook 입력 원천, 포함 원고 버전 추적 필요 |
| 챕터 리뷰 원고 | NestJS에 없음 | `chapter_review` 또는 `chapter_notebook` 성격 모델에 body·`reviewedAt`·버전 저장 |
| `book_page` | 현재 요청마다 계산, 페이지 엔티티도 존재 | PDF 조판 캐시와 혼동하지 않고 preview scope/원고 버전 연결 검토 |
| ebook export | 없음 | `ebook_export`에 scope, format, source version, 기본 표지 여부, 생성 상태, 파일 참조/만료 저장 후보 |
| entitlement/plan | 없음 | 무료/프로모션/구매별 ebook 다운로드 권한을 서버에서 판정 |
| title metadata | `book.title`만 존재 | 추천 제목 적용 이력 및 80% 충족 시점 기록 여부 검토 |

PDF 파일은 자서전 원고라는 민감 정보다. 영구 공개 URL 대신 인증된 스트림 또는 짧은 만료 URL, 접근 로그, 파일 삭제·재생성 규칙을 둔다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 기존 미리보기 | `lib/feature/book/preview_view.dart`, `preview_controller.dart` | 쪽 단위 이전/다음 UI, 현재는 PDF가 아닌 `BookPage` 텍스트 표시 |
| Flutter 책 진입 | `lib/feature/book/book_view.dart`, `book_controller.dart` | 완료 장을 `/book/preview`로 보내며 단일 책 모델 |
| Flutter 라우팅 | `lib/core/route/app_routes.dart`, `app_pages.dart` | `/book/preview` 정적 GetX route, `bookId` 미도입 |
| Flutter 파일 관련 의존성 | `pubspec.yaml` | `dio`, `path_provider`, `open_filex` 존재; PDF viewer 패키지는 없음 |
| Flutter 네이티브 설정 | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | 음성 권한만 확인됨; PDF 다운로드·공유·파일 접근 전용 설정은 미확인 |
| NestJS 책 API | `server/src/book/book.controller.ts`, `services/book.service.ts` | `/v1/book`, `/v1/book/pages`; done 장을 3문단 단위 페이지로 조립 |
| NestJS 책 모델 | `server/src/book/entities/book.entity.ts`, `book-page.entity.ts` | 사용자당 한 권, 사진 0, 페이지 모델 |
| NestJS 기능 범위 | `docs/server-feature-definition.md`, `docs/api-spec.md` | PDF/DOCX/MP3 파일 제공 API가 현재 없음을 명시 |

## 8. 신규 개발 범위 요약

1. **Flutter**: `bookId` 기반 ebook route, 자격/로딩/오류/빈 상태, PDF viewer 세로 스크롤, 안전한 다운로드·열기·공유 UI를 만든다.
2. **NestJS**: 다권 권한, 챕터 review 저장 모델, ebook eligibility, 기본 표지·부분 PDF 생성·파일 제공, 원고 버전·파일 수명 관리를 구현한다.
3. **무료 권한**: 무료 사용자의 다운로드를 UI 잠금으로 제한하지 않고, 모든 export 요청에서 챕터1 reviewed 및 entitlement를 서버 검증한다.
4. **제목 추천**: 80% 진행률을 앱과 서버 모두에서 확인하고, 현재 Next.js 추천 API의 후보 4개 UX를 공통 계약으로 이관한다.
5. **표지**: 앱 표지 제작은 TODO로 남긴다. 챕터1 다운로드에는 새 기본 표지 생성 경로가 필요하다.

## 9. 열린 이슈 / 가정

1. **[결정 완료] ebook 범위**: reviewed된 장 전부가 ebook에 포함된다. 챕터1이 자연히 최소 조건이 된다. (결정기록 08-03)
2. NestJS의 `done`과 웹 `chapter_notebook.status = reviewed`는 서로 다른 상태다. 리뷰 완료의 단일 도메인 정의, 저장 시점, 기존 데이터 이전 기준이 필요하다.
3. 무료 다운로드가 상시 무료 티어인지, 기존 “사전신청 무료 T2” 프로모션과 어떻게 겹치는지 entitlement 우선순위를 확정해야 한다.
4. Flutter에는 PDF viewer가 없다. 후보 패키지의 라이선스, Android/iOS 지원, 접근성·대용량 성능을 검토해 결정해야 한다.
5. Android/iOS의 파일 캐싱 위치, 다운로드 권한, OS 공유 시 원고 노출, 오프라인 보관 기간·삭제, 잠금화면/백업을 통한 민감 원고 접근 보호 정책이 필요하다.
6. PDF 파일을 서버 스트림, 서명 URL, 앱 로컬 암호화 저장 중 어느 방식으로 제공할지와 만료·재발급·접근 로그 정책을 정해야 한다.
7. 기본 표지의 디자인, 저자/제목 기본값, 제목 변경 시 기존 export를 재생성하는 규칙은 미정이다.
8. 80% 진행률의 분모를 전체 질문, reviewed 챕터, 또는 다른 완료 기준 중 무엇으로 계산할지와 건너뛴 질문 포함 규칙을 확정해야 한다.
9. 앱에서 제목만 저장할 때 웹 표지 스튜디오의 제목과 충돌하는 경우의 우선순위·동기화 규칙이 필요하다. 앱 표지 제작/편집은 이 화면의 TODO로 유지한다.
