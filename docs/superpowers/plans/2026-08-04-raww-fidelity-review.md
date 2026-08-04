# raww.md × Flutter+Nest 충실도 리뷰

**작성일**: 2026-08-04  
**원본**: [`docs/raww.md`](../../raww.md)  
**기준 계약**: [`docs/screens/`](../../screens/) (앱·웹 MD 쌍) > api-spec = ERD > 코드  
**범위**: Flutter 앱 + NestJS 서버. Next.js 웹 마케팅/구현은 문서(`*-web.md`)만 있고 **코드 미착수**.

---

## 요약

| 항목 | 판정 |
|------|------|
| 전체 (Flutter+Nest, storybook 영상·웹 코드 제외) | **약 74%** |
| 변환 경로 raw → 화면 MD (앱/웹 쌍) | 완료 |
| 화면 MD → Nest/Flutter (Phase 3) | 코어 플로우 대부분 완료 |
| Next.js 웹 코드 | 미착수 (문서만) |

**잘 맞은 축:** 앱 index · OCTOMO 인증·가입 · 인트로/writing-plan · 다권 book · 3라운드 작성 · audiobook(CLOVA+BGM+챕터당 2회) · ebook PDF 게이트  

**큰 구멍:** 리뷰 사진/AI사진 · write TTS+타이핑 동기 · 보이스 사전점검 · TOC 삽입 위치 · QnA/FAQ · 마일스톤 UI

---

## 변환 경로

| 층 | 상태 | 비고 |
|----|------|------|
| raw → 화면 MD | OK | 앱 단순 index / 웹 마케팅 랜딩으로 분리 |
| 화면 MD → Nest/Flutter | PARTIAL | Phase 3 수직 구현·커밋 분할 완료, gap 잔존 |
| Next.js 웹 구현 | MISSING | `*-web.md`만 존재 |

가격·후기 CRUD·마케팅 랜딩은 앱이 아니라 **웹 MD 몫**으로 분리된 것이 원문 의과 맞다.

---

## 섹터별 충실도

| # | 원문 섹터 | 판정 | 잘 맞은 것 | 원문과 다르거나 비는 것 |
|---|-----------|------|-----------|------------------------|
| 1 | 앱 index 단순 | **DONE** | `lib/feature/index/` + 시작하기 | 보안 문구 축약은 MD엔 있으나 UI는 최소형 |
| 2 | OCTOMO·가입·약관 | **PARTIAL** | challenge/verify, 필수3+마케팅, 성공→intro | 연락처 자동입력 없음 · **번호 단독 unique**(원문: 이름+번호) · 앱 ID/PW는 추후(의도) |
| 3 | 인트로 설문·작성계획 | **DONE** | 남/여·생일·결혼/자녀 skip·학력 상세·writing-plan | 복수 선택 UX는 단순화됨 |
| 4 | 목차 편집·추가 | **PARTIAL** | 이름/삭제/DnD·카탈로그·커스텀·확정→bookId | **삽입 위치 선택** 없음(append만) |
| 5 | write 3라운드·튜토리얼 | **PARTIAL** | bookId·draft·3루프·튜토리얼1회·이탈경고·완료 CTA | **보이스/마이크 점검** · **TTS+타이핑 동기** · 녹음 일시정지 없음 |
| 6 | 리뷰/Notebook | **PARTIAL** | 챕터 synthesize·앱 수정불가 안내·TTS | **사진 5장 / AI사진 / 문단삽입** · 무료락 UI 미노출 · AI함께수정은 Todo |
| 7 | book 1:N | **DONE** | 가로 카드·상세 진입 | — |
| 8 | 6-1 에디션 | **PARTIAL** | next Q 배너·진행률·플랜 잠금·review_status | **이정표(마일스톤) 화면** · 푸시는 인앱카드 · 팩트체크 Todo |
| 9 | ebook | **PARTIAL** | 챕터1 리뷰 게이트·PDF 다운 | 80% 제목락은 **서버만** · 표지제작 Todo |
| 10 | audiobook | **DONE** | 플랜락·챕터당 2회·BGM·보이스 미리듣기·확인창 | 로컬 `AUDIOBOOK_AUTO_GRANT`는 개발용 |
| 11 | storybook | **의도적 제외** | 앱 `WEB_ONLY` | 영상 파이프라인 Todo |
| 12 | qna/faq/setting | **MISSING** | 기본 설정만 | QnA API·FAQ 묶음 화면 없음 |

---

## 의도적 정책 차이 (버그 아님)

| 원문 | 현재 계약/코드 | 비고 |
|------|----------------|------|
| 유저 키 `(이름, 전화)` | **전화 단독 unique** | api-spec·ERD·화면 MD와 정합 |
| 앱에 마케팅·가격·후기 | 웹 `01-landing-web.md`로 이전 | 앱 index는 CTA만 |
| Storybook 앱 제공 X | entitlement `WEB_ONLY` | 원문과 일치 |
| T1~T4 가격표 UI | entitlement 한도만, 결제 UI 없음 | 랜딩/웹 몫 |
| FAQ | 정적 번들 예정 (CMS 미정) | api-spec 정책대기 |

---

## 가중 추정 (%)

| 영역 | 가중치 | 대략 완성도 |
|------|--------|-------------|
| Index + Auth + Intro + TOC | 25% | ~88% |
| Write + Review | 30% | ~55% |
| Book hub + 6-1 + Ebook + Audiobook | 30% | ~82% |
| Settings / FAQ / QnA + polish | 15% | ~20% |
| **가중 합** | | **~74%** |

---

## 남은 must (원문 기준 우선순위)

1. **리뷰**: 사진 업로드(챕터당 5)·AI 사진·문단 사이 삽입·무료락 UI  
2. **Write**: 진입 보이스/마이크 점검 · TTS + 타이핑 동기 애니 · (선택) 녹음 일시정지  
3. **QnA / FAQ / settings** 묶음 (`07-09-qna-faq-settings.md`)  
4. **TOC**: 추가 후 삽입 위치 피커  
5. **6-1**: 이정표(마일스톤) 화면 · ebook 제목 80% UI 게이트  
6. **웹 Next.js**: `*-web.md` 대비 코드 갭 (별도 트랙)

정책대기(의도적 미완): OTP/Kakao 병행, AI함께수정, 팩트체크, 표지 제작, Storybook 영상, POST /books 신규권, 탈퇴.

---

## Phase 3 화면 MD 매핑 (참고)

| # | 화면 MD | Flutter+Nest (이 브랜치) |
|---|---------|--------------------------|
| 1 | 01-landing | DONE |
| 2 | 02-login-signup | DONE (OTP/Kakao POLICY_WAIT) |
| 3 | 03-intro | DONE |
| 4 | 03-1-intro-toc | PARTIAL (삽입 위치) |
| 5 | 04-book-id-write | PARTIAL |
| 6 | 05-book-id-review | PARTIAL |
| 7 | 06-book | PARTIAL (POST /books 대기) |
| 8 | 06-1-book-id | PARTIAL |
| 9 | 06-1-1 ebook | PARTIAL (제목 UI) |
| 10 | 06-1-2 audiobook | DONE |
| 11 | 06-1-3 storybook | 의도적 제외 |
| 12 | 07-09 support | NOT_STARTED |

관련 계획: [`2026-08-04-screen-md-alignment.md`](./2026-08-04-screen-md-alignment.md)
