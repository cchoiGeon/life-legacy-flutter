# 4. book/[id]/write — 자서전 작성 (Flutter 앱 + NestJS)

## 1. 개요

목차의 각 **소질문**에 음성 또는 타이핑으로 답하고, AI의 리액션·후속 질문을 거쳐 다음 소질문으로 진행하는 작성 화면이다. 작성 중에는 원문을 중심으로 보여 주며, AI가 정리·재구성한 결과를 이 플로우에서 사용자에게 노출하지 않는다.

- 사용자 표기의 `book/[id]/write`는 웹식 표현이다. Flutter에는 이 경로를 그대로 만들지 않는다.
- 현재 앱은 단일 책 기준 `AppRoutes.write = '/write'`와 `GET /v1/questions/current`을 사용한다. 다권 도입 시 가장 자연스러운 방식은 **정적 GetX 라우트 `AppRoutes.write`를 유지하고**, `/intro/toc` 완료 CTA 및 책 허브에서 `Get.toNamed(AppRoutes.write, arguments: {'bookId': bookId})`로 전달하는 것이다. `WriteBinding`/컨트롤러는 route argument의 `bookId`를 검증하고 API 요청에 반영한다. 책별 딥링크 요구가 확정될 때만 GetX dynamic route를 별도 검토한다.
- 현재 NestJS 데이터 모델에는 `book`이 사용자당 사실상 단일 책이며, 질문·장 API도 `bookId`를 받지 않는다. 다권 식별자와 소유권 검증은 신규이다.
- `03-1-intro-toc.md`의 최종 완료 CTA는 이 화면으로 진입해야 한다.

## 2. 유저 플로우

1. 목차 완료 또는 책 허브에서 선택한 `bookId`를 route argument로 받아 인증된 책 소유/참여 권한을 확인한다.
2. 최초 로드 시 보이스 체크와 마이크 체크를 제공한다. 앱은 마이크 권한을 명시 요청하고, 거부·인식 불가 시 타이핑 입력을 안내한다.
3. 사용자별 최초 진입에만 튜토리얼을 표시한다. 회색 오버레이 위 흰 글씨로 질문, 다시 듣기, 녹음, 타이핑 전환, 건너뛰기 등의 기능을 단계별 안내하며 `이전` / `다음` / `건너뛰기`를 제공한다.
4. 현재 소질문을 TTS로 읽고, 최초 질문 표시 때만 한글 타이핑 애니메이션을 TTS와 동기화한다. `다시 듣기`는 TTS만 재생한다. 각 새 소질문의 첫 표시에서는 다시 TTS+애니메이션을 실행한다.
5. 사용자는 기존 앱 디자인을 따라 질문(Q), 중앙 녹음 버튼, 하단의 작은 `타이핑으로 변경하기`로 답한다. 채팅형 UI는 사용하지 않는다.
6. 녹음 완료 후 STT 전사본을 **초안**으로 자동 저장하고, 사용자가 확인·수정·확정한다. 일시정지 녹음은 제안 단계이며 도입 전 기기별 테스트가 필요하다.
7. 최초 답변 뒤 AI가 리액션+다음 질문을 제공한다. `다시 답하기`는 해당 원문을 버리고 재입력하고, `기존 답에 추가하기`는 원문을 불러와 이어 입력한다. `다른 질문`은 추후 검토 항목이다.
8. 확정 조건에 도달하면 원문 묶음을 비표시 윤문해 저장하고 다음 소질문으로 이동한다. 건너뛴 소질문은 `skipped`로 저장해 책 상세에서 재답변할 수 있어야 한다.
9. 챕터의 모든 소질문이 답변 또는 건너뛰기이면 챕터 완료 화면을 보여 준다. `리뷰하러 가기`는 `book/[id]/review`, `홈으로 이동`은 `/book` 허브로 보낸다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 단일 책 작성 | 현재 `/write`에서 현재 질문을 조회하고 답변한다 | 기존 |
| 다권 진입 | `bookId` route argument 및 책 범위 API로 현재 질문을 조회한다 | 신규 |
| 음성 입력 | `speech_to_text` 기반 단말 STT, 권한·무음·인식기 오류 시 타이핑 안내 | 기존 |
| 네이버 Voice TTS/STT | 인증된 서버 API를 통해 네이버 Voice(Clova 계열)를 사용 | 신규 전환 |
| 질문 TTS+타이핑 | 새 소질문 최초 표시에서만 음성·한글 타이핑 애니메이션 동기화 | 신규 |
| 비채팅 질문 화면 | 질문판, 녹음, 타이핑 전환, 확인 화면 중심으로 재구성 | 부분 |
| 최초 튜토리얼 | 사용자 단위 완료 상태를 저장하는 단계형 안내 | 신규 |
| 1차→꼬리질문→윤문 | 현 구현은 1회 꼬리질문 후 확정 저장 | 기존, 반복 규칙 확장 필요 |
| 다시 답하기/기존 답 추가 | 후속 질문에서 원문 삭제 또는 불러와 이어 입력 | 신규 |
| 다른 질문 | 다른 형태의 재질문 선택 | TODO |
| 건너뛰기 | 질문 상태를 `skipped`로 저장하고 다음 질문으로 이동 | 기존 |
| 녹음 일시정지 | 녹음 스트림 pause/resume 및 STT 처리 | 제안·검토/테스트 필요 |
| 이탈 경고 | 미확정 입력이 있으면 왼쪽 `나가기`, 오른쪽 강조 `취소`를 표시 | 신규 |
| 챕터 완료 CTA | review와 `/book` 허브로 이동 | 신규 |

### 음성 제공자와 동기화 가드레일

- 현재 앱 STT는 서버 전사가 아니라 `speech_to_text` 플러그인의 Android `SpeechRecognizer`/iOS Speech를 사용한다. 질문 TTS는 `replayQuestion()`이 안내 토스트만 띄우며 아직 구현되지 않았다.
- 현재 NestJS에는 TTS/STT 제공자 모듈이 없다. `AiService`도 고정 응답 스텁이다.
- 네이버 Voice 자격 증명은 Flutter 앱에 넣지 않는다. 앱은 액세스 토큰으로 NestJS 음성 API를 호출하고, 서버만 NCP 키를 보관한다.
- 제공자가 문자·단어 시간 정보를 주지 않으면 완전한 음성-문자 일치는 보장되지 않는다. 오디오 실측 길이와 한글 grapheme 단위 스케줄러를 후보로 하고, 문장부호·공백·재시도·백그라운드/복귀·접근성 및 reduced-motion을 테스트한다.

## 4. 화면 구성

### 보이스 체크·튜토리얼

- 초기 보이스 체크는 선택한 음성의 짧은 샘플 재생과 재생 실패 안내를 제공한다.
- 마이크 체크는 권한 상태와 짧은 테스트 녹음/전사를 확인한다. Android `RECORD_AUDIO`, iOS 마이크·음성 인식 설명은 이미 존재하지만, 서버형 Clova STT 도입 시 업로드 동의·네트워크 오류 UX를 추가한다.
- 튜토리얼은 write 화면 위 회색 배경과 흰 글씨, 현재 대상 강조, 이전/다음/건너뛰기로 구성한다. 완료 전에는 마지막 본 화면을 조작하지 못하게 한다.

### 질문·입력·확인

- 기존 `AskStage`/`RecordingStage` 배치를 기준으로 질문(Q), 다시 듣기, 녹음 버튼, 하단 `타이핑으로 변경하기`를 둔다.
- 녹음 중에는 전사 중간 결과와 종료/저장 제어를 제공한다. 현 앱의 버튼은 시작/종료만 제공하므로, 일시정지는 확정 기능이 아니다.
- 전사 후에는 자동 생성된 draft를 보여 주고, 확정 전 편집·다시 말하기·저장을 제공한다. 불안정한 부분 전사 결과를 `answer` 확정 행으로 곧바로 저장하지 않는다.
- 후속 질문 화면도 같은 비채팅 골격을 재사용한다. 답변 정리 결과·문단 편집 화면은 이 플로우에서 숨긴다.

### 이탈·챕터 완료

- 헤더의 나가기와 시스템 뒤로가기는 미확정 draft/녹음이 있을 때 경고를 연다. 왼쪽 `나가기`는 이탈, 오른쪽 배경색 강조 `취소`는 계속 작성을 뜻한다.
- 마지막 소질문 완료 시 현 `/book` 즉시 이동 대신 챕터 완료 화면을 우선 표시한다. 현재 Flutter/NestJS에는 review 기능이 없다.

## 5. API 엔드포인트 (NestJS)

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` | `/v1/questions/current` | 단일 책의 현재 소질문 조회, 없으면 204 | 기존 |
| `POST` | `/v1/questions/:id/answer` | 1차 원문 저장 후 1회 꼬리질문 생성 | 기존 |
| `POST` | `/v1/questions/:id/followup/:fid/answer` | 꼬리답변, 윤문, 확정 저장 | 기존 |
| `POST` | `/v1/questions/:id/skip` | draft 삭제, `skipped` 상태 저장, 다음 질문 반환 | 기존 |
| `GET` | `/v1/chapters` | 장 목록·진행 상태 조회 | 기존 |
| `POST` | `/v1/books/:bookId/write/session` | 책 권한, 현재 질문, 튜토리얼/음성 점검에 필요한 세션 정보 | 신규 제안 |
| `POST` | `/v1/books/:bookId/voice/check` | 서버 보관 네이버 Voice로 보이스/마이크 점검 지원 | 신규 제안 |
| `POST` | `/v1/books/:bookId/questions/:id/drafts` | 전사 원문·입력 방식·녹음 메타데이터를 draft로 autosave | 신규 제안 |
| `POST` | `/v1/books/:bookId/questions/:id/recordings` | 녹음 파일 업로드 및 서버 STT 전사 | 신규 제안 |
| `POST` | `/v1/books/:bookId/questions/:id/followups` | 리액션+후속 질문 생성 및 라운드 상태 갱신 | 신규/기존 API 대체 후보 |
| `POST` | `/v1/books/:bookId/questions/:id/finalize` | 답변 묶음 윤문·확정·다음 질문 또는 챕터 완료 반환 | 신규 제안 |
| `POST` | `/v1/books/:bookId/questions/:id/skip` | 책 범위의 skipped 처리 | 신규 전환 |
| `GET` | `/v1/books/:bookId/chapters/:chapterId/completion` | 챕터 완료 상태와 review/hub CTA 정보 | 신규 제안 |

기존 API는 access token guard와 질문 소유권 확인을 사용한다. 다권 API도 `bookId`만 신뢰하지 말고, 인증 사용자에게 허용된 책인지 서버에서 확인해야 한다. 네이버 Voice 키·서드파티 토큰은 어떠한 요청/응답에도 클라이언트로 보내지 않는다.

## 6. 데이터 모델

| 모델 | 역할 | 변경 방향 |
|---|---|---|
| `app_user` | 사용자·인트로 완료 상태 | 튜토리얼 동기화 정책 확정 전 기존 유지 |
| `book` | 현재 사용자 책 요약 | 다권 식별자·소유/참여 관계의 기준으로 확장 필요 |
| `user_chapter` | 사용자별 장, `locked/writing/done` 및 완료 수 | `book_id` 범위와 챕터 완료 조회 필요 |
| `user_question` | 사용자별 소질문, `pending/answered/skipped` | 재답변 이력/현재 유효 답변 정책 필요 |
| `answer_draft` | 1차 답변과 현 1회 꼬리질문 임시 저장 | 전사 autosave, 다회 후속 질문, 녹음 메타데이터를 표현하도록 확장 후보 |
| `answer` | 원문·윤문 결과·입력 방식 | 사용자가 보지 않는 최종 윤문 결과를 저장 |
| `answer_followup` | 후속 질문·답변, 현재 `seq=1` | 반복 수 확정 후 여러 `seq`를 허용하는 서비스 로직 필요 |
| `user_setting` | 현재 일일 알림만 보유 | 튜토리얼 완료/단계의 서버 저장 후보 |
| write tutorial state | 사용자별 튜토리얼 상태 | 로컬 전용 또는 서버 동기화 결정 필요 |

`answer_draft` 자동 저장과 `answer` 확정 저장은 분리한다. “STT 후 DB 자동 저장”은 전사본을 draft에 저장하는 후보로 해석하며, 사용자가 최종 답변을 확인 없이 확정할지 여부는 열린 결정이다.

## 7. 기존 코드 참고

아래 경로는 실제 존재를 확인했다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| Flutter 작성 상태 | `lib/feature/write/write_controller.dart` | 현재 질문, 1회 꼬리질문, 건너뛰기, 확인·저장 상태 |
| Flutter 작성 화면 | `lib/feature/write/write_view.dart`, `lib/feature/write/stages/` | 질문·녹음·키보드·확인·AI 대기·실패 단계 |
| Flutter 헤더/질문 편집 | `lib/feature/write/write_header.dart`, `lib/feature/write/question_edit_sheet.dart` | 나가기 현재 동작, 건너뛰기 메뉴, 질문 문구 편집 |
| Flutter 음성 | `lib/service/speech_service.dart` | 단말 STT 초기화·권한·한국어 로케일·부분 전사 |
| Flutter 권한/의존성 | `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | `speech_to_text`, `showcaseview`, 마이크·음성 인식 권한 |
| Flutter 라우팅·API | `lib/core/route/app_routes.dart`, `lib/core/route/app_pages.dart`, `lib/core/network/api_client.dart`, `lib/core/network/real_api_client.dart` | 단일 `/write`, GetX 라우트, API 경계와 실제 NestJS 매핑 |
| Flutter 책 허브 | `lib/feature/book/book_controller.dart`, `lib/feature/book/book_view.dart` | `/book`에서 단일 작성 화면으로 이동 |
| NestJS 답변 | `server/src/answers/answers.controller.ts`, `services/answers.service.ts`, `services/answers-transaction.service.ts` | 1차/후속/skip과 트랜잭션 진행 전환 |
| NestJS 답변 엔티티 | `server/src/answers/entities/answer.entity.ts`, `answer-draft.entity.ts`, `answer-followup.entity.ts` | 원문·윤문·draft·현 1회 followup |
| NestJS 장·AI | `server/src/chapters/`, `server/src/ai/services/ai.service.ts` | 현재 질문, 장 잠금 전환, AI 스텁 경계 |
| NestJS 사용자 설정 | `server/src/users/entities/app-user.entity.ts`, `user-setting.entity.ts` | 사용자 단위 상태·현재 설정 한계 |

## 8. 신규 개발 범위 요약

- Flutter: `bookId` GetX route argument 검증·전달, 최초 보이스/마이크 체크, 사용자별 튜토리얼, 비채팅 질문 UI, TTS-타이핑 동기화, 이탈 경고, 챕터 완료 화면.
- Flutter: 네이버 Voice 서버 API 클라이언트, STT 전사 draft autosave와 확정 분리, 후속 답변의 다시 답하기/기존 답 추가하기. 녹음 일시정지는 기술 검증 후에만 범위 확정.
- NestJS: 다권 책 소유·참여 권한, book 범위 질문/장/답변 API, 네이버 Voice 프록시·녹음 업로드/STT, 튜토리얼 상태, draft·후속 라운드·최종화 상태 모델.
- NestJS: 종료 사유(건너뛰기/후속 제한 도달/자동 전환)에 따른 윤문·저장 규칙을 트랜잭션과 멱등 키로 확정한다.
- 현재 앱·NestJS의 review 부재를 고려해 `book/[id]/review`는 후속 화면 구현 또는 웹 review로의 명시적 연결 정책이 필요하다.

## 9. 열린 이슈 / 가정

1. 사용자 서술은 “건너뛰기 시 `skipped` 저장 후 다음 질문”과 “건너뛰기 클릭 시 기존 답변 AI 정리·재구성·저장”을 함께 말한다. 후자는 건너뛰기 버튼인지 후속 질문 종료/자동 전환인지 대상과 시점이 충돌하므로 확정 전에는 skip에 윤문을 단정하지 않는다.
2. “loop는 최대 3번(1 → 2 → 3 → 3 → 자동 다음 질문)”에서 번호의 의미와 반복 횟수가 불명확하다. **제안**으로는 (a) 최초 답변 이후 후속 질문 최대 3회, 또는 (b) 전체 답변 라운드 최대 3회 중 하나를 선택한다. 제한 도달 시 최신 원문과 누적 답변을 비표시 윤문해 확정하고 다음 소질문으로 이동하는 패턴은 후보일 뿐이다.
3. 건너뛰기, 후속 질문 종료, 자동 전환 각각에서 AI 윤문을 할지·무엇을 확정 저장할지·재답변 시 기존 답변을 버전 보존할지는 API 상태 모델을 정한 뒤 확정한다.
4. 튜토리얼은 기기 로컬 저장이면 빠르게 구현할 수 있으나, 앱·웹 가족 공유 환경에서는 다른 기기에서도 완료 상태를 일관되게 보여 주려면 서버 동기화가 필요할 수 있다. 단계 중단 복원까지 할지와 개인정보/공유 범위를 결정해야 한다.
5. STT 전사 후 DB 자동 저장은 draft autosave로는 가능하지만, 불안정한 전사를 최종 답변으로 자동 확정할지는 별도 제품 결정이다.
6. `다른 질문`, 녹음 일시정지, 네이버 Voice의 실제 TTS/STT 기능·타이밍 메타데이터·요금·오프라인/백그라운드 정책은 제공자 검증과 실기기 테스트가 선행되어야 한다.
7. 현재 Flutter/NestJS와 Next.js는 별도 사용자·DB 모델을 쓴다. 가족 공유·웹 review를 실제로 연결하기 전 다권 ID 매핑, 권한, 웹 우선 충돌 정책을 정해야 한다.
