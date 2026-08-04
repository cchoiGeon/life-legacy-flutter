# 3-1. intro2 — 만들어진 목차 확인·편집 (Flutter 앱 + NestJS)

## 1. 개요

자기소개 응답으로 생성된 사용자별 대목차를 순서대로 확인하고, 편집한 뒤 **에디션 1 목차 생성 완료**를 확정하는 화면이다. 진입은 `/intro/loading`(생성 대기) → `/intro/toc`이며, 최종 저장 완료 후에는 작성 또는 책 허브로 이동한다.

- 기준: 사용자 스펙을 우선하며, 현 구현은 목록 표시·순서 변경·확정까지만 제공한다.
- 기존 확정은 `POST /v1/intro/toc/confirm` 시점이다. 이 시점에 `toc_confirmed_at`과 `intro_completed_at`이 기록된다.
- 데이터 보존: 카탈로그 원본 `chapter_template`은 유지하고, 실제 목차는 사용자별 `user_chapter` 사본으로 관리한다.

## 2. 유저 플로우

1. 자기소개 제출 후 생성 대기 화면에서 사용자별 목차·질문 사본을 생성한다.
2. 기본 화면에서 대목차를 `sort_order` 순으로 표시한다.
   - 기본 CTA: **`수정하기`** — 아직 변경하지 않은 상태에서 편집 모드 진입.
   - 기본 화면의 보조 CTA: **`저장하기`** — 현재 생성 결과를 그대로 확정. 기존의 `이대로 시작하기`를 이 의미로 대체한다.
3. 수정 모드에서 대목차 이름 수정, 개별 삭제, 드래그 앤 드롭 순서 변경, `추가하기`를 제공한다.
4. `추가하기`에서 현재 선택되지 않은 기존 대목차를 여러 개 선택하거나, `새로운 목차 만들기`로 제목을 입력한다.
5. 선택 완료 후 별도 삽입 위치 선택 화면에서 기존 목차의 앞/뒤 위치를 정한다. 제안 기본값은 여러 선택 항목을 **하나의 동일 위치에 선택 순서대로 삽입**하는 방식이다.
6. 삽입 내용을 저장하면 목차 순서 화면으로 돌아온다.
7. 최종 `저장하기`에서 목차와 에디션 1 완료 마일스톤을 원자적으로 확정하고 저장 완료 화면을 표시한다.
8. 완료 화면 CTA:
   - `자서전 작성하러 가기` → `/book/[id]/write`
   - `홈으로 가기` → `/book` (6번 나의 자서전/책 허브; 다권 전환 후 `/book/[id]`)

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 생성 목차 표시 | 생성된 `user_chapter`를 순서대로 보여 준다 | 기존 |
| 기본 확정 | 현 `이대로 시작하기`는 순서만 확정한다 | 부분 |
| 순서 변경 | 편집 모드에서 드래그 앤 드롭 후 최종 저장 | 부분 |
| 제목 수정 | 사용자별 대목차 제목을 변경 | 신규 |
| 대목차 삭제 | 인트로 단계에서 사용자 대목차와 연결된 미답변 질문을 삭제 | 신규 |
| 카탈로그 대목차 추가 | 미선택 `chapter_template` 다중 선택 | 신규 |
| 사용자 정의 대목차 | 제목을 직접 입력해 사용자 전용 대목차 생성 | 신규 |
| 삽입 위치 선택 | 추가 항목을 어느 기존 항목 위치에 둘지 별도 단계에서 결정 | 신규 |
| 에디션 1 완료 | 최종 저장 시 목차 확정·인트로 완료를 함께 기록 | 부분 |
| 저장 완료 CTA | 작성 시작 및 `/book` 허브 진입 | 신규 |

## 4. 화면 구성

### 기본 확인 화면

- 제목, 생성된 대목차 순번·이름 목록, `수정하기`와 `저장하기`를 표시한다.
- 기존 `TocView`는 목록과 `이대로 시작하기`, `순서 바꾸기`만 제공한다. 기본 CTA의 의미가 분리되어 있지 않으므로 문구와 상태를 재구성한다.

### 수정 화면

- 각 행: 순번, 인라인 제목 수정, 삭제 버튼, 드래그 핸들.
- 스크롤 중 실수로 순서가 바뀌지 않도록 기본 확인 상태에서는 드래그를 비활성화한다. 이는 기존 `isReordering` 정책을 유지한다.
- `추가하기`는 기존 대목차 선택과 새 목차 만들기로 분기한다.

### 추가·삽입 화면

- 선택 가능한 기존 대목차는 카탈로그 중 현재 `user_chapter`에 없는 항목만 노출하고 체크박스 다중 선택을 지원한다.
- 사용자 정의 항목은 제목 입력 후 임시 선택 목록에 추가한다.
- 다음 단계에서 “맨 앞 / 특정 항목 앞 / 특정 항목 뒤 / 맨 뒤” 중 삽입 위치를 고른다.

### 저장 완료 화면

- “에디션 1 목차가 저장되었습니다”를 명시한다.
- `자서전 작성하러 가기`는 최종 확정 응답의 `bookId` 또는 에디션 식별자로 `/book/[id]/write`로 이동한다. 현재 Flutter 구현의 `/write`는 단일 책 기준의 임시/레거시 경로이며, 다권 라우팅 도입 시 전환 대상이다.
- `홈으로 가기`는 `/book`으로 이동한다. 앱의 기존 `/home`은 홈 탭이며, 여기의 “홈”은 사용자 스펙상 `/book`이다.

## 5. API 엔드포인트 (NestJS)

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `POST` | `/v1/intro/answers` | 케이스 판정 후 템플릿·질문을 사용자 사본으로 생성 | 기존 |
| `POST` | `/v1/intro/toc/confirm` | 현재 모든 `user_chapter` ID의 순서를 재배열하고 확정 | 기존, 변경 필요 |
| `GET` | `/v1/chapters` | 확정 후 사용자별 장 목록 조회 | 기존 |
| `GET` | `/v1/catalog/chapters` | 추가 후보용 활성 카탈로그 대목차 조회 | 신규 |
| `PATCH` | `/v1/intro/toc/draft` | 제목 수정·추가·삭제·재배열을 포함한 인트로 목차 초안 저장 | 신규 제안 |
| `POST` | `/v1/intro/toc/confirm` | 초안 전체를 검증·확정하고 완료 마일스톤 및 `bookId` 또는 에디션 식별자 반환. 응답: `200` + `{ "book_id": "...", "edition_label": "에디션 1" }` | 변경 필요 |

현재 `ConfirmTocDto`는 UUID `chapter_ids` 배열만 받고, 서버도 사용자 장 집합과 **정확히 일치**해야 통과시킨다. 따라서 추가·삭제·사용자 정의 대목차·삽입 위치는 기존 계약으로 처리할 수 없다.

권장 변경 경계는 다음과 같다.

- 기존 생성 흐름과 `chapter_template → user_chapter`, `question_template → user_question` 복제는 유지한다.
- 편집 중에는 초안 API 또는 확장된 최종 확정 요청에서 제목·출처·삽입 순서·삭제를 원자적으로 반영한다.
- 사용자 정의 대목차는 `chapter_template_id = null`로 둘 수 있으나, 템플릿 유래와 구별할 `source_type`(예: `template` / `custom`) 또는 동등한 출처 필드가 필요하다.
- 선택한 카탈로그 대목차를 추가할 때는 해당 템플릿의 활성 질문도 새 `user_question`으로 복제한다. 사용자 정의 대목차의 초기 질문 정책은 별도 결정이 필요하다.
- 최종 확정 응답은 작성 화면 라우팅을 위해 `bookId` 또는 에디션 식별자를 반환해야 한다. 현재 응답은 `204 No Content`이므로 변경이 필요하다.

변경: 응답을 `200` + `{ "book_id": "...", "edition_label": "에디션 1" }`로 변경한다. 앱은 `book_id`를 route argument로 작성 화면에 전달한다.

## 6. 데이터 모델

| 모델 | 역할 | 변경 방향 |
|---|---|---|
| `chapter_template` | 공용 대목차 원본, 조건·표시 순서 보유 | 기존 원본 보존 |
| `question_template` | 공용 소질문 원본 | 기존 원본 보존 |
| `user_chapter` | 사용자별 제목·순서·상태·질문 수 사본 | 제목 수정·추가·삭제 대상; 출처 유형 후보 필요 |
| `user_question` | 사용자별 질문 사본 | 템플릿 대목차 추가 시 복제; 삭제 시 인트로에서는 함께 제거 가능 |
| `user_profile.toc_confirmed_at` | 목차 최종 확정 시각 | 기존 |
| `app_user.intro_completed_at` | 인트로 완료 및 `needs_intro=false` 근거 | 기존 |
| 책/에디션 식별자 | `/book/[id]/write` 라우팅용 식별자 | 최종 확정 시 생성 또는 확보 여부 미정; `bookId`/edition ID 반환 필요 |

삭제는 아직 작성이 시작되지 않은 인트로 시점, 즉 연결된 질문·답변이 없다는 전제를 둔다. 작성 중 목차 편집까지 허용하면 답변·진행률·장 잠금·원고의 보존 정책을 별도 설계해야 한다.

“에디션 1”은 기존 코드의 도메인 필드가 아니다. 최종 저장 시점은 현 `toc_confirmed_at`/`intro_completed_at`과 연결하고, 다권·에디션이 실제 도입될 때 `book_edition` 또는 `user_profile.edition1_toc_completed_at` 같은 필드를 **후보**로 검토한다.

## 7. 기존 코드 참고

아래 경로는 실제 존재를 확인했다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 화면 | `lib/feature/intro/toc_view.dart` | 기본 목록, 재정렬 모드, 확정 CTA |
| Flutter 상태 | `lib/feature/intro/toc_controller.dart` | 생성·확정·순서 변경, 라우트 인자 전달 |
| Flutter 생성 대기 | `lib/feature/intro/toc_loading_view.dart` | 생성 중 뒤로가기 차단 |
| Flutter 주입 | `lib/feature/intro/toc_binding.dart` | B6/B7 컨트롤러 즉시 생성 |
| Flutter 장 모델 | `lib/data/models/chapter.dart` | 장 ID·순서·제목·상태 |
| Flutter API 경계 | `lib/core/network/api_client.dart`, `lib/core/network/real_api_client.dart` | `confirmToc`과 `/intro/toc/confirm` 매핑 |
| Flutter 목업 | `lib/core/network/mock_api_client.dart` | 현재 목차 재정렬 목업 |
| Flutter 장 UI | `lib/common/widgets/ds/app_chapter_row.dart` | 장 상태 행·카드 표현 |
| Flutter `/book` | `lib/feature/book/book_view.dart` | 6번 책 허브의 현재 장 목록 |
| NestJS 컨트롤러 | `server/src/intro/intro.controller.ts` | `POST intro/toc/confirm` |
| NestJS DTO | `server/src/intro/dto/request/confirm-toc.dto.ts` | 현재 ID 배열 전용 계약 |
| NestJS 트랜잭션 | `server/src/intro/services/intro-transaction.service.ts` | 템플릿 복제·정확한 ID 집합 검증·확정 시각 기록 |
| NestJS 장 엔티티 | `server/src/chapters/entities/user-chapter.entity.ts` | 사용자 사본·템플릿 nullable 참조·순서 유니크 |
| NestJS 질문 엔티티 | `server/src/chapters/entities/user-question.entity.ts` | 사용자 질문 사본 |
| NestJS 카탈로그 | `server/src/catalog/entities/chapter-template.entity.ts`, `server/src/catalog/entities/question-template.entity.ts` | 원본 대목차·질문 구조 |

## 8. 신규 개발 범위 요약

- Flutter: 기본/편집/추가/삽입 위치/저장 완료 상태와 접근성 있는 다중 선택·인라인 제목 수정 UI.
- Flutter: `Chapter` 및 `ApiClient`을 편집 초안·출처·추가 결과와 최종 확정의 `bookId` 또는 에디션 식별자를 표현할 수 있게 확장하고, 완료 CTA를 `/book/[id]/write`, `/book`으로 연결.
- NestJS: 카탈로그 대목차 후보 조회, 사용자 목차 초안 편집 또는 확장된 확정 계약, 템플릿 선택 항목의 질문 복제, 사용자 정의 대목차 출처 구분.
- NestJS: 순서 유니크 제약을 고려한 원자적 재정렬과 최종 확정 마일스톤 기록.

## 9. 열린 이슈 / 가정

1. 다중 선택 항목은 **하나의 삽입 위치에 선택 순서대로 삽입**하는 것으로 제안하지만, 항목별 위치 지정 여부는 확정되지 않았다.
2. **[결정 2026-08-04]** 새 사용자 정의 대목차는 **초기 질문 없이** 생성한다. AI 질문 생성·범용 폴백은 후속.
3. 삭제는 인트로 시점에 답변이 없다는 전제다. 작성 이후 편집을 지원하려면 답변·원고·진행률의 보존/숨김/이관 정책이 필요하다.
4. 완료 화면의 “홈”은 `/book`으로 정의한다. 기존 Flutter `/home`과 명칭이 충돌하므로 제품 용어를 정리해야 한다.
5. 에디션/책은 `POST /intro/answers` 시점에 `book_id`가 생성된다. 확정은 `POST /intro/toc/confirm`에 `book_id`를 넣어 `first_question_id`를 받는다.
6. 앱과 웹은 같은 목차를 공유하는 To-Be 방향이다. 현재 Flutter/NestJS는 TypeORM, Next.js는 Drizzle과 별도 사용자·콘텐츠 ID 체계이므로, 마이그레이션 주체·ID 매핑·동시 편집 충돌 정책을 정해야 한다.
7. **[결정 완료 2026-08-04]** 다권 `book.id`. 레거시 단일 경로(`/book`, `/chapters`, `/questions/current`)는 제거. 작성 진입은 `arguments: {bookId}` + 정적 `/write`.
