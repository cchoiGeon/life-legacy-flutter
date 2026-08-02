# 5. book/[id]/review — 챕터 리뷰 (Next.js 웹)

## 1. 개요

`/book/[bookId]/review`는 한 챕터의 모든 소질문 답변을 불러와 AI가 자서전 형태로 종합한 원고를 읽고 수정·저장하는 웹 화면이다. 기존 `/mypage/notebook`의 종합, 직접 편집, 문장 하이라이트, 문단 사이 사진 배치 기능을 한 챕터 범위로 재사용하는 방향이다.

- 현재 공개 구현 경로는 `/mypage/notebook`이며 사용자별 대목차 `contentId`를 순회한다. 페이지 최초 진입 시 저장 원고를 우선 읽고, 없으면 `/api/notebook/synthesize`가 모든 답변을 `chapter_notebook`에 AI 종합한다.
- 현재 `/mypage/review`는 `chapter_notebook`을 다루지 않는다. 답변별 AI 수정 제안을 수락/직접 입력하는 별도 리뷰이고, mypage CTA가 숨겨진 상태다. 신규 챕터 리뷰와 이름·역할을 혼동하지 않는다.
- `/api/notebook/rewrite`는 존재하지만 `NotebookClient`의 AI 수정 버튼과 패널은 TODO 주석으로 숨겨져 있다. `/api/notebook/final-review`도 API와 결과 UI 일부는 있으나 최종 검수 버튼이 숨겨져 있다.
- To-Be 다권 경로는 `/book/[bookId]/review`이며, 기존 `/mypage/notebook`, `/mypage/review`은 현 구현 경로로 유지·이전 전략을 별도로 정한다.

## 2. 유저 플로우

1. `/book/[bookId]/write`에서 한 챕터의 모든 소질문을 답변/건너뛰기로 완료하고 `리뷰하러 가기`를 누른다. 서버는 로그인과 `bookId` 접근 권한, `chapterId`의 책 소속을 확인한다.
2. 리뷰 세션은 해당 챕터의 저장된 종합 원고를 불러온다. 없으면 모든 소질문 답변을 AI로 자서전 문체로 종합해 저장한다.
3. 사용자는 문장별로 표시된 원고를 읽고 `읽어주기`를 실행한다. 재생 중 문장은 하이라이트되고, 현재 위치는 화면 중앙으로 스크롤된다.
4. 사용자는 직접 편집해 저장할 수 있다. 사진은 유료 플랜에서만 챕터당 최대 5장을 업로드/선택하고, 문단 사이 위치에 배치한다.
5. 재생 중 `중지`한 문장을 기준으로 `AI와 함께 수정하기`를 열어 보이스 입력으로 지시하는 흐름은 TODO/검토다. 중지 문장과 이전·다음 문장, 총 3문장만 AI 컨텍스트로 전달해 수정안을 즉시 반영하는 후보다.
6. 사진이 없으면 AI 사진 1장 만들기를 제공한다. 이 기능은 TODO지만 출시 전 개발·테스트가 반드시 필요한 백로그이며, 생성 이미지는 챕터의 첫 이미지 슬롯에 우선 배치한다.
7. 저장 시 첫 챕터에는 “챕터1 저장 완료”, 이후에는 “현재 챕터 저장 완료”와 “나중에 수정 가능해요”를 표시한다. 다음 챕터가 있으면 `다음 챕터 넘어가기`, 없으면 `/book`으로 가는 `홈으로 이동`을 표시한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 챕터 AI 종합 | 소질문 답변 전체를 자서전 원고로 생성하고 `chapter_notebook`에 저장 | 기존 재사용, 다권 전환 필요 |
| 직접 편집 | textarea 기반 챕터 본문 수정·저장 | 기존 재사용 |
| 문장 하이라이트 | 분리된 문장 중 현재 읽는 문장을 강조·자동 스크롤 | 기존 재사용 |
| 읽어주기 | 현재는 문장 배열을 순차 재생 | 기존 재사용, Naver Voice 전환 필요 |
| 문단 사이 사진 배치 | `afterSentenceIndex` 위치에 소질문 첨부 사진 배치 | 기존 재사용, 한도 정책 변경 |
| 수동 사진 넣기 | 유료만, 챕터당 최대 5장 | 신규 정책·서버 검증 |
| AI 사진 1장 | 무료/유료 모두 가능, 사진이 없을 때 첫 이미지 슬롯 우선 | TODO이지만 must 개발·테스트 |
| AI와 함께 수정 | 중지 위치의 3문장 컨텍스트+보이스 지시로 부분 수정 | TODO/검토 |
| 플랜 제어 | 무료는 수동 사진 불가·AI 수정 잠금, 유료는 사진/AI 수정 가능 | 신규 |
| 최종 검수 | 전 장 교차 검수 | 기존 API/부분 UI이지만 이 화면의 챕터 편집과 별도 |

### 플랜과 권한

- 무료: 수동 사진 넣기는 제공하지 않지만 AI 사진 1장 만들기는 가능하며, AI와 함께 수정하기는 잠금이다.
- 유료: 수동 사진 넣기와 AI 수정 기능을 이용할 수 있다. 플랜 명칭·세부 티어는 지정하지 않는다.
- Route Handler 또는 공유 NestJS 서비스가 플랜, 챕터별 수동 사진 개수(최대 5), AI 수정 권한을 매 요청에서 검증한다. 클라이언트 버튼을 숨기는 것만으로는 접근 제어가 아니다.

## 4. 화면 구성

### 헤더·원고·문장 TTS

- 헤더: 챕터 제목, 저장 상태, `읽어주기`/`중지`, 편집 전환을 둔다.
- 읽기 모드: 원고를 문단 단위로 보이되 문장은 개별 span으로 감싸 현재 재생 문장을 하이라이트한다. 현 `NotebookClient`의 `splitSentences`, `useSentenceTTS`, 자동 스크롤 동작을 재사용 후보로 한다.
- Naver Voice는 긴 원고를 제공자 최대 길이 이하의 문장/문단 청크로 나눠 서버에서 합성하고 순차 재생한다. 청크 경계·재생 실패·중지·재개·캐시는 별도 설계한다.
- 현재 `/api/tts`와 `useTTS`는 OpenRouter를 사용한다. `lib/audiobook/clova-tts.ts`는 서버 환경변수로 Clova TTS를 호출하지만 Admin 오디오북 전용이다. 리뷰용 Naver Voice 연결은 신규/전환이다.

### 편집·사진

- 직접 편집은 본문 전체 편집 후 저장한다. 문단 사이 이미지 배치는 편집 후에도 anchor가 유효한지 재검증한다.
- 사진 UI는 문단/문장 뒤 `+ 사진`에서 보유 사진 선택 또는 업로드를 제공한다. 기존은 소질문당 1장 `answer_attachment`를 참조하므로, “챕터당 5장”은 업로드 대상과 집계 기준을 새로 정의해야 한다.
- 사진 placement는 단순 URL 배열이 아니라 본문 위치와 별도 저장한다. 원고 수정 시 문장 인덱스가 변할 수 있으므로 문단 index와 안정적 anchor/block ID를 함께 두는 모델을 검토한다.

### AI 수정·완료

- `AI와 함께 수정하기`는 확정 구현이 아니다. TTS 중지 시 현재 문장 인덱스를 잡고, 전·현재·다음 3문장과 보이스 지시를 서버로 보내 수정안을 받아 즉시 미리 반영하는 TODO/검토다. 저장 전 취소/되돌리기와 사실 변경 방지 기준이 필요하다.
- AI 사진 1장 만들기는 TODO이면서 출시 전 개발·테스트가 필수다. 사진이 없을 때 챕터 글을 바탕으로 생성하고 첫 번째 이미지 슬롯에 우선 삽입한다.
- 완료 패널은 “나중에 수정 가능해요”와 다음 챕터/홈 CTA를 제공한다. 첫 장의 정확한 문구는 “챕터1 저장 완료”, 이후에는 “현재 챕터 저장 완료”로 일반화한다.

## 5. API 엔드포인트

### 현재 Next.js Route Handler

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/api/notebook` | 개요 또는 `contentId`별 저장 원고·사진·검토 상태 | 기존 |
| `PATCH` | `/api/notebook` | 본문, 이미지 placement, 제목, draft/reviewed 상태 저장 | 기존 |
| `POST` | `/api/notebook/synthesize` | 답변 전체를 AI 종합해 `chapter_notebook` upsert | 기존 |
| `GET` | `/api/notebook/photos?contentId=` | 소질문 사진 슬롯·빈 슬롯 정보 | 기존 |
| `POST` | `/api/notebook/rewrite` | AI 수정안만 반환, 저장은 별도 PATCH | 기존 API, UI 숨김 |
| `POST` | `/api/notebook/final-review` | 전 장 reviewed 전제의 교차 검수 | 기존 API, 버튼 숨김 |
| `POST` | `/api/notebook/final-review/fix` | 검수 이슈 기반 장별 수정안 | 기존 |
| `POST` | `/api/upload-image` | 소질문별 1장 첨부 업로드/Neon BYTEA 저장 | 기존 |
| `GET` | `/api/answer-images/[id]` | 소유자 확인 후 첨부 이미지를 스트리밍 | 기존 |
| `GET` / `POST` | `/api/photo-inbox` | 사진 임시함 조회/일괄 업로드·AI 매칭 | 기존 |
| `POST` | `/api/tts` | OpenRouter TTS, 요청당 최대 2,000자 | 기존·전환 대상 |
| `GET` | `/api/tts/voices` | OpenRouter 음성 목록 | 기존·전환 대상 |
| `POST` | `/api/review/chapter` | 답변별 AI 수정 제안 리뷰 | 기존, 신규 화면의 종합 리뷰와 별도 |
| `POST` | `/api/review/finale` | 전체 답변의 요약·공감·응원 | 기존, 별도 |

### 다권 리뷰 API 제안

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| `GET` | `/api/books/[bookId]/chapters/[chapterId]/review` | 책/챕터 권한, 종합 원고, block·placement, 플랜 권한 조회 | 신규 제안 |
| `POST` | `/api/books/[bookId]/chapters/[chapterId]/review/synthesize` | 답변 전체로 챕터 원고 생성/재생성 | 신규 제안 |
| `PATCH` | `/api/books/[bookId]/chapters/[chapterId]/review` | 본문·placement·검토 완료 저장, 낙관적 버전 충돌 처리 후보 | 신규 제안 |
| `POST` | `/api/books/[bookId]/chapters/[chapterId]/review/tts` | Naver Voice 청크/문장 오디오 반환 | 신규 제안 |
| `POST` | `/api/books/[bookId]/chapters/[chapterId]/review/media` | 유료 수동 사진 업로드/배치, 서버의 5장 한도 검증 | 신규 제안 |
| `POST` | `/api/books/[bookId]/chapters/[chapterId]/review/images/generate` | AI 사진 1장 생성·첫 슬롯 배치 | 신규 제안·must 개발/테스트 |
| `POST` | `/api/books/[bookId]/chapters/[chapterId]/review/voice-rewrite` | 3문장 컨텍스트·음성 지시로 부분 수정안 생성 | TODO/검토 |

공유 NestJS 전환 방향에서는 위 Next.js Route Handler를 얇은 BFF로 유지하거나 NestJS 공통 API로 직접 이관한다. 어느 경우든 세션 사용자와 `bookId`의 권한을 서버에서 확인하고, Naver/이미지 제공자 키를 브라우저에 전달하지 않는다.

## 6. 데이터 모델

| 모델 | 현재 역할 | 리뷰 화면의 변경 방향 |
|---|---|---|
| `chapter_notebook` | 대목차 종합 원고, AI 초안, placement, reviewed 상태 | `bookId`/`chapterId` 범위와 원고 버전·block 모델로 확장 후보 |
| `answer` | 확정 답변, 원문, 후속 Q&A, `imageUrl` | AI 종합 입력; 기존 소질문 사진 참조 유지 여부 결정 |
| `answer_attachment` | 소질문당 최대 1장, Neon BYTEA | 챕터 최대 5장 정책과 별도의 chapter media 또는 제약 확장 필요 |
| `photo_inbox` | 임시 사진·AI 매칭 추천 | 리뷰의 선택 원천으로 재사용 가능하나 플랜/챕터 한도는 별도 검증 |
| `image_placements` | `{ afterSentenceIndex, questionId }[]` | 문단 index + block/anchor + media ID로 발전 후보 |
| `writing_progress` | 현재 대목차/질문과 notebook 상태 | 책별 리뷰 세션·챕터 저장 완료 상태 분리 필요 |
| plan/approval | `approval_request`는 제작 승인 상태, 사용자 플랜 필드 없음 | 무료/유료 entitlement, AI 수정·사진 권한은 신규 모델/외부 결제 연동 필요 |

현재 `chapter_notebook`은 `answer_attachment`를 `questionId`로 참조하며 `afterSentenceIndex`에 배치한다. 현 구조는 문단 사이 배치의 출발점이지만, 본문을 직접 수정하면 인덱스가 흔들릴 수 있고 챕터당 5장·AI 생성 출처·플랜 검증을 표현하기 부족하다.

## 7. 기존 코드 참고

아래 경로의 존재와 동작을 확인했다.

| 영역 | 경로 | 참고 내용 |
|---|---|---|
| 노트북 UI | `app/app/(dashboard)/mypage/notebook/NotebookClient.tsx` | 저장본 우선→미존재 시 synthesize, 직접 수정, 문장 하이라이트, 문장 사이 사진, AI 수정 UI TODO |
| 노트북 API | `app/app/api/notebook/route.ts`, `synthesize/route.ts`, `photos/route.ts` | 원고 조회/저장·답변 종합·사진 슬롯 |
| 숨김 AI 수정 | `app/app/api/notebook/rewrite/route.ts` | 수정안 반환 API는 존재, 클라이언트 버튼은 주석 처리 |
| 숨김 최종 검수 | `app/app/api/notebook/final-review/route.ts` | 전 장 reviewed 검수 API; UI 버튼은 주석 처리 |
| 기존 답변 리뷰 | `app/app/(dashboard)/mypage/review/ReviewClient.tsx`, `app/app/api/review/*` | 답변별 제안·직접 수정과 finale; 챕터 종합 원고와 다름 |
| TTS | `app/hooks/useTTS.ts`, `app/app/api/tts/route.ts` | OpenRouter TTS, 단일 요청 2,000자 제한 |
| Clova TTS | `app/lib/audiobook/clova-tts.ts` | 서버 전용 NCP 자격 증명, 한국어 요청 한도 2,000자, Admin 오디오북 전용 |
| 사진 API | `app/app/api/upload-image/route.ts`, `answer-images/[id]/route.ts`, `photo-inbox/route.ts` | 첨부 이미지/스트리밍/임시함 매칭 |
| 스키마 | `app/lib/db/schema.ts` | `chapter_notebook`, `answer_attachment`, `photo_inbox`, `answer`, `writing_progress`, `approval_request` |

## 8. 신규 개발 범위 요약

- Next.js: `/book/[bookId]/review` 다권 서버/클라이언트 경로, 챕터 범위 권한·세션·저장 완료 CTA, 기존 notebook 화면과의 이전/호환.
- 편집: 원고 block/anchor와 placement 모델, 유료 수동 사진 최대 5장 및 서버 검증, 웹 편집 버전 충돌·되돌리기.
- 음성: 기존 OpenRouter 문장 TTS에서 Naver Voice 서버 통합으로 전환하고, 긴 원고 청킹·순차 재생·중지 위치·하이라이트를 검증.
- TODO/검토: 중지 문장 3문장 컨텍스트와 보이스 지시를 쓰는 AI 수정은 아직 구현 확정이 아니다.
- TODO/must: AI 사진 1장 생성은 미완성 기능이지만 출시 전 개발·테스트가 필수다. 첫 이미지 슬롯 우선 배치, 실패/재시도, 플랜 정책과 안전성 검증을 포함한다.
- 공통 전환: 장기적으로 Route Handler를 공유 NestJS API의 BFF로 두거나 공통 API로 이관한다. 키·플랜·권한 검증은 서버 경계에 둔다.

## 9. 열린 이슈 / 가정

1. “챕터1 저장 완료”는 1장에만 정확히 적용하고 이후에는 “현재 챕터 저장 완료”로 일반화했다. 모든 장에서 동일한 정확 문구가 필요하면 확정이 필요하다.
2. 현재 Next.js `contentId`와 새 `bookId`/`chapterId`, Flutter/NestJS 식별자는 서로 매핑되지 않는다. 다권 전환의 ID, 데이터 이전, 가족 참여 권한과 웹 우선 충돌 정책을 정해야 한다.
3. Naver Voice의 허용 문자 수, 음성 합성 지연·비용·캐시·문장 타이밍 정보와 중지 후 재개 기준은 제공자 검증 및 브라우저 테스트가 필요하다.
4. TTS 하이라이트는 현 문장 배열 순차 재생을 재사용할 수 있으나, 실제 오디오 시간과 문장 경계의 정확도는 Naver 응답 계약에 좌우된다.
5. `AI와 함께 수정하기`는 TODO/검토다. 보이스 입력의 STT 제공자, 수정안 즉시 반영의 의미(자동 저장 여부), 사실 왜곡 방지, 원복 이력, 유료 권한을 결정해야 한다.
6. AI 사진 1장 만들기는 TODO이면서 must 개발·테스트 항목이다. 외부 이미지 제공자에 답변의 민감정보를 보낼 고지·동의, 제공자의 학습 이용·보관·삭제 정책 확인이 선행되어야 한다.
7. 유료 플랜의 세부 티어, AI 사진 생성 수/비용 한도, 이미 수동 사진 5장이 있을 때 AI 사진의 배치·교체 정책은 미정이다.
