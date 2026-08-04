# 3. 인트로(목차 만들기) — 앱

## 1. 개요

- **대상**: 시니어 작성자가 Flutter 앱에서 목차 생성 전에 자신의 기본 정보와 작성 계획을 단계적으로 입력하는 흐름
- **목적**: 성별·생년월일·가족·학업 정보를 원본으로 보존하고, 작성 가능 시간에 맞춘 기간/알림 계획을 받은 뒤 NestJS가 맞춤 목차를 생성하게 한다.
- **현재 상태**: Flutter/NestJS에는 성함을 포함한 고정 5문항 → 8개 케이스 → 목차 생성·확정 흐름이 구현되어 있다. 새 스펙의 생년월일, 건너뛰기, 조건부 학업 상세, 작성 계획은 **신규**다.
- **관련 문서**: [현재 기능 정의](../01-현재-기능정의.md), [웹·앱 분리 로드맵](../02-웹앱-분리-로드맵.md)

## 2. 유저 플로우

1. 로그인 후 아직 목차를 확정하지 않은 사용자가 `/intro`에 진입한다.
2. 성별을 `남` 또는 `여`에서 선택하고 다음으로 이동한다.
3. 생년월일의 연·월·일을 각각 드롭다운으로 선택한다.
4. 결혼 유무와 자녀 유무를 각각 `예`/`아니오`로 답하거나 **건너뛰기** 한다.
5. 학업 단계(초등학교·중학교·고등학교·대학교 이상)를 누르면 바로 아래에 상세 선택을 보인다.
   - 초등학교: `초등학교` / `국민학교`
   - 중학교·고등학교·대학교 이상: `학사` / `석사` / `박사`
6. 자서전 작성 계획에서 하루 가능 시간, 가능 요일과 오전/오후 시간대를 복수 선택하고, 추천 또는 직접 선택한 예상 기간을 확인한다.
   - 안내: “자서전 작성하는 데 예상 시간은? 알림 여부 맞춰서 드릴게요. 나중에 변경 가능해요.”
   - 안내: “평균 2~3주 정도 걸려요.”
7. 사용자가 알림 여부를 확인·선택한 뒤 목차 만들기를 실행한다.
8. 생성 중 화면을 거쳐 제안 목차를 확인·재정렬하고 확정한다. 확정 후 첫 장 작성으로 이동한다.

모든 인트로 단계는 이전/다음 버튼을 제공한다. 선택만으로 다음 단계로 자동 이동하지 않으며, 이전 단계로 돌아오면 입력값을 복원한다.

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 다단계 이동 | 모든 단계의 이전/다음, 입력값 복원, 다음 버튼 유효성 제어 | 부분 — 기존 `IntroController` 패턴 재사용·확장 |
| 성별 | `남` / `여` 단일 선택 | 변경 — 기존 선택값은 `남성` / `여성` |
| 생년월일 | 연·월·일을 별도 드롭다운으로 수집 | 신규 |
| 결혼·자녀 | 각각 `예` / `아니오` 및 건너뛰기 | 변경 — 기존에는 건너뛰기 없음 |
| 학업 상세 | 단계 선택 뒤 조건부 상세 선택을 즉시 표시 | 신규 |
| 케이스 판정 | 원본 학업·가족 값을 보존하고, 호환되는 파생 축으로 기존 8케이스를 판정 | 변경 |
| 작성 계획 | 하루 가능 시간, 평일/주말, 오전/오후 복수 선택, 기간 추천·직접 선택 | 신규 |
| 알림 설정 | 계획 단계에서 알림 여부를 설정하고 기존 오늘의 질문 알림 설정과 연결 | 부분 |
| 목차 생성·확정 | 사용자별 장·질문 스냅샷 생성, 재정렬 후 확정 | 기존 |

하루 가능 시간의 보기에는 최소 `10분`, `평균 30분`, `1시간`, `1시간 반`, `2시간 이상`을 포함한다. 기간 보기는 `1주`, `2주`, `4주`, `6주` 등을 제공한다. 추천은 가능 시간과 선택한 요일/시간대에 근거하되, 구체 계산식과 최소·최대 규칙은 신규 정책으로 확정한다. 예를 들어 시간이 많은 경우 2주를 추천할 수 있으나, 이를 고정 규칙으로 확정하지 않는다.

## 4. 화면 구성

| 화면/단계 | 구성 | 기존 대응 |
|---|---|---|
| 기본 정보 | 상단 진행률·이전, 성별 선택, 다음 | `lib/feature/intro/intro_view.dart`의 선택형 문항 레이아웃 |
| 생년월일 | 연/월/일 드롭다운, 이전/다음 | 신규 |
| 가족 정보 | 결혼·자녀 질문, 예/아니오/건너뛰기, 이전/다음 | 기존 선택형 문항을 확장 |
| 학업 정보 | 학업 단계 버튼과 선택 직후 같은 화면에 나타나는 상세 버튼 | 신규 |
| 작성 계획 | 하루 시간, 평일/주말·오전/오후 복수 선택, 기간 추천/선택, 알림 여부 | 신규 |
| 목차 생성 중 | 뒤로가기 차단, 생성 상태 안내 | `toc_loading_view.dart` 재사용·문구/장 수 가변화 |
| 목차 확인 | 장 목록, 재정렬, 확정 | `toc_view.dart`, `toc_controller.dart` 재사용 |

앱의 기존 선택형 문항은 버튼을 누른 뒤 하단 `다음`으로 이동한다. 이 상호작용을 새 모든 단일 선택 단계에 유지한다. 다중 선택 시간대는 선택된 상태를 명확히 표시하고 다음을 눌러 확정한다.

## 5. API 엔드포인트 (NestJS)

| Method | Path | 설명 | 상태 |
|---|---|---|---|
| GET | `/v1/intro/questions` | 현재 고정 5문항 조회 | 변경 필요 |
| POST | `/v1/intro/answers` | 인트로 원본 답변 저장, 케이스 판정, 목차·질문 스냅샷 생성 | 변경 필요 |
| POST | `/v1/intro/toc/confirm` | 재정렬한 목차 확정 | 기존 |
| POST | `/v1/intro/writing-plan` | 작성 계획 저장·조회 | 신규 |
| GET | `/v1/intro/profile` | 저장한 자기소개 표시용 조회 | 변경 필요 |
| GET / PATCH | `/v1/settings` | `daily_question_alarm` 조회·변경 | 기존, 계획/스케줄 필드 확장 필요 |
| GET | `/v1/notifications` | 인앱 알림 목록 조회 | 기존 |
| POST | `/v1/notifications/read-all` | 인앱 알림 전체 읽음 | 기존 |

작성 계획 저장·조회는 `POST /v1/intro/writing-plan`(신규)으로 한다. 기간 추천은 서버 공식에 맡기고, 알림 동의는 별도 필드로 저장한다. 기존 `ApiClient.generateToc(Map<String, String>)`은 단일 문자열 답변만 전달하므로 구조화된 값·건너뛰기·다중 선택을 전달하도록 모델과 구현체를 함께 변경해야 한다.

## 6. 데이터 모델

| 영역 | 기존 모델 | 새로 보존/파생할 값 |
|---|---|---|
| 인트로 원본 | `intro_question`, `intro_choice`, `user_intro_answer` | 성별, 생년월일, 결혼·자녀의 선택 또는 건너뜀, 학업 단계와 상세값 |
| 프로필·케이스 | `user_profile`, `case_definition` | 기존 `hasCollege`, `hasMarriage`, `hasChildren`과 새 원본 프로필의 관계를 명시 |
| 목차·질문 스냅샷 | `user_chapter`, `user_question` | 목차 생성 시점의 사용자별 사본, 순차 진행 상태 |
| 작성 계획 | 없음 | 하루 가능 시간, 가능 요일, 가능 시간대, 선택/추천 기간, 알림 동의·시간대·변경 시각 |
| 알림 | `user_setting.daily_question_alarm`, `device_push_token`, `notification` | 설정 토글과 발송 대상·인앱 기록을 분리해 관리 |

`user_intro_answer.value_text`는 기존에도 선택 원문을 저장한다. 새 학업 단계와 상세 선택도 원본으로 각각 보존해야 하며, 단순히 `hasCollege`로 덮어쓰면 이후 학력별 질문·분석이 불가능하다. 결혼/자녀의 건너뛰기는 `아니오`로 변환하지 말고 미응답 상태로 구분해야 한다.

## 7. 기존 코드 참고

- Flutter 인트로 UI·단계 상태: `lib/feature/intro/intro_view.dart`, `intro_controller.dart`, `binding.dart`
- Flutter 목차 생성·확정: `lib/feature/intro/toc_loading_view.dart`, `toc_view.dart`, `toc_controller.dart`, `toc_binding.dart`
- Flutter 네트워크 교체 지점: `lib/core/network/api_client.dart`, `real_api_client.dart`, `mock_api_client.dart`
- Flutter 모델: `lib/data/models/user.dart`, `chapter.dart`, `notification.dart`
- Flutter 알림 토글·조회 UI: `lib/feature/settings/settings_view.dart`, `settings_controller.dart`, `lib/feature/notifications/notifications_controller.dart`
- NestJS 인트로 API·트랜잭션: `server/src/intro/intro.controller.ts`, `services/intro.service.ts`, `services/intro-transaction.service.ts`
- NestJS 8케이스 축: `server/src/intro/const/case-axes.ts`, `seed/intro-question.seed.ts`
- NestJS 인트로 엔티티: `server/src/intro/entities/{intro-question,intro-choice,user-intro-answer,user-profile,case-definition}.entity.ts`
- NestJS 목차 스냅샷: `server/src/chapters/entities/user-chapter.entity.ts`, `user-question.entity.ts`
- NestJS 설정·알림: `server/src/settings/{settings.controller.ts,services/settings.service.ts,dto/settings.dto.ts}`, `server/src/notifications/{notifications.controller.ts,services/notifications.service.ts,entities/notification.entity.ts}`, `server/src/users/entities/{user-setting,device-push-token}.entity.ts`

## 8. 신규 개발 범위 요약

1. Flutter 인트로를 기본 정보·생년월일·가족·학업 상세·작성 계획의 다단계 입력으로 개편한다.
2. 기존 단일 선택 컨트롤러를 조건부 상세 선택, 건너뛰기, 다중 선택, 구조화된 입력 복원에 맞게 확장한다.
3. NestJS 인트로 질문/선택지·DTO·엔티티·트랜잭션을 새 원본 데이터와 작성 계획을 보존하도록 확장한다.
4. 기존 8케이스와 사용자별 목차/질문 스냅샷 생성은 유지하되, 새 입력에서 파생한 호환 축을 사용한다.
5. 기간 추천 정책과 알림 스케줄·푸시 토큰 등록·발송 작업을 별도 도메인으로 설계한다.

## 9. 열린 이슈 / 가정

1. **학업 UX와 8케이스 축**: 새 UI의 `중학교·고등학교·대학교 이상 → 학사/석사/박사`는 학제상 자연스럽지 않은 조합을 허용한다. 단계와 학위의 관계, `대학교 이상` 선택 시에만 학사·석사·박사를 보일지, 현 스펙 그대로 모든 세 단계에 보일지 제품 결정을 확인해야 한다.
2. **케이스 판정값**: 기존 서버는 `대학교 이상`만 `hasCollege=true`로 삼아 결혼·자녀와 2×2×2=8개 케이스를 만든다. 새 원본 학업 단계/상세값을 보존하면서, `hasCollege`를 어느 조합에서 true로 파생할지와 건너뛴 가족 응답의 축 값을 확정해야 한다. 미응답을 false로 처리하면 “아니오”와 데이터가 섞인다.
3. **기존 5문항 마이그레이션**: 기존 `i1` 성함은 새 필수 스펙에 없지만 현재 책 표지·사용자 이름에 쓰인다. 성함을 인트로에 유지할지 가입 정보로 이관할지, 기존 `i2`~`i5` 선택값을 새 코드/라벨로 어떻게 매핑할지 결정해야 한다.
4. **작성 계획 추천 정책**: 시간·요일·오전/오후 선택만으로 기간을 어떤 공식으로 추천할지, 복수 시간대가 실제 작성 가능 횟수를 뜻하는지, 사용자가 추천을 거부할 수 있는지를 정해야 한다.
5. **알림의 실제 상태**: `daily_question_alarm`은 GET/PATCH와 앱 토글이 구현되어 있고 `notification`은 인앱 목록용이다. `device_push_token` 테이블은 있으나 토큰 등록 API, 푸시 제공자 연동, 스케줄러·실제 발송 코드는 확인되지 않았다. 계획 단계의 “알림 여부”는 설정 저장과 실제 발송을 동일시하면 안 된다.
6. **알림 시간**: 오전/오후 선택은 작성 가능 시간대일 뿐 발송 시각이 아니다. 실제 알림 시각, 시간대, 휴일·복수 슬롯 우선순위, 미응답 재알림 정책을 정해야 한다.
7. **추가 이야기 기능**: 목차 생성 전 “추가로 하고 싶은 이야기”를 선택/직접 입력하는 기능은 이번 확정 범위가 아니다. 웹의 숨김 `StoryIdeasSection` 및 `/api/story-ideas/*`를 공유 인트로에 도입할지 별도 검토가 필요하다.
8. **공유 데이터 소유권**: 최종 방향은 앱·웹이 NestJS 공유 API의 프로필·케이스·목차·답변·진행률을 함께 쓰는 것이다. 현재 웹은 Next.js Route Handler + Drizzle, 앱은 NestJS + TypeORM으로 분리되어 있어, 기존 웹 데이터의 소유권·ID 매핑·마이그레이션·동기화 충돌 규칙을 정해야 한다.
