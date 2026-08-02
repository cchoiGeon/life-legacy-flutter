# 6-1. book/[id] — 특정 자서전 에디션 상세 (Flutter 앱 + NestJS)

## 1. 개요

특정 자서전/에디션의 작성 현황과 후처리 기능을 한곳에서 관리하는 허브 화면이다. 상단에는 지금 답할 **Question** 알림을, 본문에는 목차별 진행·리뷰 완료 여부와 전체 진행률을, 우측 액션에는 전자책·음성책·AI 영상 그림책을 둔다.

- Flutter는 웹식 `[id]` 경로를 만들지 않는다. 정적 `AppRoutes.bookDetail`(신규)을 두고 `Get.toNamed(..., arguments: {'bookId': bookId})`로 진입하며, Question 이동에는 `questionId`도 전달한다.
- 현재 Flutter/NestJS는 `/book`과 `/v1/book`이 사용자당 한 권인 단일 책 모델이며, 6-1 상세 허브·다권 식별자·리뷰 상태는 신규이다.
- Figma에서 “목차 완주율 길 이정표”에 해당하는 노드/시안은 이번 조사에서 확인하지 못했다. 상세 진행 뷰로 연결하는 버튼형 이정표는 신규 제안이다.

관련 화면: [6 내 책](./06-book.md), [4 작성](./04-book-id-write.md), [5 리뷰](./05-book-id-review.md).

## 2. 유저 플로우

1. 사용자는 책 목록에서 선택한 `bookId`를 GetX route argument로 상세 화면에 전달한다.
2. 앱은 책 소유/참여 권한, 전체·목차별 진행도, 현재 소질문, 챕터 리뷰 완료 여부, 기능별 entitlement를 한 번에 조회한다.
3. 현재 소질문이 있으면 상단 카드에 Question과 `답변하러 가기`, X를 표시한다. CTA는 `Get.toNamed(AppRoutes.write, arguments: {'bookId': bookId, 'questionId': questionId})`로 이동한다.
4. 사용자는 목차별 답변 진척과 리뷰 완료를 확인한다. 리뷰 완료 챕터는 전자책 미리보기 자격을 표시하고, 미완료 챕터는 안내를 보여 준다.
5. 길 이정표를 누르면 상세 진행 뷰(후보: `AppRoutes.bookProgress`)로 이동해 목차 완주 상태를 연속적으로 본다.
6. 전자책은 허용 범위에서 미리보기로 이동한다. 음성책과 AI 영상 그림책은 entitlement가 없으면 잠금 설명/업그레이드 안내를, 있으면 각 관리 화면으로 이동한다.
7. 팩트 체크는 향후 기능이다. 리뷰 완료 원고에서 검토 후보를 추출해 사용자가 원본·공식 자료로 확인하고 수정·무시하거나 Question으로 전환한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 단일 책 진행 화면 | 장 목록, 전체 진행률, 이어쓰기/미리보기 분기 | 기존 `/book`의 일부 |
| 에디션 상세 허브 | `bookId` 범위의 진행·후처리·권한을 묶어 표시 | 신규 |
| 현재 Question 카드 | 현재까지 확정/건너뛴 소질문 이후의 다음 질문과 작성 CTA | 신규 |
| 인앱 알림 목록 | 홈 드롭다운·알림 센터에서 목록 조회 및 모두 읽음 | 기존 |
| 푸시 알림 | `device_push_token` 테이블은 있으나 토큰 등록·발송 provider·발송 작업은 없음 | 신규 |
| 일정 알림 | `daily_question_alarm` on/off 설정만 존재, 스케줄러/실제 발송은 없음 | 신규 |
| 목차별 진행·리뷰 상태 | 장별 답변 수, 완료 여부, 리뷰 완료 여부와 ebook 자격 | 부분/신규 |
| 길 이정표 진행 뷰 | 버튼형 이정표에서 상세 진행 화면 이동 | 신규 제안 |
| 전자책 미리보기 | 완료 장의 페이지 조립 | 기존, 다권·챕터 자격 전환 필요 |
| 음성책 관리 | 현재 Flutter/NestJS 사용자 기능 없음 | 신규 |
| AI 영상 그림책 관리 | 현재 Flutter/NestJS 사용자 기능 없음 | 신규 |
| 플랜 잠금 | 기능별 서버 entitlement 판정 및 UI 잠금 | 신규 |
| 팩트 체크 | 후보 추출→사용자 확인/수정/무시→Question 전환 | 향후 TODO |

### 알림의 역할 분리

- **인앱 알림**: 서버 `notification` 행을 목록으로 보여 준다. 현재 `daily_question`·`chapter_done`·`book_ready` 유형과 질문 링크 필드는 있으나, 앱의 개별 알림 탭은 “준비 중” 토스트만 표시한다.
- **푸시 알림**: 앱이 닫혀 있어도 오늘의 질문을 알리는 전달 채널이다. `device_push_token` 엔티티는 `platform`, 고유 `token`만 저장하지만, 등록 API와 FCM/APNs 등 provider 모듈은 확인되지 않았다.
- **일정 알림**: 사용자가 일일 질문 알림을 켜고 끄는 선호 설정이다. 현재 `user_setting.daily_question_alarm`만 있으며, 시간대·발송 시각·스케줄러·재시도 정책은 없다.

X는 현재 알림 카드를 화면에서만 닫을 수 있다. 오늘의 질문 알림을 해제·미루기·읽음 처리하는 동작으로 단정하지 않는다.

## 4. 화면 구성

### 상단: 현재 Question 알림 카드

- Question 문구, 현재 목차/질문 순번, `답변하러 가기`, X를 큰 터치 영역으로 제공한다.
- `GET /v1/questions/current`은 현재 `writing` 장의 첫 `pending` 질문을 반환하고, 전부 완료하면 204를 반환한다. 다권 전환 뒤에는 선택한 `bookId` 범위에서 같은 규칙을 적용한다.
- X의 의미가 확정되기 전에는 로컬 화면 닫기만 가능한 표현으로 제한하고, 읽음·일일 해제·미루기 같은 서버 상태 변경을 연결하지 않는다.

### 진행도와 길 이정표

- 전체 진행률, 완료 장 수, 목차별 `answeredCount/questionCount`, `locked/writing/done`, 리뷰 완료 여부를 표시한다.
- 기존 장 완료는 답변 또는 건너뛰기 모두 포함한다. `reviewed` 상태는 현재 NestJS 장 모델에 없으므로 별도 챕터 원고/검토 상태가 필요하다.
- 길 이정표는 목차 구간을 버튼으로 제공하고 선택 시 상세 진행 뷰로 이동한다. 확인된 Figma 시안이 없으므로 시각 구조·애니메이션은 구현 전 디자인 확인이 필요하다.

### 후처리 액션과 잠금

- **전자책**: 무료 플랜에서도 허용한다. 현재 `/v1/book/pages`는 `done` 장만 페이지로 조립한다.
- **음성책 / AI 영상 그림책**: 잠금 상태와 해제 조건을 표시한다. Flutter/NestJS에는 사용자 관리·재생·생성 기능이 없다.
- 클라이언트 잠금은 안내용이다. 미리보기 원고, 다운로드, 오디오 생성/스트리밍, 영상 생성/재생 각각을 서버 entitlement로 검사해야 한다.
- “리뷰 완료된 챕터만 ebook 활성화”는 챕터 포함 미리보기의 자격 정책 후보로 둔다. 버튼이 전체 책 미리보기인지 챕터별 미리보기인지 확정 전에는 서버 응답이 제공 범위를 명시해야 한다.

### 팩트 체크 (TODO)

- 리뷰 완료 원고에서 날짜·이름·장소·숫자 후보를 JSON으로 추출한다.
- 결과는 “검토가 필요한 후보”로만 표시한다. AI나 외부 검색이 사실/오류를 자동 판정하지 않는다.
- 사용자는 원문·공식 자료 등으로 확인한 뒤 수정, 무시, 또는 해당 후보를 확인하는 새 Question 생성 중 하나를 선택한다.

## 5. API 엔드포인트 (NestJS)

### 현재 API

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/v1/home` | 오늘 질문, 전체 진행률, 완료 장 수 | 기존, 단일 책 |
| `GET` | `/v1/chapters` | 장별 답변 수·잠금/작성/완료 상태 | 기존, 단일 책 |
| `GET` | `/v1/questions/current` | 현재 작성할 첫 pending 소질문 | 기존, 단일 책 |
| `GET` | `/v1/book` | 책 요약 | 기존, 단일 책 |
| `GET` | `/v1/book/pages` | 완료 장의 페이지 조립 | 기존, 단일 책 |
| `GET` | `/v1/notifications` | 인앱 알림 목록 | 기존 |
| `POST` | `/v1/notifications/read-all` | 사용자 알림 전체 읽음 | 기존 |
| `GET` / `PATCH` | `/v1/settings` | `daily_question_alarm` 조회/변경 | 기존 |

### 다권 상세 허브 신규 제안

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/v1/books/:bookId/dashboard` | 책 권한, 현재 Question, 전체/목차 진행, review 상태, 기능 entitlement를 한 응답으로 반환 |
| `GET` | `/v1/books/:bookId/questions/current` | 책 범위의 현재 소질문 조회 |
| `GET` | `/v1/books/:bookId/progress` | 길 이정표/상세 진행 뷰용 목차·구간 진행도 |
| `GET` | `/v1/books/:bookId/chapters/:chapterId/ebook-eligibility` | 챕터 완료·리뷰 완료와 미리보기 가능 범위 반환 |
| `GET` | `/v1/books/:bookId/entitlements` | ebook/audio/storybook별 표시·사용 권한과 제한 반환 |
| `POST` | `/v1/books/:bookId/fact-checks` | 리뷰 완료 원고에서 검토 후보 추출 작업 생성 |
| `GET` | `/v1/books/:bookId/fact-checks` | 후보·사용자 확인 상태 조회 |
| `PATCH` | `/v1/books/:bookId/fact-checks/:id` | 후보를 수정/무시/확인 처리 |
| `POST` | `/v1/books/:bookId/fact-checks/:id/questions` | 확인이 필요한 후보를 사용자 Question으로 전환 |
| `POST` | `/v1/device-push-tokens` | 인증 사용자 단말 토큰 등록/교체/폐기 — 신규 |
| `POST` | `/v1/notifications/:id/read` | X를 읽음 처리로 정의할 경우에만 사용 — 신규 후보 |

모든 `:bookId` 요청은 액세스 토큰 사용자와 소유자/참여 관계를 서버에서 검사한다. entitlement는 API 응답, 원고 다운로드, 생성 작업, 미디어 다운로드/스트리밍마다 재검증한다.

## 6. 데이터 모델

| 모델 | 현재 상태 | 변경 방향 |
|---|---|---|
| `book` | `user_id`가 PK인 1:1 책 요약 | 독립 `book.id`, 소유/참여 관계와 에디션 범위로 전환 |
| `user_chapter` / `user_question` | 사용자 직접 귀속, 진행 상태 보유 | `book_id` 귀속 및 챕터 review 상태/원고 연결 |
| `answer` / `answer_followup` | 원문·윤문 결과 | 리뷰 완료 원고와 팩트 후보의 원천, `book_id` 범위 필요 |
| `notification` | 유형, 제목, 질문 링크, `read_at` | `book_id` 및 질문/챕터 딥링크 범위, 개별 읽음/해제 정책 필요 |
| `device_push_token` | platform·고유 token만 있음 | 단말 등록 시각, 마지막 사용, 무효 토큰 폐기 정책 및 provider 연동 필요 |
| `user_setting` | `daily_question_alarm`만 보유 | 시간대·시각·채널 선호와 미루기 정책이 필요하면 확장 |
| entitlement/plan | 없음 | 구매/프로모션/만료와 기능별 권한을 표현하는 서버 모델 신규 |
| fact-check candidate | 없음 | 원고 버전, 후보 타입·값·문맥·추출 모델, 사용자 상태, Question 연결을 보관 |

팩트 후보에는 원문 일부와 민감정보가 포함될 수 있으므로 최소 문맥만 저장하고, 접근 제어·암호화·보존/삭제 기간을 별도로 설계한다.

## 7. 기존 코드 참고

실제 존재를 확인한 경로만 기록한다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 책 허브 | `lib/feature/book/book_controller.dart`, `lib/feature/book/book_view.dart` | 단일 책 장 목록, 진행률, 작성/미리보기 분기 |
| Flutter 홈 | `lib/feature/home/home_controller.dart`, `lib/feature/home/home_view.dart` | 홈 요약, 장 목록, 인앱 알림 드롭다운 |
| Flutter 알림 | `lib/feature/notifications/notifications_controller.dart`, `notifications_view.dart` | 목록/전체 읽음, 개별 딥링크 미구현 |
| Flutter 설정 | `lib/feature/settings/settings_controller.dart`, `settings_view.dart` | 일일 질문 알림 토글 |
| Flutter 라우팅/API | `lib/core/route/app_routes.dart`, `app_pages.dart`, `lib/core/network/api_client.dart`, `real_api_client.dart` | 정적 GetX 경로와 현재 단일 책 API |
| NestJS 홈/장/책 | `server/src/home/`, `server/src/chapters/`, `server/src/book/` | 현재 질문·진행·단일 책/페이지 API |
| NestJS 알림 | `server/src/notifications/` | 목록/전체 읽음만 제공, 생성·발송 로직 확인되지 않음 |
| NestJS 설정/푸시 토큰 | `server/src/settings/`, `server/src/users/entities/user-setting.entity.ts`, `device-push-token.entity.ts` | daily alarm 설정과 토큰 엔티티 |
| NestJS 답변/AI | `server/src/answers/`, `server/src/ai/` | 답변·윤문 원천, AI는 현 고정 응답 스텁 |

## 8. 신규 개발 범위 요약

- Flutter: `bookId`/`questionId` GetX argument 기반 상세 라우트, 현재 Question 카드, 목차·review 진행 UI, 이정표 상세 뷰, 기능 잠금/오류/빈 상태.
- NestJS: 다권 책/참여 권한, 상세 dashboard·책 범위 현재 질문·진행 API, 챕터 review/ebook 자격, entitlement 판정 및 모든 보호 작업의 서버 검사.
- 알림: 단말 토큰 등록, provider 선택·발송 워커/스케줄러, 일일 알림 시간대·재시도·무효 토큰 처리, 인앱 딥링크 계약.
- 후처리: 사용자 오디오북/그림책 관리 API와 원고·미디어 작업 모델. 현재 기능이 없으므로 Admin/설계 문서를 사용자 기능으로 오인하지 않는다.
- 팩트 체크: 후보 추출·human-in-the-loop 확인·수정·무시·Question 전환과 개인정보 보호 장치를 신규 구현한다.

## 9. 열린 이슈 / 가정

1. X가 카드만 닫기, 오늘 알림 해제, 미루기, 개별 읽음 중 무엇인지 미정이다. 각 선택은 서로 다른 저장 상태와 재노출 규칙을 필요로 한다.
2. 인앱 알림, 푸시, 일정 알림의 기본 발송 시각·빈도·시간대·실패 재시도·수신 거부 처리는 정해지지 않았다. 현재 `daily_question_alarm`은 Boolean 설정뿐이다.
3. `device_push_token`은 엔티티만 존재한다. 토큰 등록 API, provider(FCM/APNs 등), 키 관리, 발송 워커와 개인정보 고지가 필요하다.
4. 길 이정표의 Figma 노드/디자인은 확인되지 않았다. 상세 진행 뷰의 정보 구조와 경로를 확정해야 한다.
5. 무료는 ebook만, 오디오북/AI 영상 그림책은 잠금이라는 화면 정책은 주어졌지만, T1~T4별 정확한 entitlement는 랜딩 가격 스펙과 운영 로드맵 사이에 재정의 이력이 있다. 서버 권한표·프로모션 우선순위를 확정해야 한다.
6. ebook이 전체 책인지 챕터별인지, 챕터 완료+review 완료가 “해당 챕터 포함 미리보기” 자격인지 확정해야 한다.
7. 오디오북은 현재 Next.js Admin 전용 생성 기능이고 Flutter/NestJS에는 사용자 관리 기능이 없다. 그림책은 Flutter/NestJS 구현이 없으며 웹에는 설계 문서만 확인됐다.
8. 팩트 체크는 AI의 사실 판정이나 자동 외부 검색이 아니다. 이름·날짜·장소·숫자 같은 개인정보를 AI에 전송하기 전 고지·명시 동의, 제공자 학습 이용·보존·삭제 정책, 원고/후보 접근 통제와 보존 기간을 확정해야 한다.
9. 후보 추출 모델은 환각·문맥 누락·동명이인·표기 차이를 만들 수 있다. 결과 문구는 “오류”가 아닌 “검토 필요”로 유지하고, 사용자 확인·수정·무시 기록과 원문 보존/되돌리기 정책을 둬야 한다.
10. Flutter/NestJS와 Next.js는 별도 사용자·DB·단일 책 모델이다. 실제 공유 전에 `bookId` 매핑, 데이터 이전, 가족 참여 권한, 웹 우선 편집 충돌 정책을 확정해야 한다.
