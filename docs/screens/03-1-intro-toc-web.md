# 3-1. intro2 — 만들어진 목차 확인·편집 (Next.js 웹)

## 1. 개요

웹에서 인트로가 생성한 목차를 순서대로 확인·편집하고, 최종 저장으로 **에디션 1 목차 생성 완료**를 확정하는 화면이다. 현재 `/outline`은 생성 목차를 읽기 전용으로 보여 주고 `/write`로 바로 이동한다. `/write`는 현재 단일 책 구현의 임시/레거시 경로이며, 다권 라우팅 도입 시 `/book/[id]/write`로 전환한다. 사용자 스펙의 편집 흐름은 초기 인트로 단계로 분리해 구현해야 한다.

- 목표: 앱과 웹이 같은 사용자 목차를 공유한다는 To-Be 방향을 따른다.
- 현 Next.js는 자체 Route Handler + Drizzle/PostgreSQL 구조이며, NestJS/TypeORM과 DB·ID 체계가 분리되어 있다.
- 따라서 단기에는 Route Handler 확장 또는 장기에는 공유 NestJS 전환 중 하나를 선택해야 한다.

## 2. 유저 플로우

1. `/intro`의 자기소개 또는 대질문 직접 선택 결과로 목차를 만든다.
2. `/outline`(또는 이 화면 전용 경로)에서 대목차를 `sortOrder` 순으로 표시한다.
   - 기본 CTA `수정하기`: 편집 상태 진입.
   - 기본 CTA `저장하기`: 변경 없이 현재 목차를 에디션 1으로 확정.
3. 수정 상태에서 제목 수정, 삭제, 드래그 앤 드롭 재정렬, `추가하기`를 제공한다.
4. 추가 화면에서 미선택 카탈로그 대목차를 다중 선택하거나 `새로운 목차 만들기`로 제목을 작성한다.
5. 별도 삽입 위치 선택 화면에서 추가 항목의 위치를 정한다.
6. 삽입 저장 후 목차 순서 화면으로 돌아와 편집 결과를 검토한다.
7. 최종 `저장하기` 후 저장 완료 화면을 보여 준다.
   - `자서전 작성하러 가기` → `/book/[id]/write`
   - `홈으로 가기` → `/book` (다권 전환 시 `/book/[id]`)

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 생성 목차 조회 | `/outline`에서 JSON 목차를 번호순으로 표시 | 기존 |
| 선택 기반 목차 생성 | 카탈로그 대질문 선택 → 사용자 목차·질문 생성 | 기존 |
| 기본 저장/확정 | 에디션 1 완료 시점·완료 화면 | 신규 |
| 순서 변경 | 사용자 목차 API와 마이페이지의 HTML drag/drop 로직은 존재 | 부분 |
| 제목 수정 | API는 존재하지만 마이페이지 UI는 주석 처리 | 부분 |
| 삭제 | 사용자 목차와 연결 질문·답변 삭제 API/UI가 존재 | 기존, 인트로 안전정책 필요 |
| 사용자 정의 대목차 | 제목만 입력해 마지막에 추가하는 API가 존재 | 부분 |
| 카탈로그 다중 선택 | 인트로 시작 경로에서만 일괄 선택 가능 | 부분 |
| 삽입 위치 선택 | 특정 위치 삽입 | 신규 |
| 저장 완료 CTA | `/book/[id]/write`, `/book` 두 목적지 | 신규 |

## 4. 화면 구성

### 기본 확인 화면

- 제목, 대목차 카드 목록, `수정하기`와 `저장하기`를 제공한다.
- 현재 `/outline`은 `outline.chapters` JSON을 숫자 키로 정렬하여 단순 목록으로 렌더링하고, `이 목차로 자서전 작성하기`만 제공한다.

### 수정 화면

- 카드마다 제목 수정, 삭제, 드래그 핸들을 제공한다.
- 기존 `/mypage`는 HTML `draggable` 기반으로 대목차 순서 변경과 삭제를 제공하므로 UI 상호작용은 재사용 후보이다.
- 다만 대목차 제목 수정·추가 버튼은 현재 주석 처리되어 있어 인트로 화면에는 별도 활성화·검증이 필요하다.

### 추가 및 삽입 위치 화면

- 카탈로그 목록에서 이미 현재 목차에 포함된 항목을 제외한 후보를 체크박스 다중 선택한다.
- `새로운 목차 만들기`는 제목 입력으로 사용자 전용 항목을 만든다.
- 다음 단계에서 하나의 삽입 위치를 선택한다. 제안은 다중 선택 항목을 선택 순서대로 같은 위치에 넣는 방식이다.

### 저장 완료 화면

- “에디션 1 목차 저장 완료”를 표시한다.
- `자서전 작성하러 가기`는 최종 확정 응답의 `bookId` 또는 에디션 식별자로 `/book/[id]/write`로 이동한다. 현재 `/write`는 단일 책 구현의 임시/레거시 경로이며, 다권 라우팅 도입 시 전환 대상이다.
- 기존 `/finish`는 작성 완료 후 `/mypage`로 이동하는 단일 CTA이므로, 목차 완료 전용 완료 화면은 별도로 구현한다.
- “홈”은 사용자 스펙에 따라 `/book`을 뜻하며 `/mypage`나 기존 앱 `/home`을 뜻하지 않는다.

## 5. API 엔드포인트

### 현재 Next.js Route Handler

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` / `POST` | `/api/outline` | 생성 목차 조회 / 자기소개 기반 생성 | 기존 |
| `POST` | `/api/outline/select` | 카탈로그에서 고른 대질문으로 목차·질문 생성 | 기존 |
| `GET` | `/api/catalog/contents` | 전역 카탈로그 대목차 조회 | 기존 |
| `GET` | `/api/contents` | 현재 사용자 대목차 목록 조회 | 기존 |
| `GET` / `POST` / `PATCH` | `/api/user-contents` | 사용자 대목차 조회 / 마지막 추가 / 전체 순서 재배열 | 기존 |
| `PATCH` / `DELETE` | `/api/user-contents/[id]` | 제목 수정 / 관련 질문·답변을 포함한 삭제 | 기존 |

### Route Handler 확장 방향

- `POST /api/user-contents`는 현재 마지막 순서로만 추가한다. `insertAfterId` 또는 `insertIndex`와 다중 항목 입력을 추가하고, 전체 순서 재계산을 트랜잭션으로 처리해야 한다.
- 카탈로그 선택 항목은 `createUserContentsFromSelection`과 질문 복제 로직을 재사용하되, 기존 목차를 초기화하는 `resetUserWritingState`를 인트로 편집에서 호출하지 않도록 분리해야 한다.
- 최종 확정용 `POST /api/outline/confirm` 같은 명시적 엔드포인트와 `edition1_toc_completed_at` 후보 상태를 설계한다. 이 응답은 `/book/[id]/write` 라우팅에 필요한 `bookId` 또는 에디션 식별자를 반환해야 한다. 현 `outline`은 캐시 역할이고 완료 상태를 갖지 않는다.

### 공유 NestJS 전환 방향

앱·웹이 같은 목차를 실제로 공유하려면 Next.js Route Handler가 NestJS의 다음 계약을 호출하거나, 웹을 NestJS API로 이전해야 한다.

| Method | Path | 현재 한계 / 전환 필요 |
|---|---|---|
| `POST` | `/v1/intro/toc/confirm` | 현 계약은 생성된 모든 `user_chapter` UUID의 재배열만 허용; 확장 시 `bookId` 또는 에디션 식별자 반환 필요 |
| `GET` | `/v1/chapters` | 사용자별 확정 목차 조회 |
| `GET` | `/v1/catalog/chapters` | 추가 후보 제공용 신규 필요 |
| `PATCH` | `/v1/intro/toc/draft` | 제목·추가·삭제·삽입 위치를 포함할 신규 제안 |

NestJS의 현 confirm 계약은 입력 ID 집합이 보유한 모든 장과 동일해야 한다. 따라서 추가·삭제·사용자 정의 대목차·삽입 위치를 현 계약에 억지로 실을 수 없으며, 신규 또는 변경 API가 필요하다.

## 6. 데이터 모델

### 현재 Next.js

| 모델 | 역할 | 현재 한계 |
|---|---|---|
| `content` | 전역 대목차 카탈로그 | 사용자별 출처 연결 정보 없음 |
| `question` | 전역 소질문 카탈로그 | 템플릿 원본 |
| `user_content` | 사용자별 대목차 사본 | `contentId`, 제목, 순서 보유; 사용자 정의 항목의 출처 유형 없음 |
| `user_question` | 사용자별 소질문 사본 | 사용자 목차에 연결된 질문 |
| `outline` | 사용자별 목차 JSON 캐시 | 에디션 완료 상태가 없음 |
| `writing_progress` | 현재 작성 진행 상태 | 목차 확정 마일스톤이 없음 |
| `answer` | 사용자 답변·윤문 결과 | 삭제 시 현재 함께 삭제됨 |
| 책/에디션 식별자 | `/book/[id]/write` 라우팅용 식별자 | 최종 확정 시 생성 또는 확보 여부 미정; `bookId`/edition ID 반환 필요 |

### 보존 원칙과 To-Be

- 카탈로그 원본은 유지하고 사용자별 `user_content`/`user_question` 사본을 변경한다. 이는 NestJS의 `chapter_template`/`user_chapter` 구조와 같은 의도다.
- 사용자 생성 목차는 카탈로그 유래 항목과 구분 가능한 `source_type` 또는 원본 ID nullable 정책이 필요하다. 단순한 임의 `contentId`만으로는 출처를 명확히 표현하기 어렵다.
- 인트로 시점에는 연결 질문·답변이 없다는 전제에서 삭제를 허용한다. 현재 Next API는 답변·질문을 실제로 삭제하므로, 작성 중 편집을 허용하는 경우에는 보존·숨김·원고 반영 정책을 별도 정의해야 한다.
- 에디션 1 도메인 필드는 현재 없다. `book_edition` 또는 프로필/진행 테이블의 `edition1_toc_completed_at`은 **후보**이며, 확정 시점은 NestJS의 `toc_confirmed_at`/`intro_completed_at`과 연결해야 한다. 작성 진입을 위해 최종 확정 응답에는 `bookId` 또는 에디션 식별자가 필요하다.

## 7. 기존 코드 참고

아래 경로는 실제 존재를 확인했다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 목차 화면 | `app/app/(dashboard)/outline/page.tsx` | 생성 목차 조회·정렬·작성 진입 |
| 생성 API | `app/app/api/outline/route.ts` | 케이스 판정, 사용자 콘텐츠·질문 복제, outline 동기화 |
| 선택 API | `app/app/api/outline/select/route.ts` | 카탈로그 다중 선택 기반 생성 |
| 콘텐츠 조회 | `app/app/api/contents/route.ts` | 사용자 대목차 목록 |
| 사용자 콘텐츠 CRUD | `app/app/api/user-contents/route.ts`, `app/app/api/user-contents/[id]/route.ts` | 추가·순서 변경·제목 수정·삭제 |
| 카탈로그 조회 | `app/app/api/catalog/contents/route.ts` | 전역 대목차 목록 |
| 대목차 카드 UI | `app/app/(dashboard)/mypage/page.tsx` | 카드 drag/drop, 삭제, 관리 다이얼로그; 제목 수정·추가 UI는 주석 처리 |
| 기존 완료 화면 | `app/app/(dashboard)/finish/page.tsx` | 작성 완료 후 `/mypage` 진입 |
| Drizzle 스키마 | `app/lib/db/schema.ts` | `content`, `user_content`, `user_question`, `outline`, `writing_progress`, `answer` |

## 8. 신규 개발 범위 요약

- `/outline`을 기본 확인/수정/삽입 위치/완료 상태로 확장하거나 전용 인트로 목차 라우트를 만든다.
- 모바일·키보드 접근성을 고려한 drag/drop, 다중 선택, 인라인 제목 수정, 삭제 확인 UI를 구현한다.
- Route Handler에 특정 위치 삽입, 카탈로그 항목 복제, 사용자 정의 항목 출처 구분, 최종 확정 마일스톤과 `bookId` 또는 에디션 식별자 반환을 추가한다.
- 장기적으로는 Next.js Drizzle 데이터를 NestJS TypeORM 사용자 목차와 통합하거나 명시적인 동기화·ID 매핑 계층을 만든다.

## 9. 열린 이슈 / 가정

1. 다중 선택한 항목은 하나의 삽입 위치에 선택 순서대로 삽입하는 것을 제안한다. 항목별 위치 선택 여부는 미확정이다.
2. 사용자 정의 대목차의 소질문을 즉시 만들지, 후속 AI/수동 생성으로 둘지 결정이 필요하다.
3. 현재 Next.js 삭제 API는 답변까지 물리 삭제한다. 인트로 이후 편집을 허용할 경우 데이터 보존 정책을 먼저 정해야 한다.
4. 최종 완료의 “홈”은 `/book`이며, 현재 웹에는 해당 라우트 존재 여부를 이번 범위에서 확인하지 않았다. 다권 전환의 목적지는 `/book/[id]`로 정의한다.
5. 에디션 1은 현 Next.js·NestJS 스키마에 없다. 후보 필드를 확정처럼 도입하지 않고, 우선 확정 시점과 기존 `toc_confirmed_at`/`intro_completed_at`의 관계를 합의해야 한다.
6. Next.js Drizzle과 NestJS TypeORM은 별도 DB 모델·사용자 ID·대목차 ID를 사용한다. 공유 목차 전환 전 마이그레이션 소유자, ID 매핑, 동시 편집 우선순위(로드맵의 웹 우선), 롤백 방식을 정해야 한다.
7. 최종 확정 단계에서 책/에디션 식별자를 생성할지, 현재 단일 책 식별자를 반환할지 데이터 모델이 확정되지 않았다. 확정 API가 `/book/[id]/write`에 필요한 `bookId` 또는 edition ID를 반환해야 한다.
