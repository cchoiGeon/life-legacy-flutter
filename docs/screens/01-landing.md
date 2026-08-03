# 01. 메인(랜딩) — 앱 (Flutter) "index"

## 1. 개요

- **목적**: Flutter 앱 최초 진입 시 서비스를 한 줄로 소개하고 "시작하기" 버튼으로 로그인 흐름 진입을 유도하는, 광고성 콘텐츠가 전혀 없는 **극도로 단순한 1페이지** 화면.
- **비범위**: 마케팅 후킹멘트, 실제 후기, 가격표, FAQ 등은 이 화면에 넣지 않는다. 그 역할은 전부 웹의 몫이다 — [`01-landing-web.md`](./01-landing-web.md) 참고.
- **대상 사용자**: 세션이 없는(최초 설치 또는 로그아웃 상태) 사용자. 세션 복원에 성공한 재방문자는 이 화면을 보지 않고 곧바로 홈 또는 자기소개로 이동한다(§2).
- **관련 문서**: [00-index](./00-index.md), [01-landing-web.md](./01-landing-web.md)(웹 랜딩), 02-login-signup(작성 예정), life-legacy-flutter `README.md`(화면↔Figma 대응표).

## 2. 유저 플로우

```
앱 실행
  → 스플래시 (/, 세션 복원, 버튼 없음, 최소 1.2초 노출)
      ├─ 세션 있음 + 목차 확정 완료 → 홈(/home)
      ├─ 세션 있음 + 목차 미확정      → 자기소개(/intro)
      └─ 세션 없음(신규/로그아웃)     → ★ 신규 index 화면 ★
                                          └─ "시작하기" 탭 → 로그인(/login)
```

index 화면 자체에는 여러 단계가 없다 — 소개 문구를 보고 "시작하기"를 누르면 바로 로그인 화면으로 이동하는 것이 전부다. 별도의 "더 알아보기"나 스크롤 콘텐츠는 없다(§1 비범위).

## 3. 핵심 기능

| 기능 | 설명 | 상태 |
|---|---|---|
| 서비스 한 줄 소개 | 브랜드명 + 짧은 카피 한두 줄 (기존 스플래시 카피 "말로 이야기하면 자서전이 됩니다" 재사용 가능) | 신규(카피는 기존 것 재사용 가능) |
| 시작하기 버튼 | 탭 시 로그인(`/login`)으로 이동 | 신규 |
| 개인정보보호 후킹 문구(축약) | 데이터 보안 원칙을 한 줄~두 줄로 축약해 배치 (전문은 웹 참고, [`01-landing-web.md`](./01-landing-web.md) §4-③) | 신규 |
| 마케팅 콘텐츠 배제 | 후기·가격표·FAQ·SNS 링크 등은 넣지 않음 | 신규(정책 확인 사항) |

## 4. 화면 구성

- 배경/브랜드 영역: 기존 스플래시와 동일 톤(브랜드 마크 + 워드마크)을 재사용
- 소개 문구 1~2줄 (명조 서체 — README "서체가 화면을 가른다" 원칙상 화면 제목/카피는 명조)
- "시작하기" CTA 버튼 1개 (고딕 서체, 기존 디자인 시스템 버튼 컴포넌트 재사용)
- (제안) 데이터 보안 원칙 축약 배지 또는 "자세히 보기" 텍스트 링크 1줄

**Flutter 기존 코드 대응**: `lib/feature/splash/splash_view.dart`의 `AppBrandMark`, `AppWordmark`, `AppTypography.brandTagline` 위젯을 그대로 재사용할 수 있다. CTA 버튼은 `lib/common/widgets/ds/`(디자인 시스템, `ds.dart` 배럴)에 정의된 기존 버튼류를 사용하는 것을 권장하나, 구체적 위젯명은 확인하지 못했다(§9 열린 이슈 4).

## 5. API 엔드포인트 (NestJS)

**해당 없음.** 이 화면은 정적 소개 문구와 화면 전환만 수행하며 서버 호출이 필요 없다. 세션 유무 판단은 스플래시 단계에서 기존 `AuthService.restore()`가 이미 처리하고(`POST /v1/auth/refresh` 등 기존 계약 그대로 재사용), index 화면은 그 결과값만 소비한다.

## 6. 데이터 모델

**해당 없음.** 신규 테이블·필드가 필요 없다. 세션 여부는 기존 `Storage`(GetStorage 래퍼, `lib/data/storage.dart`)의 토큰과 `introDone` 플래그를 그대로 사용한다.

## 7. 기존 코드 참고

| 경로 | 내용 |
|---|---|
| `life-legacy-flutter/lib/feature/splash/splash_controller.dart` | 세션 복원 후 분기 로직(`_decide()`, 30~44행). index 화면 삽입 시 "세션 없음" 케이스만 수정 대상 |
| `life-legacy-flutter/lib/feature/splash/splash_view.dart` | 버튼 없는 브랜드 스플래시 UI. 주석(9~11행)에 "예전 시안은 시작하기가 있는 랜딩이었지만 새 시안이 없앴다"고 명시 — 신규 index 화면 설계 시 반드시 검토 필요(§9-1) |
| `life-legacy-flutter/lib/core/route/app_routes.dart` | 라우트 경로 상수(`AppRoutes`). 신규 라우트 추가 시 이 파일에 `static const` 한 줄 추가하는 기존 컨벤션을 따른다 |
| `life-legacy-flutter/lib/core/route/app_pages.dart` | `GetPage` 등록 테이블(`AppPages.pages`). 화면 하나 = `binding` + `page`로 등록하는 기존 패턴 |
| `life-legacy-flutter/lib/feature/login/binding.dart`, `login_view.dart` | index 다음 화면(로그인)의 기존 구현. "시작하기" 버튼의 이동 대상 |
| `life-legacy-flutter/README.md` (24~44행) | "화면 하나 = binding + controller + view" 컨벤션 |
| `life-legacy-flutter/README.md` (46~69행) | 화면 ↔ Figma 대응표. 현재 `/` = A1 스플래시("버튼 없는 스플래시. 세션을 보고 자동으로 넘어간다")로 정의되어 있어, 신규 index 화면에 대응하는 Figma 프레임은 아직 없다 |
| `life-legacy-flutter/README.md` (262~276행) | "서체가 화면을 가른다" — 화면 제목/카피는 명조, 버튼/라벨은 고딕 원칙 |

## 8. 신규 개발 범위 요약

- 신규 화면 1개: `feature/index/`(가칭) — `binding.dart` + `index_controller.dart` + `index_view.dart` (기존 컨벤션 그대로)
- `AppRoutes`에 신규 라우트 상수 추가, `AppPages.pages`에 `GetPage` 등록
- `SplashController._decide()`의 "세션 없음" 분기 대상을 로그인 직행에서 신규 index 화면으로 변경(1줄 수정)
- 개인정보보호 후킹 문구 축약판을 index 화면 또는 온보딩(자기소개 시작 전) 어딘가에 배치 — 웹 문서([`01-landing-web.md`](./01-landing-web.md) §4-③) 원문을 앱 톤(큰 글씨, 시니어 친화)에 맞게 축약
- 신규 API·DB 없음

## 9. 열린 이슈 / 가정

1. **[핵심] index 화면과 기존 스플래시 설계 의도의 충돌.** 현재 스플래시(`splash_view.dart` 9~11행)는 "예전 시안엔 시작하기 버튼이 있는 랜딩이었으나, 시니어 사용자에게 '뭘 눌러야 하나' 하는 첫 화면을 주지 않기 위해 의도적으로 없앴다"고 명시적으로 기록되어 있다. 본 문서는 이 원칙을 **세션이 있는 재방문자에게는 그대로 유지**하고, **세션이 없는 신규 사용자에게만** index 화면을 노출하는 절충안을 제안했다(§2). 이는 필자의 판단이며 확정이 아니다.
   - 대안 A(본 문서 채택): 스플래시 뒤, 로그인 앞에 삽입. 재방문자 마찰 없음, 신규 사용자만 소개+CTA를 봄.
   - 대안 B: 스플래시 자체를 index로 완전히 대체. 모든 사용자가 매번 보게 되어 기존 설계 의도(재방문자 마찰 최소화)와 정면으로 배치됨.
   - 대안 C: 별도 index 화면을 만들지 않고, 로그인 화면(A2)에 소개 문구와 개인정보 안내만 보강.
   - **오너·디자이너 확인 필요.**
2. Figma 시안(`PickDam`)에 신규 index 화면에 대응하는 프레임이 있는지 미확인. 있다면 그 시안을 따르고, 없다면 신규 프레임 제작이 선행되어야 한다.
3. 개인정보보호 후킹 문구를 index 화면 자체에 넣을지, 온보딩(자기소개 B1 이전)에 넣을지 미확정.
4. `lib/common/widgets/ds/` 안에 재사용 가능한 CTA 버튼 컴포넌트가 정확히 무엇인지 위젯 단위까지는 확인하지 못했다(중간 상세도 범위 밖) — 실제 구현 시 `ds.dart` 배럴을 확인해서 선택할 것.
5. 앱에는 SNS(카카오/구글) 로그인이 아직 실연동되지 않았다(life-legacy-flutter `README.md` 12행 "API는 아직 전부 목업", `api-spec.md` §1.3은 카카오만 정의하고 구글은 없음). 개인정보 후킹 문구 중 "구글/카카오 인증" 표현은 앱에서도 웹과 동일한 조정이 필요하다 — 자세한 내용은 [`01-landing-web.md`](./01-landing-web.md) §9-1 참고.
