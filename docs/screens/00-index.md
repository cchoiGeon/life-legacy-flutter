# LifeLegacy 앱 개발가이드 — 화면별 색인

- **작성 기준일**: 2026-08-02
- **목적**: 확정된 화면 구성(아래 목록)을 기준으로, 각 화면을 **Flutter 앱**과 **NestJS 서버**로 구현하기 위한 개발 가이드. 기획·기능 로직 정리가 우선이며, 실제 화면 디자인은 Flutter/NestJS 저장소에 이미 정의된 디자인 시스템·API 컨벤션을 따른다.
- **비범위**: 이 문서들은 상세 위젯 트리·DTO 필드 단위 설계까지는 다루지 않는다(중간 상세도). 유저 플로우·핵심 기능·API 엔드포인트 목록·데이터 모델·기존 코드 참고 위치를 정리해 실제 구현 착수의 출발점을 제공한다.
- **참고 저장소**:
  - `lifelegacy` (현재 워크스페이스, Next.js 웹) — 이미 검증된 기능 로직의 1차 참고 소스. [`01-현재-기능정의`](../01-현재-기능정의.md), [`02-웹앱-분리-로드맵`](../02-웹앱-분리-로드맵.md)
  - `life-legacy-flutter` (`/Users/ck1044/Projects/life-legacy-flutter`, 별도 저장소) — Flutter 앱 + NestJS 서버(`server/`) 코드가 함께 있다. 컨벤션 문서: `docs/project-conventions.md`(NestJS 표준), `docs/server-architecture.md`(서버 동작 구조), `docs/server-feature-definition.md`(서버 기능 정의), `docs/api-spec.md`(API 계약), `README.md`(Flutter 구조·Figma 대응)

## 화면 목록 및 문서

| # | 화면 | 문서 | 현재 상태 요약 |
|---|------|------|----------------|
| 1 | 메인(랜딩) — 앱 | [`01-landing.md`](./01-landing.md) | Flutter 스플래시(버튼 없음)는 구현됨. 소개+시작하기 1페이지 "index" 화면은 신규 |
| 1 | 메인(랜딩) — 웹 | [`01-landing-web.md`](./01-landing-web.md) | Next.js 랜딩은 구현됨(`app/page.tsx`). 후기 CRUD·가격 매트릭스·개인정보 후킹 섹션 등 재구성은 신규 |
| 2 | 로그인 및 회원가입 — 앱 | [`02-login-signup.md`](./02-login-signup.md) | Flutter+NestJS 전화번호 OTP는 스텁. OCTOMO 기반 SMS 확인·가입/약관은 신규 |
| 2 | 로그인 및 회원가입 — 웹 | [`02-login-signup-web.md`](./02-login-signup-web.md) | Next.js Credentials(아이디/비밀번호)는 구현됨. SNS OAuth(`AUTH-01b`)는 미구현 |
| 3 | intro (목차 만들기) — 앱 | [`03-intro.md`](./03-intro.md) | Flutter+NestJS 자기소개 5문항→케이스 판정→목차 생성은 구현됨. 생년월일·건너뛰기·학업 상세·작성 계획은 신규 |
| 3 | intro (목차 만들기) — 웹 | [`03-intro-web.md`](./03-intro-web.md) | Next.js는 자유 서술 챗봇 또는 대질문 직접 선택 구현됨. 앱과 동기화하는 다단계 인트로는 신규 |
| 3-1 | intro2 (만들어진 목차 확인) — 앱 | [`03-1-intro-toc.md`](./03-1-intro-toc.md) | Flutter+NestJS 목차 재배열·확정 구현됨; 편집·추가·삽입 위치·에디션 1 완료는 신규 |
| 3-1 | intro2 (만들어진 목차 확인) — 웹 | [`03-1-intro-toc-web.md`](./03-1-intro-toc-web.md) | Next.js 조회·사용자 목차 CRUD/reorder는 부분 구현됨; 인트로 편집·확정 흐름은 신규 |
| 4 | book/[id]/write — 앱 | [`04-book-id-write.md`](./04-book-id-write.md) | Flutter+NestJS 단일 `/write`의 1회 꼬리질문·윤문 흐름 구현됨. GetX `bookId` 전달·다권·튜토리얼·네이버 Voice 통합은 신규 |
| 4 | book/[id]/write — 웹 | [`04-book-id-write-web.md`](./04-book-id-write-web.md) | Next.js `/write/[contentId]` 채팅형 1회 후속·OpenRouter 음성 흐름 구현됨. 다권·비채팅 UI·네이버 Voice 통합은 신규 |
| 5 | book/[id]/review — 앱 | [`05-book-id-review.md`](./05-book-id-review.md) | Flutter+NestJS 챕터 종합·읽기·TTS·사진 결과 조회는 신규. 직접 수정은 웹 안내 |
| 5 | book/[id]/review — 웹 | [`05-book-id-review-web.md`](./05-book-id-review-web.md) | 기존 notebook 종합·직접 수정·문장 TTS·사진 배치를 재사용하되 다권·플랜·Naver Voice 전환은 신규 |
| 6 | book — 앱 | [`06-book.md`](./06-book.md) | Flutter는 단일 자서전 홈(`/book`) 구현됨. 다권 책 목록/허브로 확장은 신규 |
| 6 | book — 웹 | [`06-book-web.md`](./06-book-web.md) | `/book` 라우트 없음. 단일 자서전 허브(`/mypage`)·BookPreview 기반의 다권 책 목록/허브는 신규 |
| 6-1 | book/[id] — 앱 | [`06-1-book-id.md`](./06-1-book-id.md) | 단일 책 상세 개념은 있으나 GetX `bookId` 기반 에디션 허브·알림·플랜 잠금은 신규 |
| 6-1 | book/[id] — 웹 | [`06-1-book-id-web.md`](./06-1-book-id-web.md) | `/mypage` 단일 허브를 다권 에디션 허브·공유 NestJS 전환으로 확장하는 신규 화면 |
| 6-1-1 | book/[id]/ebook — 앱 | [`06-1-1-book-id-ebook.md`](./06-1-1-book-id-ebook.md) | Flutter 기존 쪽 미리보기는 구현됨. 챕터1 리뷰 자격·부분 PDF 다운로드·PDF viewer는 신규 |
| 6-1-1 | book/[id]/ebook — 웹 | [`06-1-1-book-id-ebook-web.md`](./06-1-1-book-id-ebook-web.md) | 기존 preview·PDF/DOCX 내보내기는 유지. 다권·entitlement·챕터1 부분 ebook 전환은 신규 |
| 6-1-2 | book/[id]/audiobook — 앱 | [`06-1-2-book-id-audiobook.md`](./06-1-2-book-id-audiobook.md) | Flutter/NestJS에는 오디오북 모듈 없음. 사용자용 생성·다운로드는 신규 |
| 6-1-2 | book/[id]/audiobook — 웹 | [`06-1-2-book-id-audiobook-web.md`](./06-1-2-book-id-audiobook-web.md) | Admin 전용 CLOVA 오디오북 생성 구현됨. 사용자용 생성·관리 흐름은 신규 |
| 6-1-3 | book/[id]/storybook — 앱 | [`06-1-3-book-id-storybook.md`](./06-1-3-book-id-storybook.md) | Flutter 화면·route·CTA·재생은 비범위. NestJS 공통 생성 API는 신규 |
| 6-1-3 | book/[id]/storybook — 웹 | [`06-1-3-book-id-storybook-web.md`](./06-1-3-book-id-storybook-web.md) | 하이브리드 Admin 설계만 존재(생성 파이프라인 미구현). 사용자 관리·생성·재생은 신규 |
| 6-1-4 | book/[id]/bookcard | TODO (세부 기획 후 별도 가이드 작성) | TODO (세부 기획 후 별도 가이드 작성) |
| 7 | qna | [`07-09-qna-faq-settings.md`](./07-09-qna-faq-settings.md) | 통합 앱 가이드: Flutter+NestJS 신규 |
| 8 | faq | [`07-09-qna-faq-settings.md`](./07-09-qna-faq-settings.md) | 통합 앱 가이드: Flutter+NestJS 신규 |
| 9 | setting | [`07-09-qna-faq-settings.md`](./07-09-qna-faq-settings.md) | 통합 앱 가이드: Flutter+NestJS 기본 설정 구현됨 |
| 10 | notification | [`10-notification.md`](./10-notification.md) | Flutter+NestJS 인앱 알림 조회 구현됨. 푸시 발송은 신규 |

## 문서 공통 구조

각 화면 문서는 다음 순서를 따른다.

1. **개요** — 목적, 대상 사용자, 관련 문서
2. **유저 플로우** — 진입 경로부터 완료까지 단계
3. **핵심 기능** — 표 (기능 / 설명 / 상태: 기존·부분·신규)
4. **화면 구성** — 주요 섹션, Flutter 기존 코드 대응 여부
5. **API 엔드포인트 (NestJS)** — 표 (Method / Path / 설명 / 상태)
6. **데이터 모델** — 관련 테이블 (기존/신규)
7. **기존 코드 참고** — Next.js·Flutter·NestJS 경로
8. **신규 개발 범위 요약**
9. **열린 이슈 / 가정** — 필요한 경우만

상태 표기: **기존**(이미 구현됨, 그대로 재사용) · **부분**(일부만 구현, 확장 필요) · **신규**(설계·구현 필요)
