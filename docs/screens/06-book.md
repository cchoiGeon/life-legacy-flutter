# 6. book — 내 책 목록·허브 (Flutter 앱 + NestJS)

## 1. 개요

`/book`은 로그인한 사용자가 제작 중이거나 제작을 마친 자서전을 찾아보는 **개인 책 목록/허브**다. **사용자 1 : N 책** (`book.id` + `owner_user_id`)이 구현 계약이다 (`erd/new-erd.dbml`, api-spec §0.6·§6).

- Flutter `/book`은 아직 단일 권 장 목록 UI지만, API는 `GET /books`·`GET /books/{book_id}/…`만 쓴다. 레거시 `/book`·`/chapters`·`/home`은 **제거**한다.
- 책 카드 목록 → 책 상세(6-1) → 작성/리뷰/미리보기로 `bookId`를 GetX arguments로 전달한다.

관련 화면: [3-1 intro2](./03-1-intro-toc.md), [4 작성](./04-book-id-write.md), [5 리뷰](./05-book-id-review.md).

## 2. 유저 플로우

1. 사용자는 앱 탭 또는 목차 확정 완료 화면에서 정적 GetX 라우트 `AppRoutes.book`으로 진입한다.
2. 앱은 인증 토큰만 보내고, NestJS가 인증 사용자 기준으로 접근 가능한 책 목록을 필터링해 반환한다.
3. 상단은 제작 중/제작 완료 섹션으로 나누어 책 형태 카드들을 **가로로 넘겨** 본다.
4. 카드를 누르면 `Get.toNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId})`처럼 실제 앱 컨벤션의 route argument로 6-1 책 상세로 이동한다. Flutter에 웹식 `[id]` 경로를 만들지 않는다.
5. 하단에는 최소한의 내 정보와 책/진행 요약을 나열한다. 전화번호·주소는 기본으로 노출하지 않는다.
6. 상세 화면에서 이어쓰기, 챕터 리뷰, 미리보기/완성 후처리로 이동한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 단일 장 목록 | 현재 `/book`에서 `chapters()`와 `book()`을 조회하고 장 카드/이어쓰기 CTA를 표시 | 기존 |
| 개인 책 목록 | 소유하거나 참여 권한이 있는 책을 상태별로 나열 | 신규 |
| 가로 슬라이딩 책 카드 | 모바일에서 카드 한 권씩 또는 일부 다음 카드가 보이도록 수평 스크롤 | 신규 |
| 제작 중/완료 분리 | 서버가 반환한 책 상태를 기준으로 섹션화 | 신규 |
| 책 상세 진입 | `bookId`를 GetX `arguments`로 전달하여 6-1 허브로 이동 | 신규 |
| 이어쓰기 | 기존 단일 `/write` 대신 선택한 `bookId`를 작성 화면에 전달 | 변경 필요 |
| 하단 사용자/진행 요약 | 표시 이름, 작성 중인 책 수, 완료 책 수, 현재 책의 장·질문 진행률 등 후보를 표시 | 신규 |
| 민감정보 최소 노출 | 전화번호·배송지·상세 주소는 기본 카드/하단 정보에서 제외 | 신규 정책 |

제작 상태는 저장하지 않고 파생한다: 목차 확정 전 = `draft`, 모든 장 reviewed = `completed`, 그 외 = `writing`.

## 4. 화면 구성

### 상단 책 카드 영역

- 제목은 “내 책” 또는 제품 용어로 확정할 명칭을 사용한다.
- `제작 중인 자서전`, `제작 완료된 자서전`을 분리한다. 빈 섹션은 숨기거나 “아직 없습니다” 상태와 새 책 시작 CTA를 제공한다.
- 카드에는 표지 썸네일(표지 미설정 시 기본 표지), 제목, 저자 표시명, 장/질문 진행률, 후보 상태 라벨을 둔다.
- Flutter는 `ListView.separated(scrollDirection: Axis.horizontal)` 또는 동등한 접근 가능한 수평 목록으로 구현한다. 카드 폭은 큰 글자·동적 텍스트를 고려해 고정 최소 폭과 충분한 터치 영역을 둔다.

### 카드 상세 진입과 빈 상태

- 현재 `BookController.openChapter`의 장별 분기와 달리, 카드는 항상 책 상세로 간다. 잠긴 장 여부는 상세 안에서 표시한다.
- 목록이 비었으면 인트로 진입 CTA를 제공한다. 이미 책을 하나 이상 가진 사용자의 “새 자서전 만들기”가 기존 내용을 초기화하지 않도록 별도 생성 흐름을 둔다.

### 하단 정보 영역

사용자 필드가 확정되지 않았으므로 아래는 실제 구현에서 얻을 수 있는 **후보**다.

| 후보 | 실제 근거 | 기본 노출 제안 |
|---|---|---|
| 표시 이름 | Flutter `User.name`, NestJS `app_user.name` | 노출 가능 |
| 제작 중/완료 책 수 | 새 책 목록 집계 필요 | 노출 가능 |
| 선택 책의 장 수·답변 수·진행률 | 기존 `Chapter`의 `questionCount`/`answeredCount`, NestJS home 집계 | 노출 가능 |
| 마지막 수정 시각 | 신규 책/진행 데이터 필요 | 후보 |
| 자녀 연결 여부 | `User.childLinked`, `app_user.child_linked` | 공유 정책 확정 후 후보 |
| 전화번호 | `User.phone`, `app_user.phone` | 기본 비노출 |
| 배송지 | `shipping_address` | 기본 비노출 |

## 5. API 엔드포인트 (NestJS)

### 현재 API

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/book` | 인증 사용자 1명의 단일 책 요약 | 기존 |
| `GET` | `/v1/book/pages` | 완료 장 원고를 페이지로 조립 | 기존 |
| `GET` | `/v1/chapters` | 사용자 전체의 단일 책 장 목록 | 기존 |
| `GET` | `/v1/home` | 현재 질문, 전체 진행률, 완료 장 수 | 기존 |
| `GET` | `/v1/users/me` | 이름·전화번호·자녀 연결 여부 | 기존 |

### 다권 전환 제안

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/books` | 인증 사용자에게 허용된 책 목록과 카드용 요약 반환 | 신규 제안 |
| `POST` | `/v1/books` | 새 책/에디션 초안 생성. 기존 사용자 콘텐츠를 초기화하지 않음 | 신규 제안 |
| `GET` | `/v1/books/:bookId` | 6-1 상세 허브용 책·진행·권한 요약 | 신규 제안 |
| `GET` | `/v1/books/:bookId/chapters` | 선택한 책 범위 장 목록 | 신규 전환 |
| `GET` | `/v1/books/:bookId/pages` | 선택한 책의 미리보기 페이지 | 신규 전환 |

모든 `/v1/books/:bookId/*` 서비스는 `AccessTokenGuard`가 넣은 사용자 ID를 기준으로 책 소유자 또는 미래의 가족 참여자인지 확인해야 한다. 클라이언트가 전달한 `bookId`와 current user ID를 신뢰해 필터링하면 안 된다. 현재 `ChaptersService.getOwnedQuestion`처럼 다른 사용자의 리소스를 찾지 못하게 처리하는 소유권 패턴은 참고할 수 있으나, 참여 권한을 포함하는 전용 조회 정책이 필요하다.

## 6. 데이터 모델

| 모델 | 현재 상태 | 다권 전환 방향 |
|---|---|---|
| `book` | `user_id`가 PK인 1:1, 제목·저자·페이지/사진 수·완료 여부 보유 | 독립 `book.id` PK와 `owner_user_id`로 전환. 사용자 1:N 책 관계 구성 |
| `app_user` | 이름, 전화번호, `child_linked`, 인트로 완료 시각 보유 | 기본 사용자 정보 유지. 책 상태를 사용자 단위 필드에 두지 않음 |
| `user_chapter` | `user_id`에 직접 연결, `(user, sort_order)` 유니크 | `book_id`에 연결하고 `(book, sort_order)` 유니크로 이전 |
| `user_question` | `user_chapter`에 연결 | 장의 `book_id` 귀속을 통해 범위 보장 |
| `answer` / `answer_draft` / `answer_followup` | 질문별 답변·윤문·임시 상태 | 질문 연결을 유지하되 모두 첫 책으로 backfill |
| `book_page` | 현재 요청 시 계산만 하며 테이블은 캐시 자리 | `book_id` 범위로 계산/캐시 |
| 책 참여 관계 | 없음 | 미래 가족 공유를 위한 `book_participant` 또는 동등 관계 후보. 역할/읽기·편집 권한은 별도 결정 |

기존 데이터는 사용자당 한 권이므로 마이그레이션에서 각 기존 사용자에 첫 `book`(또는 `book_edition`)을 만든 뒤, 기존 책 요약·목차·질문·답변·진행 상태를 그 책에 backfill해야 한다. 이 작업은 ID 변경과 유니크 제약 전환을 포함하므로 트랜잭션, 검증 쿼리, 롤백 계획이 필요하다. NestJS는 운영 migration 체계가 별도로 확인되지 않았으므로 `DB_SYNCHRONIZE`에 의존해 자동 반영하지 않는다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 현재 허브 | `lib/feature/book/book_view.dart` | 단일 책의 장 목록과 하단 CTA |
| Flutter 허브 상태 | `lib/feature/book/book_controller.dart` | `chapters()`/`book()` 병렬 아닌 순차 조회, 장 상태별 이동 |
| Flutter 주입 | `lib/feature/book/binding.dart` | `BookController` GetX 등록 |
| Flutter 미리보기/완성 | `lib/feature/book/preview_view.dart`, `preview_controller.dart`, `complete_view.dart` | 책 페이지 조회·완료 표지·후처리 스텁 |
| Flutter 탭/라우팅 | `lib/feature/shared/tab_scaffold.dart`, `lib/core/route/app_routes.dart`, `app_pages.dart` | `/book` 정적 탭 라우트, route argument 사용 사례 |
| Flutter 모델 | `lib/data/models/book.dart`, `chapter.dart`, `user.dart` | 단일 `Book`, 장 진행 수치, 이름·전화번호·자녀 연결 후보 |
| Flutter API 경계 | `lib/core/network/api_client.dart`, `real_api_client.dart`, `mock_api_client.dart` | 현 `/book`, `/book/pages` 계약과 목업 구현 |
| Flutter 홈 | `lib/feature/home/home_view.dart`, `home_controller.dart` | 진행 카드와 장 목록을 홈에서도 노출 |
| NestJS 책 | `server/src/book/book.controller.ts`, `services/book.service.ts`, `entities/book.entity.ts` | `/book`·`/book/pages`, `user_id` PK 1:1 모델 |
| NestJS 장/질문 | `server/src/chapters/entities/user-chapter.entity.ts`, `user-question.entity.ts`, `services/chapters.service.ts` | 사용자 직접 귀속·장 순차 잠금 |
| NestJS 홈/사용자 | `server/src/home/services/home.service.ts`, `server/src/users/entities/app-user.entity.ts`, `services/users.service.ts` | 진행률 집계와 사용자 후보 필드 |
| NestJS 인증/소유권 | `server/src/book/book.controller.ts`, `server/src/chapters/services/chapters.service.ts` | Access token guard와 소유 질문 조회 패턴 |

## 8. 신규 개발 범위 요약

- Flutter: 단일 장 목록 화면을 책 카드 목록/수평 스크롤/상태별 빈 화면/하단 최소 정보 구조로 바꾸고, 정적 `/book`에서 `bookId` route argument를 상세·작성·리뷰에 전달한다.
- NestJS: 1:N `book` 관계와 장·질문·답변의 `book_id` 범위, 목록/상세 API, 서버 측 소유·참여 권한 필터를 구현한다.
- 데이터 이전: 기존 사용자별 책·목차·답변·진행 데이터를 첫 책/에디션으로 backfill하고 유니크 인덱스와 기존 단일 API 호환·전환 계획을 검증한다.
- 제품 정책: 완료·상태 모델과 가족 참여 권한을 확정한 뒤 카드 분류와 CTA를 연결한다.

## 9. 열린 이슈 / 가정

1. **[결정 완료] 제작 상태 파생 정책**: 상태를 저장하지 않고 `user_chapter`에서 파생한다. 목차 확정 전 = `draft`, 모든 장 reviewed = `completed`, 그 외 = `writing`. 취소/보관 상태는 별도 결정이 필요하다.
2. “제작 완료”가 질문 완료, 챕터 리뷰 저장, 전자책 생성, 인쇄 완료 중 무엇을 뜻하는지 확정되지 않았다. 하나의 `completed`로 이 단계를 혼동하지 않는다.
3. 새 책 생성 시 인트로를 다시 수행하는지, 기존 목차를 복제하는지, 빈 초안부터 시작하는지와 첫 책/에디션 명명 규칙이 필요하다.
4. 하단 정보의 최종 노출 항목·표시 문구는 미정이다. 전화번호·주소는 기본 비노출로 가정하며, 자녀 연결 상태도 공유 동의·권한 정책 전에는 노출하지 않는다.
5. 가족 공유 참여자는 향후 모델이다. 목록/상세/작성/리뷰별 읽기·편집 권한과 초대·철회·감사 로그 정책을 정해야 한다.
6. Flutter/NestJS와 Next.js는 별도 DB·사용자 ID 체계를 사용한다. 웹 편집과 앱 책 목록을 실제 공유하기 전 book ID 매핑, 마이그레이션 소유자, 웹 우선 충돌 정책을 확정해야 한다.
