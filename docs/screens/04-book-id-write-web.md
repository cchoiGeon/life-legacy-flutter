# 4. book/[id]/write — 자서전 작성 (Next.js 웹)

## 1. 개요

`book/[id]/write`는 다권 자서전에서 선택한 한 권의 각 소질문을 작성하는 웹 화면이다. 부모가 앱에서 말로 작성하고 가족이 웹에서 확인·수정하는 To-Be 흐름을 고려하되, 이 화면 자체는 채팅형 UI가 아닌 질문 중심의 작성 화면으로 설계한다.

- 현재 웹 라우트는 `/write/[contentId]`이며, `contentId`는 한 권 안의 **대목차** 식별자다. `/write`는 `writing_progress`의 현재 대목차 또는 첫 대목차로 리다이렉트한다.
- `book/[id]/write`의 `[id]`는 앞으로 여러 책을 구분할 책/에디션 식별자다. 기존 `/write/[contentId]`를 그대로 별칭 처리하면 책과 대목차의 범위가 섞이므로, 다권 모델 도입 후에는 `/book/[bookId]/write` + 현재 소질문 상태로 전환한다.
- 현재 구현은 질문·답변·AI 문단을 메시지로 다루는 채팅형 상태 기계이며, 윤문 문단을 사용자에게 표시하고 저장한다. 이는 “비채팅 UI, 작성 중 윤문 비표시” 사용자 스펙과 다르므로 재구성이 필요하다.
- `03-1-intro-toc-web.md`의 목차 완료 CTA는 이 다권 화면을 향해야 한다.

## 2. 유저 플로우

1. 목차 완료 또는 책 허브에서 `bookId`를 포함한 `/book/[bookId]/write`로 들어온다. 서버 컴포넌트/Route Handler가 로그인·책 접근 권한을 확인하고 책 범위의 현재 소질문을 준비한다.
2. 첫 로드에 보이스 체크와 마이크 체크를 제공한다. 브라우저는 `getUserMedia` 권한 요청과 테스트 녹음/전사 결과를 사용자에게 명확히 알려 준다.
3. 사용자의 write 화면 최초 진입이면 회색 배경과 흰 글씨의 튜토리얼을 띄운다. 버튼별 기능을 안내하고 `이전` / `다음` / `건너뛰기`를 제공한다.
4. 새 소질문 진입 시 TTS와 한글 타이핑 애니메이션을 동기화해 질문을 표시한다. 최초 질문에서만 실행하고, `다시 듣기`는 TTS만 재생한다. 다음 소질문으로 넘어갈 때마다 동일 규칙을 반복한다.
5. 질문, 녹음 버튼, 타이핑 입력 전환을 제공한다. 녹음 종료 뒤 STT 전사본은 draft로 autosave하고, 사용자는 확인·수정 후 답변을 확정한다.
6. 이전 답변에 대해 AI 리액션+다음 질문을 제공한다. `다시 답하기`는 현재 답변을 폐기해 재입력하고, `기존 답에 추가하기`는 저장된 원문을 불러 이어 입력한다. `다른 질문`은 TODO다.
7. 후속 질문 정책의 제한에 도달하면 원문을 비표시 윤문·확정하고 다음 소질문으로 진행한다. `건너뛰기`는 `skipped` 상태로 저장하고 책 상세에서 다시 답변할 수 있게 한다.
8. 작성 중 나가려 하면 현재 입력이 지워질 수 있음을 경고한다. 왼쪽 `나가기`는 이탈, 오른쪽 강조 `취소`는 현재 화면에 남는다.
9. 한 챕터의 모든 소질문이 답변 또는 건너뛰기이면 챕터 완료 화면을 표시한다. `리뷰하러 가기`는 `/book/[bookId]/review`, `홈으로 이동`은 `/book` 허브로 이동한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| `/write/[contentId]` 작성 | 대목차별 질문을 순차 작성 | 기존 |
| `/book/[bookId]/write` | 다권 책 범위의 현재 소질문 작성 | 신규 |
| 채팅형 작성 UI | 메시지 목록, 1차/후속/윤문 단계 | 기존, 스펙상 대체 |
| 질문 중심 비채팅 UI | 질문·입력·확인만 표시, 윤문 결과 비노출 | 신규 |
| 브라우저 녹음/STT | MediaRecorder → `/api/stt` → OpenRouter 전사 | 기존 |
| 네이버 Voice TTS/STT | 인증된 서버 API를 통한 Clova 계열 음성 제공 | 신규 전환 |
| 질문 TTS | OpenRouter TTS로 `질문 듣기`·문단 다시 듣기 | 기존, 제공자 전환 필요 |
| 최초 TTS+타이핑 | 신규 질문만 음성·한글 애니메이션 동기화 | 신규 |
| AI 후속 질문 | 현재 1회 후속 질문 후 윤문 | 기존, 루프 확장 필요 |
| 정리 문단 표시·수정 | 현재 사용자가 윤문 문단을 보고 다시 생성·저장 | 기존, write에서는 제거 |
| 건너뛰기 | `answer.skipped=true`, 진행률 완료 처리 | 기존 |
| 서버 draft API | `answer_draft` GET/PUT/DELETE 존재 | 부분 — 현재 write UI 미사용 |
| localStorage draft | 윤문된 문단만 로컬 저장·복원 | 부분 |
| 이탈 경고 | browser unload/뒤로가기/나가기 경고 | 부분 — 버튼 문구/배치 변경 필요 |
| 챕터 리뷰 | `/mypage/review` 및 review API 존재 | 부분 — book route·CTA 신규 |

### 음성 제공자와 동기화 가드레일

- 현재 `/api/stt`는 OpenRouter 오디오 전사이고, `/api/tts`·`useTTS`도 OpenRouter TTS를 사용한다. 브라우저 `SpeechRecognition` 직접 사용은 확인되지 않았으며, 녹음은 `MediaRecorder`이다.
- `lib/audiobook/clova-tts.ts`의 Clova TTS는 현재 Admin 오디오북 생성용이다. 작성 질문 TTS/STT에 연결되어 있지 않으며, Clova STT 구현도 확인되지 않았다.
- 네이버/NCP 자격 증명은 브라우저 번들에 포함하면 안 된다. Next.js 서버 Route Handler 또는 통합 NestJS의 인증된 음성 API만 제공자 키를 보관한다.
- TTS 글자 타이밍은 한국어 음성 길이와 정확히 일치하지 않을 수 있다. 제공자가 word boundary/timing을 지원하면 이를 우선 검토하고, 아니면 실측 오디오 길이와 grapheme-aware 스케줄러를 사용한다. 문장부호·공백·재시도·백그라운드/복귀·접근성·reduced-motion 테스트가 필요하다.

## 4. 화면 구성

### 보이스 체크·튜토리얼

- 보이스 체크는 짧은 질문 음성 샘플의 재생 성공 여부와 음량/출력 장치 안내를 제공한다.
- 마이크 체크는 권한 요청, 녹음, 서버 STT 전사 성공·실패를 보여 준다. 권한 거부나 지원하지 않는 브라우저에서는 타이핑 전환을 명확히 제공한다.
- 튜토리얼은 사용자별 최초 진입에서만 열고, 완료/건너뛰기 후 재노출하지 않는다. 사용자가 읽기 쉬운 큰 글자와 키보드 조작·스크린리더 안내를 포함한다.

### 질문·입력·후속 질문

- 현재 `WriteContentClient`의 메시지 목록과 AI 윤문 카드 대신, 한 화면에 현재 질문(Q), `다시 듣기`, 녹음, `타이핑으로 변경하기`, 건너뛰기를 구성한다.
- 첫 질문은 TTS와 타이핑 애니메이션으로 등장한다. 재생 버튼은 음성만 다시 재생하고 애니메이션 상태를 초기화하지 않는다.
- 전사 결과는 답변 확인 UI에서 수정 가능해야 하며, 서버 draft autosave와 확정 답변을 구분한다. 부분 전사나 네트워크 재시도 중 결과를 `answer` 완료 레코드로 저장하지 않는다.
- 후속 질문은 리액션+질문만 보인다. 기존 답변 정리·재구성 결과, 문단 재생성, AI 문체 편집은 write 플로우에서 보이지 않는다.

### 이탈·챕터 완료

- 현재 구현은 browser `beforeunload`, history guard, 나가기 확인을 제공한다. 신규 모달은 왼쪽 `나가기`, 오른쪽 배경색 강조 `취소`라는 사용자 스펙으로 바꾸고 미확정 draft 유무를 기준으로 연다.
- 현재 마지막 대목차 처리 결과는 `/finish` 또는 다음 `/write/[contentId]`다. 다권 화면은 마지막 **소질문이 아닌 챕터** 완료 시점에 review/hub CTA를 보여야 한다.
- 현재 review 라우트는 `/mypage/review`이고 마이페이지에 CTA가 존재한다. `/book/[bookId]/review` 라우트·다권 스코프는 신규이다.

## 5. API 엔드포인트

### 현재 Next.js Route Handler

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` / `POST` | `/api/answers` | 답변 목록 / 윤문 문단 또는 skipped 저장 | 기존 |
| `PATCH` / `DELETE` | `/api/answers/[id]` | 확정 문단 수정 / 답변 삭제 | 기존 |
| `POST` | `/api/second-question` | OpenRouter 기반 후속 질문 생성 | 기존 |
| `POST` | `/api/polish` | 원문+후속 답변을 윤문 | 기존 |
| `POST` | `/api/polish-rewrite` | 지시문 기반 윤문 재생성 | 기존 |
| `GET` / `PUT` / `DELETE` | `/api/answer-drafts` | 소질문 서버 draft 조회·저장·삭제 | 기존, write UI 미연결 |
| `POST` | `/api/stt` | 녹음 Blob을 OpenRouter STT로 전사 | 기존 |
| `POST` | `/api/tts` | OpenRouter TTS 오디오 반환 | 기존 |
| `GET` | `/api/tts/voices` | OpenRouter 음성 목록 | 기존 |
| `POST` | `/api/review/chapter` | 대목차 답변 AI 리뷰 | 기존 |
| `POST` | `/api/review/finale` | 전체 원고 마무리 리뷰 | 기존 |

### 다권·비채팅 작성 API 제안

| Method | Path | 용도 | 상태 |
|---|---|---|---|
| `GET` | `/api/books/[bookId]/write-session` | 책 권한, 현재 소질문, 챕터 진행, 튜토리얼/음성 점검 상태 | 신규 제안 |
| `POST` | `/api/books/[bookId]/voice/check` | 서버 보관 Voice 제공자로 보이스·마이크 점검 | 신규 제안 |
| `POST` | `/api/books/[bookId]/stt` | 녹음 업로드와 네이버 Voice STT 전사 | 신규 제안 |
| `POST` | `/api/books/[bookId]/tts` | 네이버 Voice TTS 오디오와 가능 시 timing 메타데이터 반환 | 신규 제안 |
| `PUT` | `/api/books/[bookId]/questions/[questionId]/draft` | 전사 원문과 진행 중 후속 질문을 autosave | 신규 제안 |
| `POST` | `/api/books/[bookId]/questions/[questionId]/followups` | 리액션+다음 질문 생성과 라운드 기록 | 신규 제안 |
| `POST` | `/api/books/[bookId]/questions/[questionId]/finalize` | 비표시 윤문, 확정 저장, 다음 질문/챕터 완료 반환 | 신규 제안 |
| `POST` | `/api/books/[bookId]/questions/[questionId]/skip` | `skipped` 저장과 다음 질문 반환 | 신규 제안 |
| `GET` | `/api/books/[bookId]/chapters/[chapterId]/completion` | 챕터 완료와 review/hub CTA 정보 | 신규 제안 |

장기 공유 방향에서는 위 Route Handler를 NestJS 공통 API의 얇은 BFF로 두거나 웹이 NestJS API를 직접 사용한다. 어느 경우든 세션 사용자와 `bookId`의 소유·참여 권한을 서버에서 검증하고 음성 공급자 비밀값을 클라이언트로 전달하지 않는다.

## 6. 데이터 모델

| 모델 | 역할 | 변경 방향 |
|---|---|---|
| `content` / `question` | 전역 대목차·소질문 카탈로그 | 현 단일 책 전제 |
| `user_content` / `user_question` | 사용자별 목차·질문 사본 | `bookId`/edition 범위와 장 상태 필요 |
| `answer` | 확정 문단, 1차 원문, 후속 Q&A, skipped | 비표시 윤문과 재답변/버전 정책 확정 필요 |
| `answer_draft` | first/followups/polished 등 소질문 임시 상태 | UI를 연결하고 전사 autosave·현재 후속 라운드·오디오 메타데이터를 보강 |
| `writing_progress` | 현재/완료 content·question과 상태 | 책별로 분리하고 챕터 완료 상태를 표현할 필요 |
| `outline` | 사용자별 목차 JSON 캐시 | 다권/에디션 완료 기준과 관계 정리 필요 |
| tutorial state | 최초 튜토리얼 단계·완료 | localStorage 또는 사용자 서버 상태로 신규 |
| 책/에디션 모델 | `/book/[bookId]/write`의 범위 | 현재 스키마에 없음, 신규 |

현재 `answer_draft` Route Handler는 존재하지만 `WriteContentClient`는 윤문된 결과만 `localStorage` 키 `lifelegacy-polished-draft-v2:*`로 저장한다. 새 설계에서는 서버 draft를 단일 복원 기준으로 우선하고, 로컬 저장은 오프라인/네트워크 실패 완화용으로만 둘지 결정한다.

## 7. 기존 코드 참고

아래 경로는 실제 존재를 확인했다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 웹 작성 라우트 | `app/app/(dashboard)/write/page.tsx`, `app/app/(dashboard)/write/[contentId]/page.tsx` | 현재 대목차 작성 진입·Suspense 경계 |
| 웹 작성 상태/UI | `app/app/(dashboard)/write/[contentId]/WriteContentClient.tsx` | 채팅형 1차/후속/윤문, 건너뛰기, localStorage draft, 이탈 경고 |
| 답변 API | `app/app/api/answers/route.ts`, `app/app/api/answers/[id]/route.ts` | 확정·skipped 저장, 수정·삭제 |
| AI API | `app/app/api/second-question/route.ts`, `app/app/api/polish/route.ts`, `app/app/api/polish-rewrite/route.ts` | OpenRouter 후속 질문·윤문·재생성 |
| draft API | `app/app/api/answer-drafts/route.ts` | 서버형 소질문 draft CRUD |
| 웹 음성 | `app/components/voice/STTPanel.tsx`, `app/app/api/stt/route.ts` | MediaRecorder, 마이크 권한, OpenRouter STT |
| 웹 TTS | `app/hooks/useTTS.ts`, `app/app/api/tts/route.ts`, `app/app/api/tts/voices/route.ts` | OpenRouter TTS 음성 목록·재생 |
| Clova 오디오북 | `app/lib/audiobook/clova-tts.ts` | 서버 환경변수로 NCP Clova TTS 호출; 작성용 미연결 |
| Drizzle 모델 | `app/lib/db/schema.ts` | `answer`, `answer_draft`, `writing_progress`, 사용자 콘텐츠·질문 |
| 현재 리뷰 | `app/app/(dashboard)/mypage/review/page.tsx`, `ReviewClient.tsx`, `app/app/api/review/` | `/mypage/review` 및 장/전체 리뷰 API |

## 8. 신규 개발 범위 요약

- Next.js: `/book/[bookId]/write` 다권 라우트, 서버 권한 검증, 현재 소질문 기반의 비채팅 write 클라이언트, 기존 `/write/[contentId]`에서의 전환/호환 전략.
- Next.js: 보이스·마이크 체크, 사용자 단위 튜토리얼, TTS-한글 타이핑 동기화, reduced-motion 접근성, 스펙형 이탈 경고, 챕터 완료 CTA.
- Next.js: 기존 OpenRouter 작성 음성에서 네이버 Voice 서버 통합으로 전환하고, 공급자 키를 서버 환경변수에만 둔다.
- Next.js: STT 초안 autosave와 최종 답변 확정 분리, 다시 답하기/기존 답에 추가하기, 다회 후속 질문 상태 및 종료 사유별 저장 규칙.
- 데이터/API: book/edition 범위, 책별 진행률·튜토리얼 상태, `/book/[bookId]/review` 라우트와 기존 `/mypage/review` 기능의 재사용 또는 이전.

## 9. 열린 이슈 / 가정

1. 사용자 스펙의 “건너뛰기하면 skipped 저장 후 다음 질문”과 “건너뛰기 클릭 시 기존 답변 AI 정리·재구성·저장”은 서로 충돌한다. 후자의 대상 버튼/시점이 명확해질 때까지 skip에 윤문을 확정 규칙으로 쓰지 않는다.
2. “loop는 최대 3번(1 → 2 → 3 → 3 → 자동 다음 질문)”은 번호와 횟수 의미가 불명확하다. **제안**은 (a) 최초 답변 뒤 후속 질문 최대 3회 또는 (b) 최초 포함 전체 답변 라운드 최대 3회 중 하나이며, 제한 도달 시 최신 원문/누적 답변을 비표시 윤문해 확정하는 패턴은 후보이다.
3. 건너뛰기·후속 질문 종료·자동 전환 각각의 AI 윤문 여부, draft 보존, 확정 답변 버전 보존 규칙은 API 상태 모델에서 별도 확정해야 한다.
4. 튜토리얼을 localStorage만으로 저장하면 기기별로 독립적이다. 앱·웹을 가족이 함께 쓰는 방향에서는 서버 저장·동기화가 필요할 수 있으므로, 완료 상태만 동기화할지 마지막 단계도 복원할지 결정해야 한다.
5. STT 결과의 “DB 자동 저장”은 서버 draft autosave로 해석하는 것이 안전하다. 전사 즉시 `answer` 최종 확정을 허용할지는 사용자의 확인 단계와 충돌하므로 제품 결정을 남긴다.
6. 일시정지 녹음은 요구사항상 신규 제안이며 확정 범위가 아니다. MediaRecorder 지원 편차, 녹음 파일 결합, 재시도, 탭 백그라운드 동작을 테스트한 뒤 결정한다.
7. 현재 review는 `/mypage/review`에서 답변이 있는 대목차를 대상으로 동작한다. 다권 book route, 챕터 완료 직후 진입 조건, NestJS/Flutter와의 공유 데이터 모델은 아직 없다.
8. Next.js Drizzle과 Flutter/NestJS TypeORM은 별도 사용자·식별자·DB 모델이다. 가족 공유와 웹 우선 수정 정책을 실제 적용하기 전 book ID 매핑, 권한, 동시 편집 충돌, 이전 계획을 확정해야 한다.
