# 3. 인트로(목차 만들기) — 웹

## 1. 개요

- **대상**: 웹에서 직접 자서전을 시작하는 사용자와, Flutter 앱에서 수집한 프로필·목차를 웹에서 이어 보는 사용자
- **목적**: 앱과 같은 인트로 원본 데이터·목차를 공유하되, 웹 전용 작성도 가능한 온보딩을 제공한다.
- **현재 상태**: `/intro`는 `자기소개하기`(자유 서술 챗봇) 또는 `질문 선택하기`(대질문 직접 선택)의 두 시작 방식을 제공한다. 새 다단계 인트로는 구현되어 있지 않다.
- **방향**: 장기적으로 NestJS 공유 API를 사용해 앱과 동기화한다. 현재 웹은 Next.js Route Handler와 Drizzle DB를 독립적으로 사용한다.

## 2. 유저 플로우

### 앱에서 시작한 사용자

1. 앱에서 성별·생년월일·가족·학업·작성 계획을 저장하고 목차를 생성·확정한다.
2. 웹은 동일 계정의 공유 프로필·목차·진행률을 조회한다.
3. 작성 중이면 해당 작성 화면으로, 목차만 있으면 `/outline`으로, 완료면 마이페이지로 안내한다.

### 웹에서 직접 시작한 사용자

1. `/intro`에서 새 다단계 인트로 또는 기존 자유 서술/대질문 직접 선택 중 제공할 시작 방식을 선택한다.
2. 새 다단계 인트로를 선택하면 앱과 동일하게 성별 → 생년월일 → 결혼/자녀(각각 건너뛰기 가능) → 조건부 학업 상세 → 작성 계획을 입력한다.
3. 하루 가능 시간과 평일/주말·오전/오후 복수 선택을 바탕으로 예상 기간을 추천받고, 알림 여부를 확인한다.
4. 목차 만들기 후 맞춤 목차를 확인하고 작성으로 이동한다.

새 구조로 전환하면 현재 챗봇은 자유 서술 보완 경로로 병행할지, 제거할지 결정해야 한다. 대질문 직접 선택은 프로필/케이스 없이 목차를 만들 수 있는 현재 별도 경로이므로, 공유 데이터 계약에서 유지 여부와 저장 형태를 명시해야 한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 새 다단계 인트로 | 성별, 생년월일, 가족, 학업 상세, 작성 계획을 앱과 같은 데이터 구조로 수집 | 신규 |
| 이전/다음 | 모든 단계에 공통 적용, 입력 복원 | 신규 |
| 가족 건너뛰기 | 결혼·자녀를 각각 예/아니오/건너뛰기로 기록 | 신규 |
| 조건부 학업 상세 | 초등학교는 초등학교/국민학교, 그 외 단계는 학사/석사/박사 표시 | 신규 |
| 계획·기간 추천 | 하루 시간·복수 가능 시간대·기간 보기·추천·알림 여부 | 신규 |
| 자유 서술 챗봇 | STT/텍스트 자기소개를 저장하고 AI 케이스·목차 생성 | 기존 |
| 대질문 직접 선택 | 글로벌 대질문을 고른 뒤 사용자별 목차·질문 생성 | 기존 |
| 스토리 아이디어 | “하고 싶은 이야기”를 AI 질문 초안으로 만들고 적용하는 API | 부분 — UI는 숨김 |
| 앱·웹 동기화 | 동일 프로필·케이스·목차·답변·진행률 사용 | 신규/설계 필요 |

기간 추천은 시간·가능 요일·오전/오후 복수 선택을 근거로 하며, 시간이 많으면 2주를 추천할 수 있다. 다만 실제 계산식, 추천 임계값, 기본 기간은 아직 확정된 정책이 아니다. 선택 보기에는 최소 `1주`, `2주`, `4주`, `6주` 등을 둔다.

## 4. 화면 구성

| 화면/상태 | 구성 | 기존 대응 |
|---|---|---|
| 시작 방식 | 다단계 인트로, 자유 서술 자기소개, 대질문 직접 선택의 진입 정책 | `app/(dashboard)/intro/IntroStartClient.tsx` 변경 |
| 다단계 기본 정보 | 성별 버튼, 생년월일 연·월·일 드롭다운, 이전/다음 | 신규 |
| 가족·학업 | 결혼/자녀의 건너뛰기, 조건부 학업 상세 선택 | 신규 |
| 작성 계획 | 시간·평일/주말·오전/오후 복수 선택, 기간 추천/선택, 알림 안내 | 신규 |
| 자유 서술 챗봇 | 안내 메시지, STT·텍스트 입력, AI 목차 안내 | `IntroClient.tsx` 기존 |
| 대질문 선택 | 글로벌 대질문 목록, 필수/선택 토글, 작성 시작 | `SelectContentsClient.tsx` 기존 |
| 목차 확인 | 맞춤 유형·목차 표시, 작성 진입 | `app/(dashboard)/outline/page.tsx` 기존, 앱과 동기화 시 변경 |

현재 웹의 챗봇은 한 번의 자유 텍스트에 이름·나이·성별·직업·결혼·자녀 등을 요청하고 `/api/profile`, `/api/outline`을 순차 호출한다. 따라서 새 다단계 구조로 바꾸면 챗봇의 텍스트 저장 모델과 구조화된 데이터 모델을 병행하거나 이관해야 한다.

## 5. API 엔드포인트 (Next.js Route Handler → 공유 API 전환 대상)

| 현재 Method | 현재 Path | 현재 역할 | 전환 방향 |
|---|---|---|---|
| GET / POST | `/api/profile` | 자유 서술 프로필 문자열/케이스명 저장·조회 | 구조화된 NestJS 인트로 프로필 조회·저장으로 통합 |
| GET / POST | `/api/outline` | AI 케이스 판정, 목차·사용자별 질문 생성 | NestJS `intro/answers`, `intro/toc/confirm`과 공통 계약화 |
| GET | `/api/catalog/contents` | 글로벌 대질문 목록 | 웹 직접 선택을 공통 카탈로그 API로 이전 검토 |
| POST | `/api/outline/select` | 선택 대질문으로 사용자별 목차·질문 생성 | 공유 API의 별도 “직접 선택” 계약 여부 결정 |
| POST | `/api/story-ideas/suggest` | 추가 이야기 기반 질문 그룹 초안 | 도입 검토 대상 |
| POST | `/api/story-ideas/apply` | 확정 질문 그룹을 사용자 목차/질문에 반영 | 도입 검토 대상 |
| GET / PATCH | `/api/account` | 웹 계정·작성 설정 | 현재 알림 계획 설정 없음 |
| GET / PATCH | `/v1/settings` | 앱의 `daily_question_alarm` | 웹도 공유 설정을 쓸 때 재사용 |

웹 다단계 인트로의 목표 계약은 NestJS `GET /v1/intro/questions`, `POST /v1/intro/answers`, `POST /v1/intro/toc/confirm`, `GET /v1/intro/profile` 및 계획/알림 확장 API다. 이 문서는 Route Handler를 신규로 확정하지 않으며, 공유 API 이전 전 임시 어댑터가 필요할 수 있음을 전제로 한다.

## 6. 데이터 모델

| 영역 | 현재 Next.js Drizzle | 공유 목표 / 변경 |
|---|---|---|
| 프로필 | `profile.data`에 자유 문자열 또는 JSON 문자열, `case_name` | 구조화된 인트로 원본과 파생 케이스를 NestJS `user_intro_answer`, `user_profile`로 통합 |
| 목차 | `outline.chapters` JSON 캐시 | NestJS `user_chapter` 사용자 스냅샷을 원본으로 하고 웹용 캐시 존속 여부 결정 |
| 사용자별 질문 | `user_content`, `user_question` | NestJS `user_chapter`, `user_question`과 필드·식별자 매핑 필요 |
| 답변·진행 | `answer`, `answer_draft`, `writing_progress` | 공유 답변·진행률 계약 및 충돌 정책 필요 |
| 새 인트로 원본 | 없음 | 성별, 생년월일, 결혼/자녀 값 또는 건너뜀, 학업 단계·상세값 |
| 새 작성 계획 | 없음 | 하루 가능 시간, 복수 요일·시간대, 선택/추천 기간, 알림 동의·시간대 |
| 알림 | 웹 사용자 스키마·`/api/account`에는 오늘의 질문 알림 필드 없음 | NestJS `user_setting.daily_question_alarm`, 푸시 토큰·인앱 알림과 통합 검토 |

현재 웹 케이스 판정은 자유 서술 텍스트에서 AI 또는 키워드 규칙으로 대학·결혼·자녀 신호를 추론하며, 인생 방향 케이스도 우선할 수 있다. 새 다단계 입력의 명시적 원본 데이터와 NestJS의 8케이스는 이 방식과 결과가 달라질 수 있다.

## 7. 기존 코드 참고

- 웹 인트로 라우팅·진입 분기: `app/app/(dashboard)/intro/page.tsx`
- 시작 방식 선택: `app/app/(dashboard)/intro/IntroStartClient.tsx`
- 자유 서술 챗봇: `app/app/(dashboard)/intro/IntroClient.tsx`
- 대질문 직접 선택: `app/app/(dashboard)/intro/SelectContentsClient.tsx`
- 목차 표시: `app/app/(dashboard)/outline/page.tsx`
- 프로필/목차 Route Handler: `app/app/api/profile/route.ts`, `app/app/api/outline/route.ts`
- 직접 선택 Route Handler: `app/app/api/catalog/contents/route.ts`, `app/app/api/outline/select/route.ts`
- 스토리 아이디어 Route Handler: `app/app/api/story-ideas/suggest/route.ts`, `app/app/api/story-ideas/apply/route.ts`
- 웹 케이스·스냅샷·진행률: `app/lib/cases.ts`
- 웹 스키마: `app/lib/db/schema.ts`
- 숨김 스토리 아이디어 UI: `app/components/mypage/StoryIdeasSection.tsx`, `app/app/(dashboard)/mypage/page.tsx`
- 웹 계정 설정: `app/app/(dashboard)/settings/**`, `app/app/api/account/route.ts`

## 8. 신규 개발 범위 요약

1. `/intro`에 앱과 동일한 다단계 구조화 인트로를 추가하고, 모든 단계에 이전/다음·입력 복원을 구현한다.
2. 기존 자유 서술 챗봇 및 대질문 직접 선택의 병행/전환 정책과 명확한 진입 화면을 정한다.
3. 구조화 인트로·목차·질문·진행률을 NestJS 공유 API로 조회·저장하도록 웹 데이터 접근을 이전하거나 어댑터를 둔다.
4. 앱과 동일한 작성 계획·기간 추천·알림 설정을 표시하되, 기간 정책과 실제 푸시 발송은 별도 구현으로 다룬다.
5. 목차 만들기 전 스토리 아이디어 기능은 제품 검토 후에만 노출한다.

## 9. 열린 이슈 / 가정

1. **현재 UX 전환 범위**: 현재 `/intro`의 챗봇과 직접 선택은 실제 동작한다. 새 다단계 인트로가 기본 경로인지, 자유 서술과 직접 선택을 유지하는 병행 경로인지 확정해야 한다.
2. **학업 원본과 케이스**: 앱과 동일하게 학업 단계·상세값을 원본으로 보존하되, 기존 NestJS 8케이스의 `hasCollege`와 웹의 텍스트 기반 `hasCollege` 추론을 어떤 하나의 규칙으로 통일할지 결정해야 한다. 결혼/자녀의 건너뛰기를 false로 환원하면 원본 의미가 손실된다.
3. **웹의 방향 케이스**: `app/lib/cases.ts`는 `direction_*` 케이스를 지원하지만 NestJS 인트로는 대학·결혼·자녀 8케이스만 구현한다. 공유 계약에서 방향 케이스를 유지·이전·제외할지 결정해야 한다.
4. **작성 계획 정책**: 추천 기간의 계산식, 복수 요일·시간대의 해석, 사용자 수정 권한과 계획 변경 후 알림 재계산 규칙은 미정이다.
5. **알림의 실제 상태**: 웹 `/api/account`에는 `daily_question_alarm` 또는 푸시 설정이 없다. NestJS에는 `daily_question_alarm` 저장 API와 `device_push_token` 테이블·인앱 알림 조회가 있지만, 토큰 등록·푸시 제공자·스케줄러·실제 발송은 확인되지 않았다.
6. **Story ideas는 TODO**: `StoryIdeasSection`은 `mypage/page.tsx`에서 주석 처리되어 UI가 숨겨져 있고, `/api/story-ideas/suggest`·`apply`만 남아 있다. 목차 전 단계에서 “추가로 하고 싶은 이야기”를 선택/직접 추가하는 기능은 이 근거를 바탕으로 별도 도입 검토해야 하며, 확정 기능으로 취급하지 않는다.
7. **데이터 소유권·마이그레이션**: 현재 Next.js는 NextAuth/Drizzle 테이블(`profile`, `outline`, `user_content`, `user_question`, `answer`, `writing_progress`)을, NestJS는 TypeORM 테이블을 별도로 소유한다. 동일 계정 식별, 기존 데이터 이관, 중복 목차 생성 방지, 웹 우선 편집 충돌 해결, 롤백 방안을 먼저 결정해야 한다.
8. **개인정보**: 생년월일과 가족·학업·작성 가능 시간은 민감한 프로필 데이터다. 공유 API 이전 시 접근 권한, 암호화/보존 기간, 가족 공유 계정의 열람 범위를 설계해야 한다.
